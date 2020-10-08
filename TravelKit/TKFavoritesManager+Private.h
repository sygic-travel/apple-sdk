//
//  TKFavoritesManager+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 08/02/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <TravelKit/TKFavoritesManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKFavoritesManager ()

// Private methods
- (NSDictionary<NSString *, NSNumber *> *)favoritePlaceIDsToSynchronize;
- (void)storeServerFavoriteIDsAdded:(NSArray<NSString *> *)addedIDs removed:(NSArray<NSString *> *)removedIDs;

@end

NS_ASSUME_NONNULL_END
