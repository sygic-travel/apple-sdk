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
#import "TKPlacesManager.h"
#import "TKSessionManager+Private.h"
#import "TKUserSettings+Private.h"
#import "Foundation+TravelKit.h"

#ifdef LOG_SYNC
#define SyncLog(__FORMAT__, ...) NSLog(@"[SYNC] " __FORMAT__, ##__VA_ARGS__)
#else
#define SyncLog(...) do { } while (false)
#endif


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
		_state = kSyncStateStandby;
		_queue = [NSOperationQueue new];
		_queue.name = @"Synchronization";
		_queue.maxConcurrentOperationCount = 1;
		if ([_queue respondsToSelector:@selector(setQualityOfService:)])
			_queue.qualityOfService = NSQualityOfServiceBackground;
		_requests = [NSMutableArray array];
		_tripConflicts = [NSMutableArray array];
		_repeatTimer = [NSTimer timerWithTimeInterval:kSynchronizationTimerPeriod target:self
			selector:@selector(synchronizePeriodic) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:_repeatTimer forMode:NSRunLoopCommonModes];
		_lastSynchronization = 0;
	}

	return self;
}


#pragma mark - Plain calls


- (void)synchronize
{
	@synchronized(self) {

		// If we're connected and session allows synchronization
		if (!_blockSynchronization)
		{
			if (_state == kSyncStateStandby)
			{
				[self sendNotification:kSyncNotificationBegin];

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
		else [self sendNotification:kSyncNotificationCancel];
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

		if ((now - _lastSynchronization) > kSynchronizationMinPeriod)
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

	_state = kSyncStateInitializing;

	// Set up fields for current synchronization loop
	_currentAccessToken = [userCredentials.accessToken copy];
	_significantUpdatePerformed = NO;

	// Fire up
	SyncLog(@"Started for user: %@ (%@)", userInfo.userID, userInfo.fullName);

	[self checkState];

	[NSThread currentThread].name = nil;
}


#pragma mark - Phase initializers


//- (void)synchronizeCustomPlaces
//{
//	// Get local Custom Places from the DB and perform PUT/POST requests to Activity API
//
//	BOOL changesAvailable = NO;
//	NSArray *customActivities = [[ActivityManager defaultManager] customActivitiesForUserWithID:_currentUserID];
//
//	for (Activity *a in customActivities)
//	{
//		BOOL activityIsLocal = (a.type & ActivityTypeLocal) > 0;
//
//		if (!activityIsLocal && !a.changed) continue;
//
//		changesAvailable = YES;
//
//		if (activityIsLocal)
//			SyncLog(@"Activity NOT on server – sending: %@", a.ID);
//		else
//			SyncLog(@"Activity NOT up-to-date on server – sending: %@", a.ID);
//
//		void (^success)(Activity *) = ^(Activity *received) {
//
//			if (received) [self processResponseWithActivity:received sentID:a.ID];
//
//			[self checkState];
//
//		};
//
//		void (^failure)(APIError *e) = ^(APIError *e) {
//
//			if (e.response.code == 404) {
//
//				SyncLog(@"Activity NOT on server – deleting: %@", a.ID);
//
//				[[ActivityManager defaultManager] removeActivity:a];
//				_significantUpdatePerformed = YES;
//			}
//
//			[self checkState];
//		};
//
//		APIRequest *request = nil;
//
//		if (activityIsLocal)
//			request = [[APIRequest alloc] initAsNewPlaceRequestWithActivity:a success:success failure:failure];
//		else
//			request = [[APIRequest alloc] initAsUpdatePlaceRequestWithActivity:a success:success failure:failure];
//
//		request.accessToken = _currentAccessToken;
//		[_requests addObject:request];
//		[request start];
//	}
//
//	if (!changesAvailable)
//		[self checkState];
//}

//- (void)synchronizeLeavedTrips
//{
//	BOOL changesAvailable = NO;
//
//	NSArray *leavedTrips = [[TripsManager defaultManager] getArchivedTripsForUserWithID:_currentUserID];
//
//	for (TripInfo *trip in leavedTrips)
//	{
//		if ([trip.ownerID isEqualToString:_currentUserID])
//			continue;
//
//		changesAvailable = YES;
//
//		APIRequest *request = [[APIRequest alloc] initAsUnsubscribeTripRequestForTripWithID:trip.ID success:^{
//
//			[[TripsManager defaultManager] deleteTripWithID:trip.ID];
//
//			if ([[SessionManager defaultSession].activeTrip.ID isEqualToString:trip.ID])
//				[[SessionManager defaultSession] reloadActiveTrip];
//
//			[self checkState];
//
//		} failure:^{ [self checkState]; }];
//
//		request.accessToken = _currentAccessToken;
//		[_requests addObject:request];
//		[request start];
//	}
//
//	if (!changesAvailable)
//		[self checkState];
//}

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


	TKAPIRequest *request = nil;
	void (^failure)(TKAPIError *) = ^(TKAPIError *__unused e){
		[self checkState];
	};

	// Locally added Favourites
	for (NSString *itemID in favouritesToAdd)
	{
		request = [[TKAPIRequest alloc] initAsFavoriteItemAddRequestWithID:itemID success:^{

			[_session storeServerFavoriteIDsAdded:@[ itemID ] removed:@[ ]];
			[self checkState];

		} failure:failure];

//		request.accessToken = _currentAccessToken;
		[_requests addObject:request];
		[request start];
	}

	// Locally removed Favourites
	for (NSString *itemID in favouritesToRemove)
	{
		request = [[TKAPIRequest alloc] initAsFavoriteItemDeleteRequestWithID:itemID success:^{

			[_session storeServerFavoriteIDsAdded:@[ ] removed:@[ itemID ]];
			[self checkState];

		} failure:failure];

//		request.accessToken = _currentAccessToken;
		[_requests addObject:request];
		[request start];
	}

	[self checkState];
}

- (void)synchronizeChanges
{
	// Get lastest updates from Changes API and do all the magic

	TKSessionManager *session = [TKSessionManager sharedSession];
	TKUserSettings *settings = [TKUserSettings sharedSettings];

	// Check for user's trip changes
	if (session.credentials != nil)
	{
		NSDate *since = nil;

		NSTimeInterval changesTimestamp = settings.changesTimestamp;
		if (changesTimestamp > 0) since = [NSDate dateWithTimeIntervalSince1970:changesTimestamp];

		TKAPIRequest *listRequest = [[TKAPIRequest alloc] initAsChangesRequestSince:since
		success:^(NSDictionary<NSString *,NSNumber *> *updatedTripsDict, NSArray<NSString *> *deletedTripIDs,
		NSArray<NSString *> *updatedFavouriteIDs, NSArray<NSString *> *deletedFavouriteIDs, BOOL updatedSettings, NSDate *timestamp) {

			// Report online statistics
			SyncLog(@"Got list with %tu Trip updates and %tu Favourite updates",
			        updatedTripsDict.allKeys.count + deletedTripIDs.count,
			        updatedFavouriteIDs.count + deletedFavouriteIDs.count);

			// Update Changes API timestamp
			_lastChangesTimestamp = settings.changesTimestamp = [timestamp timeIntervalSince1970];

//			// Set up comparable arrays
//			NSMutableArray *currentOnlineTripIDs = [updatedTripsDict.allKeys mutableCopy];
//			NSArray *currentDBTrips = [[[TripsManager defaultManager] getTripsForUserWithID:_currentUserID]
//				.reverseObjectEnumerator allObjects];
//
//			// Walk through the local trips to send to server (when signed in)
//			for (Trip *localTrip in currentDBTrips) {
//
//				// Find out whether trip has been updated
//				BOOL updated = updatedTripsDict[localTrip.ID] != nil;
//
//				// Hold sending this update when trip is active and changed after sync loop began
//				if ([localTrip.ID isEqualToString:session.activeTrip.ID] && session.activeTrip.changedSinceLastSynchronization)
//					continue;
//
//				// If not marked as updated on server...
//				if (!updated) {
//
//					BOOL deletedOnRemote = [deletedTripIDs containsObject:localTrip.ID];
//
//					// ...and is user-created (with no server-generated ID)
//					if ([localTrip.ID hasPrefix:@LOCAL_TRIP_PREFIX]) {
//
//						SyncLog(@"Trip NOT on server yet – sending: %@", localTrip);
//
//						APIRequest *request = [[APIRequest alloc] initAsNewTripRequestForTrip:localTrip success:^(Trip *trip) {
//
//							[self processResponseWithTrip:trip sentTripID:localTrip.ID];
//							[self checkState];
//
//						} failure:^{
//							[self checkState];
//						}];
//
//						request.accessToken = _currentAccessToken;
//						[_requests addObject:request];
//						[request start];
//					}
//
//					// ...if locally modified, send updates to the server
//
//					else if (!deletedOnRemote && localTrip.changed) {
//
//						SyncLog(@"Trip NOT up-to-date on server – sending: %@", localTrip);
//						APIRequest *updateTripRequest = [[APIRequest alloc] initAsUpdateTripRequestForTrip:localTrip success:^(Trip *trip) {
//
//							[self processResponseWithTrip:trip sentTripID:localTrip.ID];
//							[self checkState];
//
//						} failure:^(APIError *e, Trip *trip){
//
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
//								[self processResponseWithTrip:trip sentTripID:localTrip.ID];
//
//							[self checkTripConflicts];
//							[self checkState];
//						}];
//
//						updateTripRequest.accessToken = _currentAccessToken;
//						[_requests addObject:updateTripRequest];
//						[updateTripRequest start];
//					}
//
//					// ...otherwise:
//					// - Trips returned as deleted from server can be dropped directly
//					// - In case we request Changes API with 'since' timestamp 0, Trips not found in response
//					//   can be deleted as these are not present on the server
//
//					else if (deletedOnRemote || session.changesTimestamp == 0)
//					{
//						SyncLog(@"Trip NOT on server – deleting: %@", localTrip);
//
//						if ([session.activeTrip.ID isEqualToString:localTrip.ID])
//							session.activeTrip = nil;
//
//						[[TripsManager defaultManager] deleteTripWithID:localTrip.ID];
//					}
//
//				}
//
//				else {
//
//					//////////////////////////
//					// Method A: Push changes to server so it can tell us what to do
//					//////////////////////////
//					//
//					// Success: Changes accepted
//					// Error: Begin conflict resolution of Trip if verbosely ignored, ignore otherwise
//					//
//
//					// Server sent updated Trip which is also locally modified.
//					// Try pushing it so we get one of [success, failure, conflict].
//
//					if (localTrip.changed) {
//
//						// Do not further process matching remote Trip, we decide what to do here
//						[currentOnlineTripIDs removeObject:localTrip.ID];
//
//						SyncLog(@"Trip conflicting with server - sending: %@", localTrip);
//						APIRequest *request = [[APIRequest alloc] initAsUpdateTripRequestForTrip:localTrip success:^(Trip *trip) {
//
//							[self processResponseWithTrip:trip sentTripID:localTrip.ID];
//							[self checkState];
//
//						} failure:^(APIError *e, Trip *trip){
//
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
//								[self processResponseWithTrip:trip sentTripID:localTrip.ID];
//
//							[self checkTripConflicts];
//							[self checkState];
//						}];
//
//						request.accessToken = _currentAccessToken;
//						[_requests addObject:request];
//						[request start];
//
//						//////////////////////////
//						// Method B: Try some local-side rules
//						// Note: Not maintained
//						//////////////////////////
//
////						BOOL canSafelyPush = matchingOnlineTrip.rights & TripRightsEdit;
////
////						// Break if I can't push any changes so local data will be overwritten later
////						if (!canSafelyPush)
////							continue;
////
////						// Do not further process matching remote Trip, we decide what to do here
////						[currentOnlineTrips removeObject:matchingOnlineTrip];
////
////						// Announce a conflict if remote data are newer than local
////						if ([matchingOnlineTrip.lastUpdate timeIntervalSinceDate:localTrip.lastUpdate] > 0)
////						{
////							// Add Trips pair to conflicts holding structure
////							TKTripConflict *conflict = [TKTripConflict new];
////							conflict.localTrip = localTrip;
////							conflict.remoteTrip = matchingOnlineTrip;
////							[_tripConflicts addObject:conflict];
////						}
////
////						// Otherwise force-push local data
////						else
////						{
////							localTrip.version = matchingOnlineTrip.version;
////							localTrip.lastUpdate = [NSDate now];
////							localTrip.rights = matchingOnlineTrip.rights;
////
////							SyncLog(@"Trip NOT up-to-date on server – sending: %@", localTrip);
////							APIRequest *request = [[APIRequest alloc] initAsUpdateTripRequestForTrip:
////							  localTrip success:^(Trip *trip) {
////
////								[self processResponseWithTrip:trip sentTripID:localTrip.ID];
////								[self checkState];
////
////							} failure:^(APIError *e, Trip* trip){
////								[self checkState];
////							}];
////
////							request.accessToken = _currentAccessToken;
////							[_requests addObject:request];
////							[request start];
////						}
//
//					}
//
//				}
//
//			}
//
//			NSMutableArray *tripsToFetch = [NSMutableArray arrayWithCapacity:5];
//
//			// Walk through the server trips
//			for (NSString *onlineTripID in currentOnlineTripIDs) {
//
//				// Initial rule for app type
//				BOOL shouldProcess = YES;
//				NSUInteger onlineTripVersion = [updatedTripsDict[onlineTripID] unsignedIntegerValue];
//
//				// If found in the DB and up-to-date, do not request it except for
//				// the case the Trip is foreign -- changes in collaborators and its rights
//				// do not change Trip version
//				for (Trip *dbTrip in currentDBTrips)
//					if ([dbTrip.ID isEqualToString:onlineTripID])
//					{
//						if (dbTrip.version == onlineTripVersion)
//							if ([dbTrip.userID isEqual:dbTrip.ownerID])
//								shouldProcess = NO;
//						break;
//					}
//
//				if (!shouldProcess) continue;
//
//				SyncLog(@"Trip updated on server - queueing: %@", onlineTripID);
//				[tripsToFetch addObject:onlineTripID];
//			}
//
//			_tripIDsToFetch = [tripsToFetch copy];

			// Process Favourite fields

			[session storeServerFavoriteIDsAdded:updatedFavouriteIDs removed:deletedFavouriteIDs];

			if (updatedFavouriteIDs.count || deletedFavouriteIDs.count)
				_significantUpdatePerformed = YES;

			[self checkTripConflicts];
			[self checkState];

		} failure:^(TKAPIError *__unused error) {
			[self checkState];
		}];

//		listRequest.accessToken = _currentAccessToken;
		[_requests addObject:listRequest];
		[listRequest start];

		[self checkState];
}

	// Otherwise skip Trips processing
	else [self checkState];
}

//- (void)synchronizeUpdatedTrips
//{
//	NSMutableSet *storedIDs = [NSMutableSet setWithCapacity:_tripIDsToFetch.count];
//
//	// Iterate the Trip IDs from API
//	for (NSString *tripID in _tripIDsToFetch)
//	{
//		[storedIDs addObject:tripID];
//
//		if (storedIDs.count >= 25 || (storedIDs.count && tripID == _tripIDsToFetch.lastObject))
//		{
//			APIRequest *request = [[APIRequest alloc] initAsBatchTripRequestForIDs:
//			  storedIDs.allObjects success:^(NSArray<Trip *> *trips) {
//
//				for (Trip *t in trips)
//					[self processResponseWithTrip:t sentTripID:t.ID];
//
//				[self checkState];
//
//			} failure:^{
//				[self checkState];
//			}];
//
//			request.accessToken = _currentAccessToken;
//			[_requests addObject:request];
//			[request silentStart];
//
//			[storedIDs removeAllObjects];
//		}
//	}
//
//	// Check state
//	[self checkState];
//}

//- (void)synchronizeMissingItems
//{
//	// Get missing IDs from the DB
//	NSArray *missingIDs = [[ActivityManager defaultManager] missingActivityIDs];
//
//	NSMutableSet *storedIDs = [NSMutableSet setWithCapacity:missingIDs.count];
//	NSMutableSet *storedCustomIDs = [NSMutableSet setWithCapacity:missingIDs.count];
//
//	// Fetch Items missing from the DB from API
//
//	for (NSString *itemID in missingIDs)
//	{
//		ActivityType type = itemID.typeOfActivityID;
//
//		if (!itemID || type & ActivityTypeLocal) {}
//		else if (type & ActivityTypeCustom) [storedCustomIDs addObject:itemID];
//		else [storedIDs addObject:itemID];
//
//		// Ask for missing IDs in batches of 25
//		if (storedIDs.count >= 25 || (storedIDs.count && itemID == missingIDs.lastObject))
//		{
//			APIRequest *request = [[APIRequest alloc] initAsBatchPlaceRequestForItemIDs:
//			   storedIDs.allObjects success:^(NSArray<Activity *> *activities) {
//
//				[self processResponseWithBatchActivities:activities];
//				[self checkState];
//
//			} failure:^{
//				[self checkState];
//			}];
//
//			request.accessToken = _currentAccessToken;
//			[_requests addObject:request];
//			[request silentStart];
//
//			[storedIDs removeAllObjects];
//		}
//
//		if (storedCustomIDs.count >= 25 || (storedCustomIDs.count && itemID == missingIDs.lastObject))
//		{
//			APIRequest *request = [[APIRequest alloc] initAsBatchPlaceRequestForItemIDs:
//			  storedCustomIDs.allObjects success:^(NSArray<Activity *> *activities) {
//
//				[self processResponseWithBatchActivities:activities];
//				[self checkState];
//
//			} failure:^{
//				[self checkState];
//			}];
//
//			request.accessToken = _currentAccessToken;
//			[_requests addObject:request];
//			[request silentStart];
//
//			[storedCustomIDs removeAllObjects];
//		}
//	}
//
//	// Check state
//	[self checkState];
//}


#pragma mark - API responses workers


- (void)processResponseWithTrip:(TKTrip *)trip sentTripID:(NSString *)originalTripID
{
//	SyncLog(@"Processing Trip: %@", trip);
//
//	TripsManager *tm = [TripsManager defaultManager];
//	SessionManager *sm = [SessionManager defaultSession];
//	Trip *activeTrip = sm.activeTrip;
//
//	BOOL activeUpdated = ([activeTrip.ID isEqualToString:trip.ID] ||
//						  [activeTrip.ID isEqualToString:originalTripID]);
//
//	// Update Trip ID if needed
//	if (originalTripID && ![originalTripID isEqualToString:trip.ID])
//		[tm changeTripWithID:originalTripID toID:trip.ID];
//
//	if (activeUpdated)
//	{
//		// If changed since last synchronization, do not update with these data, only update
//		// ID and version to prevent sending duplicate trips with same past version
//		if (activeTrip.changedSinceLastSynchronization) {
//			activeTrip.ID = trip.ID;
//			activeTrip.version = trip.version;
//			[sm saveActiveTripUpdates];
//			return;
//		}
//	}
//
//	// Fill in handling User ID information
//	if (!trip.userID) trip.userID = _currentUserID;
//
//	// If there's already a Trip in the DB, update, otherwise add new Trip
//	[tm saveOrUpdateTrip:trip forUserWithID:_currentUserID];
//
//	// Refresh active Trip if changed
//	if (activeUpdated)
//		sm.activeTrip = trip;
}

- (void)processResponseWithBatchActivities:(NSArray *)activities
{
//	// Size of Activities array to save in batch
//	NSUInteger savingBatch = ([[UIDevice currentDevice] isPowerfulDevice]) ? 100:50;
//
//	NSMutableArray *toSave = [NSMutableArray array];
//
//	for (Activity *a in activities)
//	{
//		SyncLog(@"Got Activity: %@", a);
//
//		// Update Activity owner in case of Custom Activity
//		if (a.type & ActivityTypeCustom && !a.owner)
//			a.owner = _currentUserID;
//
//		// Stack current Activity
//		[toSave addObject:a];
//
//		// Save stacked Activities if needed
//		if (toSave.count >= savingBatch || a == activities.lastObject)
//		{
//			[[ActivityManager defaultManager] batchSaveActivities:toSave];
//			[toSave removeAllObjects];
//		}
//	}
//
//	_significantUpdatePerformed = YES;
}

//- (void)processResponseWithActivity:(Activity *)activity sentID:(NSString *)sentID
//{
//	if (!activity) return;
//
//	SyncLog(@"Got Activity: %@", activity);
//
//	// Update Activity ID in the DB if changed
//	if (![sentID isEqualToString:activity.ID])
//		[[ActivityManager defaultManager] changeIDOfActivityWithID:sentID toID:activity.ID];
//
//	// Update Activity owner in case of Custom Activity
//	if (activity.type & ActivityTypeCustom)
//		activity.owner = _currentUserID;
//
//	[[ActivityManager defaultManager] saveActivity:activity];
//	_significantUpdatePerformed = YES;
//}
//
//- (void)processResponseWithBatchDestinations:(NSArray *)destinations
//{
//#ifdef LOG_SYNC
//	for (Activity *d in destinations)
//		SyncLog(@"Got destination: %@", d);
//#endif
//
//	[[DestinationManager defaultManager] batchSaveDestinations:destinations];
//
//}
//
//- (void)processResponseWithDestination:(Activity *)destination
//{
//	if (!destination) return;
//
//	[self processResponseWithBatchDestinations:@[ destination ]];
//}


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

	// Push locally created Custom Places phase if required
//	if (_state == kSyncStateCustomPlaces)
//		[self synchronizeCustomPlaces];

	// Push locally leaved foreign Trips
//	else if (_state == kSyncStateLeavedTrips)
//		[self synchronizeLeavedTrips];

	// Push locally marked Favourites phase if required
//	else
	if (_state == kSyncStateFavourites)
		[self synchronizeFavourites];

	// Perform Changes phase if required
	else if (_state == kSyncStateChanges)
		[self synchronizeChanges];

	// Fetch Trips updated on API
//	else if (_state == kSyncStateUpdatedTrips)
//		[self synchronizeUpdatedTrips];

	// Fetch missing items from API
//	else if (_state == kSyncStateMissingItems)
//		[self synchronizeMissingItems];

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
	_state = kSyncStateStandby;
	if (_significantUpdatePerformed)
		[self sendNotification:kSyncNotificationSignificantUpdate];
	[self sendNotification:kSyncNotificationDone];
}

- (void)cancelSynchronization
{
	for (TKAPIRequest *request in _requests)
		[request cancel];

	[_requests removeAllObjects];

	SyncLog(@"Synchronization cancelled");

	_state = kSyncStateStandby;
	[self sendNotification:kSyncNotificationDone];
}

- (void)sendNotification:(SyncNotificationType)notification
{
//	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
//
//		switch (notification)
//		{
//			case kSyncNotificationBegin:
//				[[NotificationCenter defaultCenter] postNotificationName:kNotificationSynchronizationManagerWillStart];
//				break;
//
//			case kSyncNotificationDone:
//				[[NotificationCenter defaultCenter] postNotificationName:kNotificationSynchronizationManagerDidFinish];
//				break;
//
//			case kSyncNotificationSignificantUpdate:
//				[[NotificationCenter defaultCenter] postNotificationName:kNotificationSynchronizationManagerDidSignificantUpdate];
//				break;
//		}
//
//	}];
}

- (BOOL)syncInProgress
{
    return (_state != kSyncStateStandby);
}

@end
