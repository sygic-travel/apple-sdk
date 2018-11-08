//
//  TKPlace+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <TravelKit/TKPlace.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKPlace ()

/// Dictionary with @(TKPlaceLevel) key and NSString* values
+ (NSDictionary<NSNumber *, NSString *> *)levelStrings;

/// Dictionary with @(TKPlaceCategory) key and NSString* values
+ (NSDictionary<NSNumber *, NSString *> *)categorySlugs;

/// TKPlace resolver from NSString*
+ (TKPlaceLevel)levelFromString:(NSString *)str;

/// Initialiser
- (nullable instancetype)initFromResponse:(NSDictionary *)response;

@end


@interface TKDetailedPlace ()

/// Initialiser
- (nullable instancetype)initFromResponse:(NSDictionary *)response;

@end


@interface TKPlaceDetail ()

/// Initialiser
- (nullable instancetype)initFromResponse:(NSDictionary *)response;

@end


@interface TKPlaceTag ()

/// Initialiser
- (nullable instancetype)initFromResponse:(NSDictionary *)response;

@end

NS_ASSUME_NONNULL_END
