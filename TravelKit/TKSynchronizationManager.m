//
//  TKSynchronizationManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 31/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKAPI+Private.h"
#import "TKSynchronizationManager.h"
#import "TKTripsManager+Private.h"
#import "TKSessionManager+Private.h"
#import "TKUserSettings+Private.h"
#import "Foundation+TravelKit.h"

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
	TKSynchronizationStateUpdatedTrips,
	TKSynchronizationStateClearing,
};

typedef NS_ENUM(NSUInteger, TKSynchronizationNotificationType) {
	TKSynchronizationNotificationTypeBegin = 0,
	TKSynchronizationNotificationTypeSignificantUpdate,
	TKSynchronizationNotificationTypeCancel,
	TKSynchronizationNotificationTypeDone,
};


@interface TKTripConflict : NSObject

@property (nonatomic, strong) TKTrip *localTrip;
@property (nonatomic, strong) TKTrip *remoteTrip;
@property (nonatomic, copy) NSString *lastEditor;
@property (nonatomic, strong) NSDate *lastUpdate;

@end

@implementation TKTripConflict @end


@interface TKSynchronizationManager ()

@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, copy) NSString *currentAccessToken;

@property (atomic) BOOL verboseSynchronization;
@property (atomic) BOOL significantUpdatePerformed;
@property (nonatomic, strong) NSTimer *repeatTimer;
@property (nonatomic, assign) NSTimeInterval lastSynchronization;

@property (nonatomic, strong) NSMutableArray *requests;
@property (nonatomic, strong) NSMutableArray *tripConflicts;
@property (nonatomic, strong) NSArray *tripIDsToFetch;

@property (atomic) NSTimeInterval lastChangesTimestamp;

@end


@interface TKSynchronizationManager ()

@property (nonatomic, strong) TKSessionManager *session;
@property (nonatomic, strong) TKTripsManager *tripsManager;
@property (atomic) TKSynchronizationState state;

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
		_session = [TKSessionManager sharedSession];
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
				[self sendNotification:TKSynchronizationNotificationTypeBegin];

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
		else [self sendNotification:TKSynchronizationNotificationTypeCancel];
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

	// Set up fields for current synchronization loop
	_currentAccessToken = [userCredentials.accessToken copy];
	_significantUpdatePerformed = NO;

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

	TKUserSettings *settings = [TKUserSettings sharedSettings];

	// Check for user's trip changes
	if (_session.credentials != nil)
	{
		NSDate *since = nil;

		NSTimeInterval changesTimestamp = settings.changesTimestamp;
		if (changesTimestamp > 0) since = [NSDate dateWithTimeIntervalSince1970:changesTimestamp];

		TKAPIRequest *listRequest = [[TKAPIRequest alloc] initAsChangesRequestSince:since
		success:^(NSDictionary<NSString *,NSNumber *> *updatedTripsDict, NSArray<NSString *> *deletedTripIDs,
		NSArray<NSString *> *updatedFavouriteIDs, NSArray<NSString *> *deletedFavouriteIDs,
		BOOL __unused updatedSettings, NSDate *timestamp) {

			// Report online statistics
			SyncLog(@"Got list with %tu Trip updates and %tu Favourite updates",
			        updatedTripsDict.allKeys.count + deletedTripIDs.count,
			        updatedFavouriteIDs.count + deletedFavouriteIDs.count);

			// Update Changes API timestamp
			_lastChangesTimestamp = settings.changesTimestamp = [timestamp timeIntervalSince1970];

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
						TKAPIRequest *updateTripRequest = [[TKAPIRequest alloc] initAsUpdateTripRequestForTrip:localTrip success:^(TKTrip *trip) {

							[self processResponseWithTrip:trip sentTripID:localTrip.ID];
							[self checkState];

						} failure:^(TKAPIError *__unused e, TKTrip *trip){

// TODO: Conflicts
//							TKAPIResponse *response = e.response;
//							NSString *resolution = [response.data[@"conflict_resolution"] parsedString];
//
//							// If pushed Trip update has been ignored,
//							// add Trips pair to conflicts holding structure
//							if (trip && [resolution containsSubstring:@"ignored"])
//							{
//								NSDictionary *conflictDict = [response.data[@"conflict_info"] parsedDictionary];
//								TKTripConflict *conflict = [TKTripConflict new];
//								conflict.localTrip = localTrip;
//								conflict.remoteTrip = trip;
//								conflict.lastEditor = [conflictDict[@"last_user_name"] parsedString];
//								NSString *dateStr = [conflictDict[@"last_updated_at"] parsedString];
//								conflict.lastUpdate = (dateStr) ? [NSDate dateFrom8601DateTimeString:dateStr] : nil;
//								[_tripConflicts addObject:conflict];
//							}
//
//							// Otherwise process received Trip
//							else if (trip)
								[self processResponseWithTrip:trip sentTripID:localTrip.ID];

							[self checkTripConflicts];
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
						TKAPIRequest *request = [[TKAPIRequest alloc] initAsUpdateTripRequestForTrip:localTrip success:^(TKTrip *trip) {

							[self processResponseWithTrip:trip sentTripID:localTrip.ID];
							[self checkState];

						} failure:^(TKAPIError *__unused e, TKTrip *trip){

// TODO: Conflicts
//							APIResponse *response = e.response;
//							NSString *resolution = [response.data[@"conflict_resolution"] parsedString];
//
//							// If pushed Trip update has been ignored,
//							// add Trips pair to conflicts holding structure
//							if (trip && [resolution containsSubstring:@"ignored"])
//							{
//								NSDictionary *conflictDict = [response.data[@"conflict_info"] parsedDictionary];
//								TKTripConflict *conflict = [TKTripConflict new];
//								conflict.localTrip = localTrip;
//								conflict.remoteTrip = trip;
//								conflict.lastEditor = [conflictDict[@"last_user_name"] parsedString];
//								NSString *dateStr = [conflictDict[@"last_updated_at"] parsedString];
//								conflict.lastUpdate = (dateStr) ? [NSDate dateFrom8601DateTimeString:dateStr] : nil;
//								[_tripConflicts addObject:conflict];
//							}
//
//							// Otherwise process received Trip
//							else if (trip)
								[self processResponseWithTrip:trip sentTripID:localTrip.ID];

							[self checkTripConflicts];
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

			if (updatedFavouriteIDs.count || deletedFavouriteIDs.count)
				_significantUpdatePerformed = YES;

			[self checkTripConflicts];
			[self checkState];

		} failure:^(TKAPIError *__unused error) {
			[self checkState];
		}];

		[self enqueueRequest:listRequest];

		[self checkState];
}

	// Otherwise skip Trips processing
	else [self checkState];
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
		[_tripsManager changeTripWithID:originalTripID toID:trip.ID];

//	// Fill in handling User ID information
//	if (!trip.userID) trip.userID = _currentUserID;

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

	// Leave when there's a pending Trip conflict
	if (_tripConflicts.count != 0)
		return;

	// Move to a next phase
	_state++;

	// Push locally marked Favourites phase if required
	if (_state == TKSynchronizationStateFavourites)
		[self synchronizeFavourites];

	// Perform Changes phase if required
	else if (_state == TKSynchronizationStateChanges)
		[self synchronizeChanges];

	// Fetch Trips updated on API
	else if (_state == TKSynchronizationStateUpdatedTrips)
		[self synchronizeUpdatedTrips];

	// Otherwise finish synchronization loop
	else [self finishSynchronization];
}

- (void)checkTripConflicts
{
//	TKTripConflict *conflict = _tripConflicts.firstObject;
//
//	if (!conflict) return;
//
//	NSString *message = nil;
//
//	if (conflict.lastEditor && conflict.lastUpdate)
//		message = [NSString stringWithFormat:NSLocalizedString(@"A newer version of trip “%@” "
//			"edited by %@ at %@ is available on the server and your pending local changes cannot "
//			"be merged. Which version do you want to keep?", @"Conflict " "alert message"),
//				conflict.localTrip.name, conflict.lastEditor,
//				[[NSDateFormatter sharedDatePickerStyleDateTimeFormatter]
//					stringFromDate:conflict.lastUpdate]];
//	else
//		message = [NSString stringWithFormat:NSLocalizedString(@"A newer version of trip “%@” "
//			"is available on the server and your pending local changes cannot be merged. "
//			"Which version do you want to keep?", @"Conflict alert message"), conflict.localTrip.name];
//
//	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:
//		NSLocalizedString(@"Trip Conflict", @"Alert title") message:message
//		delegate:self cancelButtonTitle:NSLocalizedString(@"Local", @"Button title")
//		otherButtonTitles:NSLocalizedString(@"Server", @"Button title"), nil];
//	alert.tag = kTagAlertTripConflict;
//	alert.tripomaticProperty = conflict;
//	[alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
}

- (void)finishSynchronization
{
	// Set last sync date now to delay next sync appearance
	_lastSynchronization = [NSDate timeIntervalSinceReferenceDate];
//	[SessionManager defaultSession].changesTimestamp = _lastChangesTimestamp;

	SyncLog(@"Synchronization finished");
	_state = TKSynchronizationStateStandby;
	if (_significantUpdatePerformed)
		[self sendNotification:TKSynchronizationNotificationTypeSignificantUpdate];
	[self sendNotification:TKSynchronizationNotificationTypeDone];
}

- (void)cancelSynchronization
{
	for (TKAPIRequest *request in _requests)
		[request cancel];

	[_requests removeAllObjects];

	SyncLog(@"Synchronization cancelled");

	_state = TKSynchronizationStateStandby;
	[self sendNotification:TKSynchronizationNotificationTypeDone];
}

- (void)sendNotification:(TKSynchronizationNotificationType __unused)notification
{
	// TODO
//	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
//
//		switch (notification)
//		{
//			case TKSynchronizationNotificationTypeBegin:
//				[[NotificationCenter defaultCenter] postNotificationName:kNotificationSynchronizationManagerWillStart];
//				break;
//
//			case TKSynchronizationNotificationTypeDone:
//				[[NotificationCenter defaultCenter] postNotificationName:kNotificationSynchronizationManagerDidFinish];
//				break;
//
//			case TKSynchronizationNotificationTypeSignificantUpdate:
//				[[NotificationCenter defaultCenter] postNotificationName:kNotificationSynchronizationManagerDidSignificantUpdate];
//				break;
//		}
//
//	}];
}

- (BOOL)syncInProgress
{
    return (_state != TKSynchronizationStateStandby);
}

@end
