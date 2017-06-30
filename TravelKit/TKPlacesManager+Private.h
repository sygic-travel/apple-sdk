//
//  TKPlacesManager+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 23/05/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TravelKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKPlacesManager : NSObject

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)sharedManager;

#pragma mark - Generic queries

- (void)placesForQuery:(TKPlacesQuery *)query
	completion:(void (^)(NSArray<TKPlace *>  * _Nullable places, NSError * _Nullable error))completion;

- (void)placesWithIDs:(NSArray<NSString *> *)placeIDs
	completion:(void (^)(NSArray<TKPlace *> *, NSError *))completion;

- (void)detailedPlaceWithID:(NSString *)placeID
	completion:(void (^)(TKPlace * _Nullable place, NSError * _Nullable error))completion;

- (void)mediaForPlaceWithID:(NSString *)placeID
	completion:(void (^)(NSArray<TKMedium *> * _Nullable media, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
