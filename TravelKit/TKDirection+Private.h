//
//  TKDirection.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/01/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <TravelKit/TKDirection.h>

NS_ASSUME_NONNULL_BEGIN


@interface TKDirectionsSet ()

- (nullable instancetype)initFromDictionary:(NSDictionary *)dictionary;

@end


@interface TKDirection ()

@property (nonatomic, copy, nullable) NSString *routeID;

- (nullable instancetype)initFromDictionary:(NSDictionary *)dictionary;

@end


@interface TKDirectionStep ()

@property (nonatomic, copy, nullable) NSString *displayMode;

- (nullable instancetype)initFromDictionary:(NSDictionary *)dictionary;

@end


@interface TKDirectionIntermediateStop ()

- (nullable instancetype)initFromDictionary:(NSDictionary *)dictionary;

@end


NS_ASSUME_NONNULL_END
