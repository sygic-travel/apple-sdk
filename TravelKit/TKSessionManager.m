//
//  TKSessionManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 29/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKSessionManager+Private.h"
#import "TKDatabaseManager+Private.h"

#import "Foundation+TravelKit.h"
#import "NSObject+Parsing.h"


@interface TKSessionManager ()

@property (nonatomic, strong) TKDatabaseManager *database;

@end


@implementation TKSessionManager

+ (TKSessionManager *)sharedSession
{
    static dispatch_once_t once = 0;
    static TKSessionManager *shared = nil;
    dispatch_once(&once, ^{ shared = [[self alloc] init]; });
    return shared;
}

- (instancetype)init
{
	if (self = [super init])
	{
		_database = [TKDatabaseManager sharedInstance];
	}

	return self;
}


#pragma mark -
#pragma mark Generic methods


- (void)clearUserData
{
	// Clear Favorites
	[_database runQuery:@"DELETE * FROM %@;" tableName:kDatabaseTableFavorites];
}


#pragma mark -
#pragma mark Favorites


- (NSArray<NSString *> *)favoritePlaceIDs
{
	NSArray *results = [_database runQuery:
		@"SELECT id FROM %@;" tableName:kDatabaseTableFavorites];

	return [results mappedArrayUsingBlock:^NSString *(NSDictionary *res, NSUInteger __unused idx) {
		return [res[@"id"] parsedString];
	}];
}

- (void)updateFavoritePlaceID:(NSString *)favoriteID setFavorite:(BOOL)favorite
{
	if (!favoriteID) return;

	if (favorite)
		[_database runQuery:@"INSERT OR IGNORE INTO %@ VALUES (?);"
			tableName:kDatabaseTableFavorites data:@[ favoriteID ]];
	else
		[_database runQuery:@"DELETE FROM %@ WHERE id = ?;"
			tableName:kDatabaseTableFavorites data:@[ favoriteID ]];
}

@end
