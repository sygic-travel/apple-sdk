//
//  TKDatabaseManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 9/7/2014.
//  Copyright (c) 2014 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

// Exported table names
extern NSString * const kDatabaseTablePlace;
extern NSString * const kDatabaseTablePlaceDetail;
extern NSString * const kDatabaseTablePlaceParents;
extern NSString * const kDatabaseTableMedium;
extern NSString * const kDatabaseTableReference;
extern NSString * const kDatabaseTableFavourite;


@interface TKDatabaseManager : NSObject

/**
 * Shared instance
 *
 * @return singleton instance of this class
 */
+ (TKDatabaseManager *)sharedInstance;

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
