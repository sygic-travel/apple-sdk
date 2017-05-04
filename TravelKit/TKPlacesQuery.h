//
//  TKPlacesQuery.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TKPlace.h"
#import "TKMapRegion.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Query object used for fetching specific collections of `TKPlace` objects.
 
 To perform regional queries, use either `quadKeys` (preferred) or `bounds` property to specify the area of your interest.
 */
@interface TKPlacesQuery : NSObject <NSCopying>

/// Search term to use. Mainly usable for searching through English and localised names.
@property (nonatomic, copy, nullable) NSString *searchTerm;

/// Desired levels of `TKPlace` objects. Matches `TKPlace` objects in _ANY_ of the reqested levels.
///
/// @see `TKPlaceLevel`
@property (atomic) TKPlaceLevel levels;

/// Listed map quad keys to query.
///
/// @note Length `1`--`18`. All requested quad keys should be of the same length.
@property (nonatomic, copy, nullable) NSArray<NSString *> *quadKeys;

/// Desired area of the map.
@property (nonatomic, strong, nullable) TKMapRegion *bounds;

/// Division of each map tile when spreading.
///
/// @note Accepted values: `0`--`3`. Implicit value is `0`.
///
/// @warning Value of `limit` must be divisible by `4^mapSpread`.
@property (nonatomic, strong, nullable) NSNumber *mapSpread;

/// Array of the desired Category slugs. Matches `TKPlace` objects having _ALL_ of the requested categories.
///
/// @see `TKPlace`
@property (nonatomic, copy, nullable) NSArray<NSString *> *categories;

/// Plain-text array of the desired Tag keys. Matches `TKPlace` objects having _ALL_ of the reqested tags.
@property (nonatomic, copy, nullable) NSArray<NSString *> *tags;

/// Idenfitier of the parent node of returned `TKPlace` objects.
@property (nonatomic, copy, nullable) NSString *parentID;

/// Maximum number of results returned. If multiple quad keys specified, the limit applies to each one of them separately.
///
/// @warning The value requested must be divisible by `4^mapSpread`.
@property (nonatomic, strong, nullable) NSNumber *limit;

@end

NS_ASSUME_NONNULL_END
