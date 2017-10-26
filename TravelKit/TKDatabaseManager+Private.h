//
//  TKDatabaseManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 9/7/2014.
//  Copyright (c) 2014 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

// Exported table names
extern NSString * const kDatabaseTablePlaces;
extern NSString * const kDatabaseTablePlaceDetails;
extern NSString * const kDatabaseTablePlaceParents;
extern NSString * const kDatabaseTableMedia;
extern NSString * const kDatabaseTableReferences;
extern NSString * const kDatabaseTableFavorites;
extern NSString * const kDatabaseTableTrips;
extern NSString * const kDatabaseTableTripDays;
extern NSString * const kDatabaseTableTripDayItems;


@interface TKDatabaseManager : NSObject

/** Shared instance */
@property (class, readonly, strong) TKDatabaseManager *sharedManager;

/** Default path of the database file */
+ (NSString *)databasePath;

/** Disqualified initializer */
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;

/** Check consistency, run proper migrations etc. */
- (void)checkConsistency;

/** Check indexes presence. */
- (void)checkIndexes;

// SELECT queries
- (NSArray *)runQuery:(NSString *const)query;
- (NSArray *)runQuery:(NSString *const)query tableName:(NSString *const)tableName;
- (NSArray *)runQuery:(NSString *const)query tableName:(NSString *const)tableName data:(NSArray *const)data;

// INSERT/UPDATE/... queries
- (BOOL)runUpdate:(NSString *const)query;
- (BOOL)runUpdate:(NSString *const)query tableName:(NSString *const)tableName;
- (BOOL)runUpdate:(NSString *const)query tableName:(NSString *const)tableName data:(NSArray *const)data;
- (BOOL)runUpdateTransactionWithQueries:(NSArray *const)queries dataArray:(NSArray *const)dataArray;

@end
