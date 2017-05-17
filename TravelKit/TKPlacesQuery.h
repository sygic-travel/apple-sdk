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
 Query enum declaring in which manner the related parameter should be treated.
 */
typedef NS_ENUM(NSUInteger, TKPlacesQueryMatching) {
	/// Matching rule stating **ANY** of the queried criteria needs to be met.
	TKPlacesQueryMatchingAny  = 0,
	/// Matching rule stating **ALL** of the queried criteria need to be met.
	TKPlacesQueryMatchingAll = 1,
};

/**
 Query object used for fetching specific collections of `TKPlace` objects.
 
 To perform regional queries, use either `quadKeys` (preferred) or `bounds` property to specify the area of your interest.
 */
@interface TKPlacesQuery : NSObject <NSCopying>

/// Search term to use. Usable for searching through English and localised names.
@property (nonatomic, copy, nullable) NSString *searchTerm;

/// Desired levels of Places.
///
/// @note Matches objects in **ANY** of the reqested levels.
///
/// @see `TKPlaceLevel`
@property (atomic) TKPlaceLevel levels;

/// Listed map quad keys to query.
///
/// @note Length: `1`--`18`. All requested quad keys should be of the same length.
@property (nonatomic, copy, nullable) NSArray<NSString *> *quadKeys;

/// Desired area of the map.
@property (nonatomic, strong, nullable) TKMapRegion *bounds;

/// Division of each map tile when spreading.
///
/// @note Accepted values: `0`--`3`. Implicit value is `0`.
///
/// @warning Value of `limit` must be divisible by `4^mapSpread`.
@property (nonatomic, strong, nullable) NSNumber *mapSpread;

/// Array of the desired Category slugs.
///
/// @note Matches Places having **ALL** of the requested categories.
///       Switching to **ANY** is possible by using the `-categoriesMatching` property.
///
/// @see `TKPlace`
/// @see `categoriesMatching`
@property (nonatomic, copy, nullable) NSArray<NSString *> *categories;

/// Flag controlling the matching rule for `categories`.
@property (atomic) TKPlacesQueryMatching categoriesMatching;

/// Plain-text array of the desired Tag keys.
///
/// @note Matches Places having **ALL** of the reqested tags.
///       Switching to **ANY** is possible by using the `-tagsMatching` property.
///
/// @see `tagsMatching`
@property (nonatomic, copy, nullable) NSArray<NSString *> *tags;

/// Flag controlling the matching rule for `tags`.
@property (atomic) TKPlacesQueryMatching tagsMatching;

/// Desired identifiers of parent nodes.
///
/// @note Matches Places having **ALL** of the reqested parents.
///       Switching to **ANY** is possible by using the `-parentIDsMatching` property.
///
/// @see `parentIDsMatching`
@property (nonatomic, copy, nullable) NSArray<NSString *> *parentIDs;

/// Flag controlling the matching rule for `parentIDs`.
@property (atomic) TKPlacesQueryMatching parentIDsMatching;

/// Maximum number of results returned.
///
/// @note Accepted values: `0`--`512`.
///
/// @note If multiple quad keys specified, the limit applies to each map tile separately.
///
/// @warning The value requested must be divisible by `4^mapSpread`.
@property (nonatomic, strong, nullable) NSNumber *limit;

@end

NS_ASSUME_NONNULL_END
