//
//  TKFavoritesManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 08/02/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import "TKFavoritesManager.h"
#import "TKDatabaseManager+Private.h"
#import "Foundation+TravelKit.h"
#import "NSObject+Parsing.h"

@interface TKFavoritesManager ()

@property (nonatomic, strong) TKDatabaseManager *database;

@end


@implementation TKFavoritesManager


#pragma mark -
#pragma mark Initialization


+ (TKFavoritesManager *)sharedManager
{
	static TKFavoritesManager *shared = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[self alloc] init];
	});

	return shared;
}

- (instancetype)init
{
	if (self = [super init])
	{
		_database = [TKDatabaseManager sharedManager];
	}

	return self;
}
#pragma mark -
#pragma mark Favorites


- (NSArray<NSString *> *)favoritePlaceIDs
{
	NSArray *results = [_database runQuery:
		@"SELECT id FROM %@ WHERE state >= 0;" tableName:kTKDatabaseTableFavorites];

	return [results mappedArrayUsingBlock:^NSString *(NSDictionary *res) {
		return [res[@"id"] parsedString];
	}];
}

- (void)updateFavoritePlaceID:(NSString *)favoriteID setFavorite:(BOOL)favorite
{
	if (!favoriteID) return;

	if (favorite)
		[_database runQuery:@"INSERT OR REPLACE INTO %@ VALUES (?, 1);"
			tableName:kTKDatabaseTableFavorites data:@[ favoriteID ]];
	else
		[_database runQuery:@"UPDATE %@ SET state = -1 WHERE id = ?;"
			tableName:kTKDatabaseTableFavorites data:@[ favoriteID ]];
}

- (NSDictionary<NSString *,NSNumber *> *)favoritePlaceIDsToSynchronize
{
	NSArray<NSDictionary *> *results = [_database runQuery:
		@"SELECT * FROM %@ WHERE state != 0;" tableName:kTKDatabaseTableFavorites];

	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:results.count];

	for (NSDictionary *f in results)
	{
		NSString *ID = [f[@"id"] parsedString];
		NSNumber *state = [f[@"state"] parsedNumber];

		if (!ID || ABS(state.integerValue) != 1) continue;

		dict[ID] = state;
	}

	return dict;
}

- (void)storeServerFavoriteIDsAdded:(NSArray<NSString *> *)addedIDs removed:(NSArray<NSString *> *)removedIDs
{
	NSString *(^joinIDs)(NSArray<NSString *> *) = ^NSString *(NSArray<NSString *> *arr) {
		if (!arr.count) return nil;
		return [NSString stringWithFormat:@"'%@'", [arr componentsJoinedByString:@"','"]];
	};

	NSString *addString = joinIDs(addedIDs);
	NSString *remString = joinIDs(removedIDs);

	if (addString) [_database runQuery:[NSString stringWithFormat:
		@"UPDATE %@ SET state = 0 WHERE id IN (%@);", kTKDatabaseTableFavorites, addString]];

	for (NSString *ID in addedIDs)
		[_database runQuery:@"INSERT OR IGNORE INTO %@ (id) VALUES (?);"
			tableName:kTKDatabaseTableFavorites data:@[ ID ]];

	if (remString) [_database runQuery:[NSString stringWithFormat:
		@"DELETE FROM %@ WHERE id IN (%@);", kTKDatabaseTableFavorites, remString]];
}

@end
