//
//  TKSynchronizationManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 31/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKAPI+Private.h"
#import "TKSynchronizationManager.h"
#import "TKEventsManager.h"
#import "TKTripsManager+Private.h"
#import "TKSessionManager+Private.h"
#import "TKUserSettings+Private.h"
#import "Foundation+TravelKit.h"
#import "NSDate+Tripomatic.h"
#import "NSObject+Parsing.h"

#ifdef LOG_SYNC
#define SyncLog(__FORMAT__, ...) NSLog(@"[SYNC] " __FORMAT__, ##__VA_ARGS__)
#else
#define SyncLog(...) do { } while (false)
#endif


#define kTKSynchronizationTimerPeriod  15
#define kTKSynchronizationMinPeriod    60

typedef NS_ENUM(NSUInteger, TKSynchronizationState) {
	TKSynchronizationStateStandby = 0,
	TKSynchronizationStateInitializing,
	TKSynchronizationStateFavourites,
	TKSynchronizationStateChanges,
	TKSynchronizationStateTripConflicts,
	TKSynchronizationStateUpdatedTrips,
	TKSynchronizationStateClearing,
};

typedef NS_ENUM(NSUInteger, TKSynchronizationNotificationType) {
	TKSynchronizationNotificationTypeBegin = 0,
	TKSynchronizationNotificationTypeSignificantUpdate,
	TKSynchronizationNotificationTypeCancel,
	TKSynchronizationNotificationTypeDone,
};


@interface TKSynchronizationResult ()

@property (atomic) NSTimeInterval changesTimestamp;

@end

@implementation TKSynchronizationResult @end


@interface TKSynchronizationManager ()

@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, copy) NSString *currentAccessToken;

@property (nonatomic, strong) NSTimer *repeatTimer;
@property (nonatomic, assign) NSTimeInterval lastSynchronization;

@property (nonatomic, strong) NSMutableArray<TKAPIRequest *> *requests;
@property (nonatomic, strong) NSMutableArray<TKTripConflict *> *tripConflicts;
@property (nonatomic, strong) NSArray<NSString *> *tripIDsToFetch;

@end


@interface TKSynchronizationManager ()

@property (nonatomic, strong) TKSessionManager *session;
@property (nonatomic, strong) TKEventsManager *events;
@property (nonatomic, strong) TKTripsManager *tripsManager;

@property (atomic) TKSynchronizationState state;
@property (nonatomic, strong) TKSynchronizationResult *result;

@end


@implementation TKSynchronizationManager


#pragma mark - Instance stuff


+ (TKSynchronizationManager *)sharedManager
{
	static TKSynchronizationManager *shared = nil;
	static dispatch_once_t pred = 0;
	dispatch_once(&pred, ^{ shared = [[self alloc] init]; });
	return shared;
}

- (instancetype)init
{
	if (self = [super init])
	{
		_session = [TKSessionManager sharedManager];
		_events = [TKEventsManager sharedManager];
		_tripsManager = [TKTripsManager sharedManager];
		_state = TKSynchronizationStateStandby;
		_queue = [NSOperationQueue new];
		_queue.name = @"Synchronization";
		_queue.maxConcurrentOperationCount = 1;
		if ([_queue respondsToSelector:@selector(setQualityOfService:)])
			_queue.qualityOfService = NSQualityOfServiceBackground;
		_requests = [NSMutableArray array];
		_tripConflicts = [NSMutableArray array];
		_lastSynchronization = 0;
	}

	return self;
}


#pragma mark - Setters


- (void)setPeriodicSyncEnabled:(BOOL)periodicSyncEnabled
{
	// Store
	_periodicSyncEnabled = periodicSyncEnabled;

	// Invalidate in any case
	[_repeatTimer invalidate];
	_repeatTimer = nil;

	if (periodicSyncEnabled)
	{
		_repeatTimer = [NSTimer timerWithTimeInterval:kTKSynchronizationTimerPeriod target:self
			selector:@selector(synchronizePeriodic) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:_repeatTimer forMode:NSRunLoopCommonModes];
	}
}


#pragma mark - Plain calls


- (void)synchronize
{
	@synchronized(self) {

		// If we're connected and session allows synchronization
		if (!_blockSynchronization)
		{
			if (_state == TKSynchronizationStateStandby)
			{
				_lastSynchronization = [NSDate timeIntervalSinceReferenceDate];

				// Create targetted operation
				NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
					[self synchronizeAtomicWithCredentials:_session.credentials];
				}];

				// Add the operation to a self-handling queue
				[_queue addOperation:operation];
			}
			else
				SyncLog(@"Skipping, still %tu items in queue", _requests.count + _tripConflicts.count);
		}
	}
}

- (void)synchronizePeriodic
{
	@synchronized(self) {

		if (!_session.credentials)
			return;

		SyncLog(@"Tick Tock");

		if (_blockSynchronization)
			return;

		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

		if ((now - _lastSynchronization) > kTKSynchronizationMinPeriod)
		{
			SyncLog(@"Scheduled synchronization");
			[self synchronizeAtomicWithCredentials:_session.credentials];
		}
	}
}


#pragma mark - Atomic operation


- (void)synchronizeAtomicWithCredentials:(TKUserCredentials *)userCredentials
{
	[NSThread currentThread].name = @"Synchronization";

	_state = TKSynchronizationStateInitializing;
	_result = [TKSynchronizationResult new];
	_result.success = YES;

	// Set up fields for current synchronization loop
	_currentAccessToken = [userCredentials.accessToken copy];

	// Fire up
	SyncLog(@"Synchronization started");

	[self checkState];

	[NSThread currentThread].name = nil;
}


#pragma mark - API requests worker


- (void)enqueueRequest:(TKAPIRequest *)request
{
	request.accessToken = _currentAccessToken;
	[_requests addObject:request];
	[request start];
}


#pragma mark - Phase initializers


- (void)synchronizeFavourites
{
	NSDictionary<NSString *, NSNumber *> *toSync = [_session favoritePlaceIDsToSynchronize];

	NSArray<NSString *> *favouritesToAdd =
	  [toSync.allKeys filteredArrayUsingBlock:^BOOL(NSString *key) {
		return toSync[key].integerValue > 0;
	}];

	NSArray<NSString *> *favouritesToRemove =
	  [toSync.allKeys filteredArrayUsingBlock:^BOOL(NSString *key) {
		return toSync[key].integerValue < 0;
	}];

	void (^failure)(TKAPIError *) = ^(TKAPIError *__unused e){
		[self checkState];
	};

	// Locally added Favourites
	for (NSString *itemID in favouritesToAdd)
	{
		[self enqueueRequest:[[TKAPIRequest alloc] initAsFavoriteItemAddRequestWithID:itemID success:^{

			[_session storeServerFavoriteIDsAdded:@[ itemID ] removed:@[ ]];
			[self checkState];

		} failure:failure]];
	}

	// Locally removed Favourites
	for (NSString *itemID in favouritesToRemove)
	{
		[self enqueueRequest:[[TKAPIRequest alloc] initAsFavoriteItemDeleteRequestWithID:itemID success:^{

			[_session storeServerFavoriteIDsAdded:@[ ] removed:@[ itemID ]];
			[self checkState];

		} failure:failure]];
	}

	[self checkState];
}

- (void)synchronizeChanges
{
	// Get lastest updates from Changes API and do all the magic

	// Check for user's trip changes
	if (_session.credentials != nil)
	{
		NSDate *since = nil;

		NSTimeInterval changesTimestamp = [TKUserSettings sharedSettings].changesTimestamp;
		if (changesTimestamp > 0) since = [NSDate dateWithTimeIntervalSince1970:changesTimestamp];

		TKAPIRequest *listRequest = [[TKAPIRequest alloc] initAsChangesRequestSince:since
		success:^(NSDictionary<NSString *,NSNumber *> *updatedTripsDict, NSArray<NSString *> *deletedTripIDs,
		NSArray<NSString *> *updatedFavouriteIDs, NSArray<NSString *> *deletedFavouriteIDs,
		BOOL __unused updatedSettings, NSDate *timestamp) {

			// Report online statistics
			SyncLog(@"Got list with %tu Trip updates and %tu Favourite updates",
			        updatedTripsDict.allKeys.count + deletedTripIDs.count,
			        updatedFavouriteIDs.count + deletedFavouriteIDs.count);

			// Mark down a Changes timestamp
			_result.changesTimestamp = [timestamp timeIntervalSince1970];

			// Set up comparable arrays
			NSMutableArray<NSString *> *currentOnlineTripIDs = [updatedTripsDict.allKeys mutableCopy];
			NSArray<TKTrip *> *currentDBTrips = [[_tripsManager allTrips]
				.reverseObjectEnumerator allObjects];

			// Walk through the local trips to send to server (when signed in)
			for (TKTrip *localTrip in currentDBTrips) {

				// Find out whether trip has been updated
				BOOL updated = updatedTripsDict[localTrip.ID] != nil;

				// If not marked as updated on server...
				if (!updated) {

					BOOL deletedOnRemote = [deletedTripIDs containsObject:localTrip.ID];

					// ...and is user-created (with no server-generated ID)
					if ([localTrip.ID hasPrefix:@LOCAL_TRIP_PREFIX]) {

						SyncLog(@"Trip NOT on server yet – sending: %@", localTrip);

						[self enqueueRequest:[[TKAPIRequest alloc] initAsNewTripRequestForTrip:localTrip success:^(TKTrip *trip) {

							[self processResponseWithTrip:trip sentTripID:localTrip.ID];
							[self checkState];

						} failure:^(TKAPIError *__unused error) {
							[self checkState];
						}]];
					}

					// ...if locally modified, send updates to the server

					else if (!deletedOnRemote && localTrip.changed) {

						SyncLog(@"Trip NOT up-to-date on server – sending: %@", localTrip);
						TKAPIRequest *updateTripRequest = [[TKAPIRequest alloc] initAsUpdateTripRequestForTrip:localTrip
						success:^(TKTrip *remoteTrip, TKTripConflict *conflict) {

							// Enqueue the conflict if it's valid
							if (conflict)
								[_tripConflicts addObject:conflict];

							// Otherwise process received Trip
							else if (remoteTrip)
								[self processResponseWithTrip:remoteTrip sentTripID:localTrip.ID];

							[self checkState];

						} failure:^(TKAPIError *__unused e){
							[self checkState];
						}];

						[self enqueueRequest:updateTripRequest];
					}

					// ...otherwise:
					// - Trips returned as deleted from server can be dropped directly
					// - In case we request Changes API with 'since' timestamp 0, Trips not found in response
					//   can be deleted as these are not present on the server

					else if (deletedOnRemote || changesTimestamp < 1)
					{
						SyncLog(@"Trip NOT on server – deleting: %@", localTrip);

						[_tripsManager deleteTripWithID:localTrip.ID];
					}
				}

				else {

					// Success: Changes accepted
					// Error: Begin conflict resolution of Trip if verbosely ignored, ignore otherwise
					//

					// Server sent updated Trip which is also locally modified.
					// Try pushing it so we get one of [success, failure, conflict].

					if (localTrip.changed) {

						// Do not further process matching remote Trip, we decide what to do here
						[currentOnlineTripIDs removeObject:localTrip.ID];

						SyncLog(@"Trip conflicting with server - sending: %@", localTrip);
						TKAPIRequest *request = [[TKAPIRequest alloc] initAsUpdateTripRequestForTrip:localTrip
						success:^(TKTrip *remoteTrip, TKTripConflict *conflict) {

							// Enqueue the conflict if it's valid
							if (conflict)
								[_tripConflicts addObject:conflict];

							// Otherwise process received Trip
							else if (remoteTrip)
								[self processResponseWithTrip:remoteTrip sentTripID:localTrip.ID];

							[self checkState];

						} failure:^(TKAPIError *__unused e){
							[self checkState];
						}];

						[self enqueueRequest:request];
					}
				}
			}

			NSMutableArray *tripsToFetch = [NSMutableArray arrayWithCapacity:5];

			// Walk through the server trips
			for (NSString *onlineTripID in currentOnlineTripIDs) {

				// Initial rule for app type
				BOOL shouldProcess = YES;
				NSUInteger onlineTripVersion = [updatedTripsDict[onlineTripID] unsignedIntegerValue];

				// If found in the DB and up-to-date, do not request it except for
				// the case the Trip is foreign -- changes in collaborators and its rights
				// do not change Trip version
				for (TKTrip *dbTrip in currentDBTrips)
					if ([dbTrip.ID isEqualToString:onlineTripID])
					{
						if (dbTrip.version == onlineTripVersion)
							shouldProcess = NO;
						break;
					}

				if (!shouldProcess) continue;

				SyncLog(@"Trip updated on server - queueing: %@", onlineTripID);
				[tripsToFetch addObject:onlineTripID];
			}

			_tripIDsToFetch = [tripsToFetch copy];

			// Process Favourite fields

			[_session storeServerFavoriteIDsAdded:updatedFavouriteIDs removed:deletedFavouriteIDs];

			// Fill the result object

			if (updatedTripsDict.count || deletedTripIDs.count) {
				NSMutableArray<NSString *> *updatedTripIDs = [NSMutableArray arrayWithCapacity:10];
				[updatedTripIDs addObjectsFromArray:updatedTripsDict.allKeys ?: @[ ]];
				[updatedTripIDs addObjectsFromArray:deletedTripIDs ?: @[ ]];
				_result.updatedTripIDs = updatedTripIDs;
			}

			if (updatedFavouriteIDs.count || deletedFavouriteIDs.count)
				_result.favoritesUpdated = YES;

			// Continue processing

			[self checkState];

		} failure:^(TKAPIError *__unused error) {

			// Mark Sync as unsuccessful due to Changes failure
			_result.success = NO;

			// Continue processing
			[self checkState];
		}];

		[self enqueueRequest:listRequest];

		[self checkState];
}

	// Otherwise skip Trips processing
	else [self checkState];
}

- (void)resolveTripConflicts
{
	if (!_tripConflicts.count) {
		[self checkState];
		return;
	}

	if (_events.tripConflictsHandler)
	{
		dispatch_semaphore_t sema = dispatch_semaphore_create(0);

		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			_events.tripConflictsHandler(_tripConflicts, ^{

				for (TKTripConflict *conf in _tripConflicts)
				{
					TKTrip *localTrip = conf.localTrip;

					if (conf.forceLocalTrip)
					{
						localTrip.lastUpdate = [NSDate now];

						SyncLog(@"Trip on server will be overwritten: %@", localTrip);

						TKAPIRequest *request = [[TKAPIRequest alloc] initAsUpdateTripRequestForTrip:localTrip
						success:^(TKTrip *remoteTrip, TKTripConflict *__unused conflict) {

							// Process received Trip
							[self processResponseWithTrip:remoteTrip sentTripID:localTrip.ID];
							[self checkState];

						} failure:^(TKAPIError *__unused e){
							[self checkState];
						}];

						[self enqueueRequest:request];
					}
					else {
						SyncLog(@"Trip will be overwritten from server: %@", conf.remoteTrip);
						[self processResponseWithTrip:conf.remoteTrip sentTripID:conf.remoteTrip.ID];
					}
				}

				dispatch_semaphore_signal(sema);
			});
		}];

		dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
	}

	else
		for (TKTripConflict *conf in _tripConflicts.copy)
			[self processResponseWithTrip:conf.remoteTrip sentTripID:conf.localTrip.ID];

	[self checkState];
}

- (void)synchronizeUpdatedTrips
{
	NSMutableSet *storedIDs = [NSMutableSet setWithCapacity:_tripIDsToFetch.count];

	// Iterate the Trip IDs from API
	for (NSString *tripID in _tripIDsToFetch)
	{
		[storedIDs addObject:tripID];

		if (storedIDs.count >= 25 || (storedIDs.count && tripID == _tripIDsToFetch.lastObject))
		{
			[self enqueueRequest:[[TKAPIRequest alloc] initAsBatchTripRequestForIDs:
			  storedIDs.allObjects success:^(NSArray<TKTrip *> *trips) {

				for (TKTrip *t in trips)
					[self processResponseWithTrip:t sentTripID:t.ID];

				[self checkState];

			  } failure:^(TKAPIError *__unused e) {
				[self checkState];
			}]];

			[storedIDs removeAllObjects];
		}
	}

	// Check state
	[self checkState];
}


#pragma mark - API responses workers


- (void)processResponseWithTrip:(TKTrip *)trip sentTripID:(NSString *)originalTripID
{
	SyncLog(@"Processing Trip: %@", trip);

	// Update Trip ID if needed
	if (originalTripID && ![originalTripID isEqualToString:trip.ID])
	{
		[_tripsManager changeTripWithID:originalTripID toID:trip.ID];

		if (_events.tripIDChangeHandler)
			_events.tripIDChangeHandler(originalTripID, trip.ID);
	}

	// If there's already a Trip in the DB, update, otherwise add new Trip
	[_tripsManager storeTrip:trip];
}


#pragma mark - Actions


- (void)checkState
{
	// Find finished requests
	NSMutableArray *requestsToClean = [NSMutableArray array];

	for (TKAPIRequest *r in _requests)
		if (r.state == TKAPIRequestStateFinished)
			[requestsToClean addObject:r];

	// ..and remove them from the queue
	[_requests removeObjectsInArray:requestsToClean];

	// Leave when there's a pending operation in current phase
	if (_requests.count != 0)
		return;

	// Move to a next phase
	_state++;

	// Push locally marked Favourites phase if required
	if (_state == TKSynchronizationStateFavourites)
		[self synchronizeFavourites];

	// Perform Changes phase if required
	else if (_state == TKSynchronizationStateChanges)
		[self synchronizeChanges];

	else if (_state == TKSynchronizationStateTripConflicts)
		[self resolveTripConflicts];

	// Fetch Trips updated on API
	else if (_state == TKSynchronizationStateUpdatedTrips)
		[self synchronizeUpdatedTrips];

	// Otherwise finish synchronization loop
	else [self finishSynchronization];
}

- (void)finishSynchronization
{
	// Set last sync date now to delay next sync appearance
	_lastSynchronization = [NSDate timeIntervalSinceReferenceDate];

	// Update Changes timestamp in User settings
	if (_result.success) {
		[TKUserSettings sharedSettings].changesTimestamp = _result.changesTimestamp;
		[[TKUserSettings sharedSettings] commit];
	}

	SyncLog(@"Synchronization finished");

	_state = TKSynchronizationStateStandby;

	if (_events.syncCompletionHandler)
		_events.syncCompletionHandler(_result);
}

- (void)cancelSynchronization
{
	for (TKAPIRequest *request in _requests)
		[request cancel];

	[_requests removeAllObjects];

	SyncLog(@"Synchronization cancelled");

	_state = TKSynchronizationStateStandby;
	_result.success = NO;

	if (_events.syncCompletionHandler)
		_events.syncCompletionHandler(_result);
}

- (BOOL)syncInProgress
{
    return (_state != TKSynchronizationStateStandby);
}

@end
