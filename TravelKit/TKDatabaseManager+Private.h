//
//  TKDatabaseManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 9/7/2014.
//  Copyright (c) 2014 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Exported table names
//extern NSString * const kTKDatabaseTablePlaces;
//extern NSString * const kTKDatabaseTablePlaceDetails;
//extern NSString * const kTKDatabaseTablePlaceParents;
//extern NSString * const kTKDatabaseTableMedia;
//extern NSString * const kTKDatabaseTableReferences;
extern NSString * const kTKDatabaseTableFavorites;
extern NSString * const kTKDatabaseTableTrips;
extern NSString * const kTKDatabaseTableTripDays;
extern NSString * const kTKDatabaseTableTripDayItems;


@interface TKDatabaseManager : NSObject

/// Shared instance
@property (class, readonly, strong) TKDatabaseManager *sharedManager;

/// Default path of the database file
+ (NSString *)databasePath;

/// Disqualified initializer
+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/// Check consistency, run proper migrations etc.
- (void)checkConsistency;

/// Check indexes presence
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
