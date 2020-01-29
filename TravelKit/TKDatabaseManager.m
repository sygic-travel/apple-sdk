//
//  TKDatabaseManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 9/7/2014.
//  Copyright (c) 2014 Tripomatic. All rights reserved.
//

#import "TKEnvironment+Private.h"
#import "TKDatabaseManager+Private.h"

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabaseQueue.h"

#import "NSObject+Parsing.h"

#define NSStringMultiline(...) @#__VA_ARGS__


// Database scheme
NSUInteger const kDatabaseSchemeVersionLatest = 20171026;

// Table names // ABI-EXPORTED
//NSString * const kTKDatabaseTablePlaces = @"places";
//NSString * const kTKDatabaseTablePlaceDetails = @"place_details";
//NSString * const kTKDatabaseTablePlaceParents = @"place_parents";
//NSString * const kTKDatabaseTableMedia = @"media";
//NSString * const kTKDatabaseTableReferences = @"references";
NSString * const kTKDatabaseTableFavorites = @"favorites";
NSString * const kTKDatabaseTableTrips = @"trips";
NSString * const kTKDatabaseTableTripDays = @"trip_days";
NSString * const kTKDatabaseTableTripDayItems = @"trip_day_items";


#pragma mark Private category


@interface TKDatabaseManager ()

@property (nonatomic) NSUInteger databaseVersion;

@property (atomic) BOOL databaseCreatedRecently;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

@end


#pragma mark -
#pragma mark Implementation


@implementation TKDatabaseManager

+ (TKDatabaseManager *)sharedManager
{
    static dispatch_once_t once = 0;
    static TKDatabaseManager *shared = nil;
    dispatch_once(&once, ^{ shared = [[self alloc] init]; });
    return shared;
}

+ (NSString *)databasePath
{
	return [TKEnvironment sharedEnvironment].databasePath;
}

- (instancetype)init
{
	if (self = [super init])
	{
		if (![self isMemberOfClass:[TKDatabaseManager class]])
			@throw @"TKDatabaseManager class cannot be inherited";

		[self initializeDatabase];
	}

	return self;
}

- (void)initializeDatabase
{
	@synchronized (self) {

		if (!_databaseQueue) {

			NSFileManager *fm = [NSFileManager defaultManager];

			// Prepare paths
			NSString *databasePath = [TKDatabaseManager databasePath];
			NSString *databaseDir = [databasePath stringByDeletingLastPathComponent];

			// Check for DB existance
			BOOL exists = [fm fileExistsAtPath:databasePath];

			if (!exists && ![fm fileExistsAtPath:databaseDir isDirectory:nil])
				if (![fm createDirectoryAtPath:databaseDir withIntermediateDirectories:YES attributes:nil error:nil])
					@throw @"Database initialization error";

			if (!exists) [fm createFileAtPath:databasePath contents:nil attributes:nil];

			// Initialize DB accessor on the file
			_databaseQueue = [FMDatabaseQueue databaseQueueWithPath:databasePath];

			// Try to handle some basic error cases
			if (!_databaseQueue && exists)
			{
				[fm removeItemAtPath:databasePath error:nil];
				_databaseQueue = [FMDatabaseQueue databaseQueueWithPath:databasePath];
			}

			// Throw on error
			if (!_databaseQueue) @throw @"Database initialization error";

			// Check consistency
			[self checkConsistency];
		}
	}
}


#pragma mark -
#pragma mark Version checking


- (NSUInteger)databaseVersion
{
	return [[[[self runQuery:@"PRAGMA user_version;"] lastObject]
		[@"user_version"] parsedNumber] unsignedIntegerValue];
}

- (void)setDatabaseVersion:(NSUInteger)databaseVersion
{
	NSString *userVersionQuery = [NSString stringWithFormat:
		@"PRAGMA user_version = %tu;", databaseVersion];
	[self runQuery:userVersionQuery tableName:nil data:nil];
}


#pragma mark -
#pragma mark Migrations


- (void)checkConsistency
{
	//////////////////////////////////
	// Set journal mode

	[self runQuery:@"PRAGMA journal_mode = 'TRUNCATE';" tableName:nil data:nil];

	//////////////////////////////////
	// Check Database scheme

	[self checkScheme];

	//////////////////////////////////
	// Check Database indexes

	[self checkIndexes];
}

- (void)checkIndexes
{
	// Drop obsolete redundant indexes
//	[self runUpdate:@"DROP INDEX IF EXISTS ...;"];

	// Create smart indexes as required
//	[self runUpdate:@"CREATE INDEX IF NOT EXISTS index_name ON %@ (quadkey ASC);"
//		  tableName:... data:nil];

//		NSString *sql = NSStringMultiline(
//
//CREATE INDEX IF NOT EXISTS medium_type ON "medium" ("type" ASC);
//
//CREATE INDEX IF NOT EXISTS medium_place_id ON "medium" ("place_id" ASC);
//
//CREATE INDEX IF NOT EXISTS place_rating ON "place" ("rating" DESC);
//
//CREATE INDEX IF NOT EXISTS place_quadkey ON "place" ("quadkey" ASC);
//
//CREATE INDEX IF NOT EXISTS place_categories ON "place" ("categories" ASC);
//
//CREATE INDEX IF NOT EXISTS place_parents_parent_id ON "place_parents" ("parent_id" ASC);
//
//CREATE INDEX IF NOT EXISTS place_parents_place_id ON "place_parents" ("place_id" ASC);
//
//CREATE INDEX IF NOT EXISTS reference_place_id ON "reference" ("place_id" ASC);
//
//		);
//
//		for (NSString *query in [sql componentsSeparatedByString:@";"])
//			if (query.length > 5)
//				[self runUpdate:query];
}

- (void)checkScheme
{
	//////////////////////////////////
	// Read current Database scheme & determine state

	NSUInteger currentScheme = [self databaseVersion];

	//////////////////////////////////
	// Check Database scheme version

	if (currentScheme == kDatabaseSchemeVersionLatest)
		return;

#ifdef DEBUG
	NSLog(@"[DATABASE] Updating Database scheme");
#endif

	//////////////
	// Perform migration rules

	// Favorites
	if (currentScheme < 20170621) {
		[self runUpdate:@"CREATE TABLE IF NOT EXISTS %@ "
			"(id text PRIMARY KEY NOT NULL);" tableName:kTKDatabaseTableFavorites];
	}

	// Favorites on server
	if (currentScheme < 20171024) {
		[self runUpdate:@"ALTER TABLE %@ ADD state INTEGER "
			"NOT NULL DEFAULT 0;" tableName:kTKDatabaseTableFavorites];
	}

	// New Trips API -- new structure + migration
	if (currentScheme < 20171026) {

		[self runUpdate:@"CREATE TABLE IF NOT EXISTS %@ (id text PRIMARY KEY UNIQUE NOT NULL, "
		 "name text, version integer, days integer, destination_ids text, owner_id text, starts_on text, "
		 "updated_at text, changed integer, deleted integer, privacy integer, rights integer);"
			  tableName:kTKDatabaseTableTrips];

		[self runUpdate:@"CREATE TABLE IF NOT EXISTS %@ (trip_id text NOT NULL, "
		 "day_index integer NOT NULL, note text, PRIMARY KEY(trip_id, day_index));"
			  tableName:kTKDatabaseTableTripDays];

		[self runUpdate:@"CREATE TABLE IF NOT EXISTS %@ ("
		 "trip_id text NOT NULL, day_index integer NOT NULL, item_index integer NOT NULL, "
		 "item_id text NOT NULL, start_time integer, duration integer, note text, "
		 "transport_mode integer, transport_type integer, transport_avoid integer, "
		 "transport_start_time integer, transport_duration integer, transport_note text, "
		 "transport_polyline text, PRIMARY KEY(trip_id, day_index, item_index));"
             tableName:kTKDatabaseTableTripDayItems];
	}

	// Missing Route ID attribute
	if (currentScheme < 20181024) {
		[self runUpdate:@"ALTER TABLE %@ ADD transport_route_id text;"
			tableName:kTKDatabaseTableTripDayItems];
	}

	//////////////
	// Update version pragma

	self.databaseVersion = kDatabaseSchemeVersionLatest;
}


#pragma mark -
#pragma mark Database methods


- (NSArray *)runQuery:(NSString *const)query
{
	return [self runQuery:query tableName:nil data:nil];
}

- (NSArray *)runQuery:(NSString *const)query tableName:(NSString *const)tableName
{
	return [self runQuery:query tableName:tableName data:nil];
}

- (NSArray *)runQuery:(NSString *const)query tableName:(NSString *const)tableName data:(NSArray *const)data
{
	// Fill in a table name
	NSString *workingQuery = [NSString stringWithFormat:query, tableName];

#ifdef LOG_SQL
	NSLog(@"[SQL] Query: '%@'  Data: %@", workingQuery, data);
#endif

	__block NSMutableArray *results = [NSMutableArray array];
	__block NSError *error = nil;

	[_databaseQueue inDatabase:^(FMDatabase *database){

		@autoreleasepool {

			FMResultSet *resultSet = [database executeQuery:workingQuery withArgumentsInArray:data];

			if ([database hadError]) {
				error = database.lastError;
				NSLog(@"[DATABASE] Error when executing query %@: %@", workingQuery, error);
				return;
			}

			NSDictionary *dict = nil;
			while ([resultSet next])
				[results addObject:(dict = resultSet.resultDictionary)];

			[resultSet close];
			resultSet = nil;

		}

	}];

	return results;
}

- (BOOL)runUpdate:(NSString *const)query
{
	return [self runUpdate:query tableName:nil data:nil];
}

- (BOOL)runUpdate:(NSString *const)query tableName:(NSString *const)tableName
{
	return [self runUpdate:query tableName:tableName data:nil];
}

- (BOOL)runUpdate:(NSString *const)query tableName:(NSString *const)tableName data:(NSArray *const)data
{

	// Fill in a table name
	NSString *workingQuery = [NSString stringWithFormat:query, tableName];

#ifdef LOG_SQL
	NSLog(@"[SQL] %@ with %@", workingQuery, data);
#endif

	__block BOOL isUpdateOk = YES;
	__block NSError *error = nil;
	__block int changes = 0;

	[_databaseQueue inDatabase:^(FMDatabase *database){

		isUpdateOk = [database executeUpdate:workingQuery withArgumentsInArray:data];
		if ([database hadError]) error = database.lastError;
		changes = database.changes;

	}];

	if (error) @throw @"Database update error";

	return isUpdateOk;
}

- (BOOL)runUpdateTransactionWithQueries:(NSArray *const)queries dataArray:(NSArray *const)dataArray
{
	__block BOOL isUpdateOk = YES;
	__block NSError *error = nil;

	[_databaseQueue inTransaction:^(FMDatabase *database, BOOL *rollback){

		NSUInteger index = 0;

		for (NSString *query in queries)
		{
			if (index >= dataArray.count)
				continue;

			NSArray *data = dataArray[index];

			isUpdateOk = [database executeUpdate:query withArgumentsInArray:data];

			if ([database hadError]) {
				error = database.lastError;
				NSLog(@"[DATABASE] Error when updating DB with query %@: %@", query, error);
				*rollback = YES;
				break;
			}

			index++;
		}

	}];

	return isUpdateOk;
}

- (BOOL)checkExistenceOfColumn:(NSString *)columnName inTable:(NSString *)tableName
{
	__block BOOL exists = NO;

	[_databaseQueue inDatabase:^(FMDatabase *database){
		exists = [database columnExists:columnName inTableWithName:tableName];
	}];

	return exists;
}

@end
