//
//  TKDirection.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/01/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <TravelKit/TKDirection.h>

NS_ASSUME_NONNULL_BEGIN


@interface TKDirectionsSet (Private)

- (nullable instancetype)initFromDictionary:(NSDictionary *)dictionary;

@end


@interface TKDirection (Private)

- (nullable instancetype)initFromDictionary:(NSDictionary *)dictionary;

@end


@interface TKDirectionStep (Private)

- (nullable instancetype)initFromDictionary:(NSDictionary *)dictionary;

@end


@interface TKDirectionIntermediateStop (Private)

- (nullable instancetype)initFromDictionary:(NSDictionary *)dictionary;

@end


NS_ASSUME_NONNULL_END
