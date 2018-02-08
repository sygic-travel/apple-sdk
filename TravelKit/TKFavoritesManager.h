//
//  TKFavoritesManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 08/02/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///---------------------------------------------------------------------------------------
/// @name Favorites Manager
///---------------------------------------------------------------------------------------

/**
 A working manager used to work with Favorites.
 */
@interface TKFavoritesManager : NSObject

///---------------------------------------------------------------------------------------
/// @name Shared interface
///---------------------------------------------------------------------------------------

/// Shared Favorites managing instance.
@property (class, readonly, strong) TKFavoritesManager *sharedManager;

+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

///---------------------------------------------------------------------------------------
/// @name Favorites working queries
///---------------------------------------------------------------------------------------

/**
 Fetches an array of IDs of Places previously marked as favorite.

 @return Array of Place IDs.
 */
- (NSArray<NSString *> *)favoritePlaceIDs;

/**
 Updates a favorite state for a specific Place ID.

 @param favoriteID Place ID to update.
 @param favorite Desired Favorite state, either `YES` or `NO`.
 */
- (void)updateFavoritePlaceID:(NSString *)favoriteID setFavorite:(BOOL)favorite;

@end

NS_ASSUME_NONNULL_END
