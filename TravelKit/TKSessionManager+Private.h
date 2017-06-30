//
//  TKSessionManager+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 29/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TKSessionManager : NSObject

/**
 * Shared instance
 *
 * @return singleton instance of this class
 */
+ (TKSessionManager *)sharedSession;

/** Disqualified initializer */
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;

#pragma mark - Generic methods

- (void)clearUserData;

#pragma mark - Favourites

- (NSArray<NSString *> *)favouritePlaceIDs;

- (void)updateFavouritePlaceID:(NSString *)favouriteID setFavourite:(BOOL)favourite;

@end
