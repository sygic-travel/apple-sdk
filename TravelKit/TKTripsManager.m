//
//  TKTripsManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 30/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "NSDate+Tripomatic.h"
#import "NSObject+Parsing.h"
#import "Foundation+TravelKit.h"
#import "TKTripsManager+Private.h"

#import "TKDatabaseManager+Private.h"
#import "TKAPI+Private.h"


@interface TKTripsManager ()

@property (nonatomic, strong) TKDatabaseManager *database;
@property (atomic, strong) NSOperationQueue *workingQueue;

@end


#pragma mark - Implementation


@implementation TKTripsManager


+ (TKTripsManager *)sharedManager
{
    static dispatch_once_t once = 0;
    static TKTripsManager *shared = nil;
    dispatch_once(&once, ^{ shared = [[self alloc] init]; });
    return shared;
}


#pragma mark - Init methods


- (instancetype)init
{
	if (self = [super init])
	{
		_database = [TKDatabaseManager sharedManager];

		_workingQueue = [[NSOperationQueue alloc] init];
		_workingQueue.name = @"Trip working queue";
		_workingQueue.maxConcurrentOperationCount = 2;
	}

	return self;
}


#pragma mark - Trip methods


- (TKTrip *)tripWithID:(NSString *)tripID
{
	if (!tripID) return nil;

	NSDictionary *tripDict = [[_database runQuery:@"SELECT * FROM %@ WHERE id = ? LIMIT 1;"
					tableName:kTKDatabaseTableTrips data:@[ tripID ]] lastObject];

	// If there were no Trips...
	if (!tripDict) return nil;

	NSArray *dayDicts = [_database runQuery:@"SELECT * FROM %@ WHERE trip_id = ? "
		"ORDER BY day_index ASC;" tableName:kTKDatabaseTableTripDays data:@[ tripID ]];

	NSArray *dayItemDicts = [_database runQuery:@"SELECT * FROM %@ WHERE trip_id = ? "
		"ORDER BY day_index ASC, item_index ASC;" tableName:kTKDatabaseTableTripDayItems data:@[ tripID ]];

	TKTrip *trip = [[TKTrip alloc] initFromDatabase:tripDict dayDicts:dayDicts dayItemDicts:dayItemDicts];

	// ...or Trip is not valid, return nil
	if (!trip) return nil;

	// Return object
	return trip;
}

- (NSArray<TKTrip *> *)allTrips
{
	NSMutableArray<TKTrip *> *trips = [NSMutableArray arrayWithCapacity:10];

	NSArray *tripDicts = [_database runQuery:@"SELECT * FROM %@ "
		"ORDER BY updated_at DESC;" tableName:kTKDatabaseTableTrips];

	if (!tripDicts.count) return @[ ];

	NSArray *tripIDs = [tripDicts mappedArrayUsingBlock:^id(NSDictionary *dict) {
		return [dict[@"id"] parsedString];
	}];

	NSString *tripsStr = [NSString stringWithFormat:@"'%@'", [tripIDs componentsJoinedByString:@"','"]];

	NSArray *dayDicts = [_database runQuery:[NSString
	  stringWithFormat:@"SELECT * FROM %@ WHERE trip_id IN (%@) "
	    "ORDER BY day_index ASC;", kTKDatabaseTableTripDays, tripsStr]];

	NSArray *itemDicts = [_database runQuery:[NSString
	  stringWithFormat:@"SELECT * FROM %@ WHERE trip_id IN (%@) "
	    "ORDER BY day_index ASC, item_index ASC;", kTKDatabaseTableTripDayItems, tripsStr]];

	for (NSDictionary *tripDict in tripDicts)
	{
		NSString *tripID = [tripDict[@"id"] parsedString];

		if (!tripID) continue;

		NSArray *tripDayDicts = [dayDicts filteredArrayUsingBlock:^BOOL(NSDictionary *dayDict) {
			return [[dayDict[@"trip_id"] parsedString] isEqualToString:tripID];
		}];

		NSArray *tripItemDicts = [itemDicts filteredArrayUsingBlock:^BOOL(NSDictionary *itemDict) {
			return [[itemDict[@"trip_id"] parsedString] isEqualToString:tripID];
		}];

		TKTrip *trip = [[TKTrip alloc] initFromDatabase:tripDict
			dayDicts:tripDayDicts dayItemDicts:tripItemDicts];

		if (!trip) continue;

		[trips addObject:trip];
	}

	return trips;
}

- (TKTripInfo *)infoForTripWithID:(NSString *)tripID
{
	if (!tripID) return nil;

	NSDictionary *result = [[_database runQuery:@"SELECT * FROM %@ WHERE id = ? LIMIT 1;"
									  tableName:kTKDatabaseTableTrips data:@[ tripID ]] lastObject];

	// If there were no results...
	if (!result) return nil;

	// Return object
	return [[TKTripInfo alloc] initFromDatabase:result];
}

- (BOOL)insertTrip:(TKTrip *)trip
{
	NSString *tripID = trip.ID;

	if (!tripID) return NO;

	id tripName = trip.name ?: [NSNull null];
	id startDate = [trip.startDate dateString] ?: [NSNull null];
	id lastUpdate = [[NSDateFormatter shared8601DateTimeFormatter] stringFromDate:trip.lastUpdate] ?: [NSNull null];
	id ownerID = trip.ownerID ?: [NSNull null];
	id destinationIDs = [trip.destinationIDs componentsJoinedByString:@"|"] ?: [NSNull null];

	BOOL ok = YES;

	ok &= [_database runUpdate:@"INSERT INTO %@ (id, name, version, days, destination_ids, "
		"owner_id, starts_on, updated_at, changed, deleted, privacy, rights) VALUES "
		"(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);" tableName:kTKDatabaseTableTrips data:@[
			tripID, tripName, @(trip.version), @(trip.days.count), destinationIDs, ownerID,
			startDate, lastUpdate, @(trip.changed), @(trip.deleted), @(trip.privacy),
			@(trip.rights)
		]];

	NSMutableArray *queries = [NSMutableArray arrayWithCapacity:5*trip.days.count];
	NSMutableArray *data    = [NSMutableArray arrayWithCapacity:5*trip.days.count];

	[trip.days enumerateObjectsUsingBlock:^(TKTripDay *day, NSUInteger dayIndex, BOOL *__unused s1) {

		id note = day.note ?: [NSNull null];

		if (day.note.length) {
			[queries addObject:[NSString stringWithFormat:
			   @"INSERT INTO %@ (trip_id, day_index, note) VALUES (?, ?, ?);", kTKDatabaseTableTripDays]];
			[data addObject:@[ tripID, @(dayIndex), note ]];
		}

		[day.items enumerateObjectsUsingBlock:^(TKTripDayItem *item, NSUInteger itemIndex, BOOL *__unused s2) {

			id itemID = item.placeID ?: [NSNull null];
			id startTime = item.startTime ?: [NSNull null];
			id duration = item.duration ?: [NSNull null];
			id itemNote = item.note ?: [NSNull null];

			id transMode = @(item.transportMode);
			id transAvoid = @(item.transportAvoid);
			id transStartTime = item.transportStartTime ?: [NSNull null];
			id transDuration = item.transportDuration ?: [NSNull null];
			id transNote = item.transportNote ?: [NSNull null];
			id transPoly = item.transportPolyline ?: [NSNull null];

			[queries addObject:[NSString stringWithFormat:
			   @"INSERT INTO %@ (trip_id, day_index, item_index, item_id, start_time, "
			    "duration, note, transport_mode, transport_avoid, "
				"transport_start_time, transport_duration, transport_note, transport_polyline) "
				"VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);", kTKDatabaseTableTripDayItems]];
			[data addObject:@[ tripID, @(dayIndex), @(itemIndex), itemID,
			   startTime, duration, itemNote, transMode, transAvoid,
			   transStartTime, transDuration, transNote, transPoly ]];
		}];
	}];

	ok &= [_database runUpdateTransactionWithQueries:queries dataArray:data];

	return ok;
}

- (BOOL)saveTrip:(TKTrip *)trip
{
	trip.changed = YES;
	trip.lastUpdate = [NSDate now];

	return [self storeTrip:trip];
}

- (BOOL)storeTrip:(TKTrip *)trip
{
	[self deleteTripWithID:trip.ID];
	return [self insertTrip:trip];
}

- (BOOL)deleteTripWithID:(NSString *)tripID
{
	if (!tripID) return NO;

	return [self deleteTripsWithIDs:@[ tripID ]];
}

- (BOOL)deleteTripsWithIDs:(NSArray<NSString *> *)tripIDs
{
	if (!tripIDs.count) return YES;

	BOOL ok = YES;
	NSString *tripsStr = [NSString stringWithFormat:@"'%@'", [tripIDs componentsJoinedByString:@"','"]];

	ok &= [_database runUpdate:[NSString stringWithFormat:
			@"DELETE FROM %@ WHERE id IN (%@);", kTKDatabaseTableTrips, tripsStr]];
	ok &= [_database runUpdate:[NSString stringWithFormat:
			@"DELETE FROM %@ WHERE trip_id IN (%@);", kTKDatabaseTableTripDays, tripsStr]];
	ok &= [_database runUpdate:[NSString stringWithFormat:
			@"DELETE FROM %@ WHERE trip_id IN (%@);", kTKDatabaseTableTripDayItems, tripsStr]];

	return ok;
}

- (BOOL)changeTripWithID:(NSString *)originalID toID:(NSString *)newID
{
	BOOL ok = [_database runUpdate:@"UPDATE %@ SET id = ? WHERE id = ?;"
						 tableName:kTKDatabaseTableTrips data:@[ newID, originalID ]];
	    ok &= [_database runUpdate:@"UPDATE %@ SET trip_id = ? WHERE trip_id = ?;"
						 tableName:kTKDatabaseTableTripDays data:@[ newID, originalID ]];
	    ok &= [_database runUpdate:@"UPDATE %@ SET trip_id = ? WHERE trip_id = ?;"
						 tableName:kTKDatabaseTableTripDayItems data:@[ newID, originalID ]];

	return ok;
}


#pragma mark - Trip Info methods


- (NSArray<TKTripInfo *> *)allTripInfos
{
	NSArray *results = [_database runQuery:@"SELECT * FROM %@ "
		"ORDER BY updated_at DESC;" tableName:kTKDatabaseTableTrips];

	NSMutableArray *trips = [NSMutableArray arrayWithCapacity:results.count];
	for (NSDictionary *row in results) {
		TKTripInfo *trip = [[TKTripInfo alloc] initFromDatabase:row];
		if (trip) [trips addObject:trip];
	}

	return trips;
}

- (NSArray<TKTripInfo *> *)upcomingTripInfos
{
	NSDate *upcomingLimit = [[NSDate now] midnight];

	NSString *upcomingString = [[NSDateFormatter sharedDateFormatter] stringFromDate:upcomingLimit];

	if (!upcomingString.length) return @[ ];

	NSArray *results = [_database runQuery:@"SELECT * FROM %@ WHERE "
						"(deleted != 1 OR deleted IS NULL) AND starts_on >= ? ORDER by starts_on ASC"
								 tableName:kTKDatabaseTableTrips data:@[ upcomingString ]];

	NSMutableArray *trips = [NSMutableArray arrayWithCapacity:results.count];
	for (NSDictionary *row in results) {
		TKTripInfo *trip = [[TKTripInfo alloc] initFromDatabase:row];
		if (trip) [trips addObject:trip];
	}

	return trips;
}

- (NSArray<TKTripInfo *> *)pastTripInfos
{
	NSDate *pastLimit = [[NSDate now] midnight];

	NSString *pastString = [[NSDateFormatter sharedDateFormatter] stringFromDate:pastLimit];

	if (!pastString.length) return @[ ];

	NSArray *results = [_database runQuery:@"SELECT * FROM %@ WHERE "
						"(deleted != 1 OR deleted IS NULL) AND starts_on < ? ORDER by starts_on DESC"
								 tableName:kTKDatabaseTableTrips data:@[ pastString ]];

	NSMutableArray *trips = [NSMutableArray arrayWithCapacity:results.count];
	for (NSDictionary *row in results) {
		TKTripInfo *trip = [[TKTripInfo alloc] initFromDatabase:row];
		if (trip) [trips addObject:trip];
	}

	return trips;
}

- (NSArray<TKTripInfo *> *)futureTripInfos
{
	// Get Trips starting not before tomorrow /* modified at least 2 days before start */

	NSArray *results = [_database runQuery:@"SELECT * FROM %@ WHERE "
		"(deleted != 1 OR deleted IS NULL) AND strftime('%Y-%m-%d',starts_on) > "
		"DATE('now','start of day','+30 minutes') "
		/* AND strftime('%Y-%m-%d',starts_on) >= DATE(strftime('%Y-%m-%d',updated_at),'+2 days') */
		" ORDER BY updated_at DESC" tableName:kTKDatabaseTableTrips];

	NSMutableArray *trips = [NSMutableArray arrayWithCapacity:results.count];
	for (NSDictionary *row in results) {
		TKTripInfo *trip = [[TKTripInfo alloc] initFromDatabase:row];
		if (trip) [trips addObject:trip];
	}

	return trips;
}

- (NSArray<TKTripInfo *> *)tripInfosInYear:(NSInteger)year
{
	NSArray *results = nil;

	results = [_database runQuery:@"SELECT * FROM %@ WHERE starts_on LIKE ? AND "
		"(deleted != 1 OR deleted IS NULL) ORDER BY updated_at DESC" tableName:kTKDatabaseTableTrips
			data:@[ [NSString stringWithFormat:@"%zd%%", year] ]];

	NSMutableArray *trips = [NSMutableArray arrayWithCapacity:results.count];
	for (NSDictionary *row in results) {
		TKTripInfo *trip = [[TKTripInfo alloc] initFromDatabase:row];
		if (trip) [trips addObject:trip];
	}

	return trips;
}

- (NSArray<TKTripInfo *> *)unscheduledTripInfos
{
	NSArray *results = nil;

	results = [_database runQuery:@"SELECT * FROM %@ WHERE starts_on IS NULL AND "
		"(deleted != 1 OR deleted IS NULL) ORDER BY updated_at DESC" tableName:kTKDatabaseTableTrips];

	NSMutableArray *trips = [NSMutableArray arrayWithCapacity:results.count];
	for (NSDictionary *row in results) {
		TKTripInfo *trip = [[TKTripInfo alloc] initFromDatabase:row];
		if (trip) [trips addObject:trip];
	}

	return trips;
}

- (NSArray<TKTripInfo *> *)deletedTripInfos
{
	NSArray *results = nil;

	results = [_database runQuery:@"SELECT * FROM %@ WHERE "
		"deleted = 1 ORDER BY updated_at DESC" tableName:kTKDatabaseTableTrips];

	NSMutableArray *trips = [NSMutableArray arrayWithCapacity:results.count];
	for (NSDictionary *row in results) {
		TKTripInfo *trip = [[TKTripInfo alloc] initFromDatabase:row];
		if (trip) [trips addObject:trip];
	}

	return trips;
}

- (NSArray<TKTripInfo *> *)changedTripInfos
{
	NSArray *results = nil;

	results = [_database runQuery:@"SELECT * FROM %@ WHERE "
		"changed = 1 ORDER BY updated_at DESC" tableName:kTKDatabaseTableTrips];

	NSMutableArray *trips = [NSMutableArray arrayWithCapacity:results.count];
	for (NSDictionary *row in results) {
		TKTripInfo *trip = [[TKTripInfo alloc] initFromDatabase:row];
		if (trip) [trips addObject:trip];
	}

	return trips;
}

- (NSArray<NSNumber *> *)yearsOfActiveTrips
{
	NSArray *results = [_database runQuery:@"SELECT DISTINCT SUBSTR(starts_on,1,4) year FROM %@ "
		"WHERE starts_on NOT NULL AND (deleted != 1 OR deleted IS NULL) "
		"ORDER BY year DESC;" tableName:kTKDatabaseTableTrips];

	NSMutableArray<NSNumber *> *years = [NSMutableArray arrayWithCapacity:results.count];
	for (NSDictionary *row in results) {
		NSNumber *year = @([row[@"year"] integerValue]);
		if (year.integerValue > 0) [years addObject:year];
	}

	return years;
}

- (void)saveTripInfo:(TKTripInfo *)trip
{
	if (!trip) return;

	TKTripInfo *local = [self infoForTripWithID:trip.ID];

	id tripID = trip.ID ?: [NSNull null];
	id tripName = trip.name ?: [NSNull null];
	id tripVersion = @(trip.version);
	id tripDaysCount = @(trip.daysCount);
	id tripDestinations = [trip.destinationIDs componentsJoinedByString:@"|"] ?: [NSNull null];
	id tripOwnerID = trip.ownerID ?: [NSNull null];

	id tripDateStart = [trip.startDate dateString] ?: [NSNull null];
	id tripLastUpdate = [[NSDate now] a8601DateTimeString] ?: [NSNull null];
	id tripChanged = @(trip.changed);
	id tripDeleted = @(trip.deleted);
	id tripPrivacy = @(trip.privacy);
	id tripRights = @(trip.rights);

	// Insert or Update

	if (!local)
		[_database runUpdate:@"INSERT INTO %@ (id, name, version, days, destination_ids, owner_id, starts_on, "
		 "updated_at, changed, deleted, privacy, rights) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
			tableName:kTKDatabaseTableTrips data:@[ tripID, tripName, tripVersion, tripDaysCount,
				tripDestinations, tripOwnerID, tripDateStart, tripLastUpdate,
				tripChanged, tripDeleted, tripPrivacy, tripRights]];
	else
		[_database runUpdate:@"UPDATE %@ SET name = ?, version = ?, days = ?, destination_ids = ?, "
		 "owner_id = ?, starts_on = ?, updated_at = ?, changed = ?, deleted = ?, privacy = ?, "
		 "rights = ? WHERE id = ?;" tableName:kTKDatabaseTableTrips data:@[ tripName, tripVersion,
			tripDaysCount, tripDestinations, tripOwnerID, tripDateStart, tripLastUpdate,
			tripChanged, tripDeleted, tripPrivacy, tripRights, tripID ]];
}


#pragma mark - API stuff


- (void)fetchTripWithID:(NSString *)tripID completion:(void (^)(TKTrip *_Nullable, NSError *_Nullable))completion
{
	[[[TKAPIRequest alloc] initAsTripRequestForTripWithID:tripID success:^(TKTrip *trip) {

		if (completion) completion(trip, nil);

	} failure:^(TKAPIError *__unused error) {

		if (completion) completion(nil, error);

	}] start];
}

- (void)emptyTrashWithCompletion:(void (^)(NSArray<NSString *> *_Nullable, NSError *_Nullable))completion
{
	[[[TKAPIRequest alloc] initAsEmptyTrashRequestWithSuccess:^(NSArray<NSString *> *tripIDs) {

		[self deleteTripsWithIDs:tripIDs];

		if (completion) completion(tripIDs, nil);

	} failure:^(TKAPIError *error) {

		if (completion) completion(nil, error);

	}] start];
}

@end
