//
//  TKPlacesQuery.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <TravelKit/TKPlace.h>
#import <TravelKit/TKMapRegion.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Query enum declaring in which manner the related parameter should be treated.
 */
typedef NS_ENUM(NSUInteger, TKPlacesQueryMatching) {
	/// Matching rule stating **ANY** of the queried criteria needs to be met.
	TKPlacesQueryMatchingAny  = 0,
	/// Matching rule stating **ALL** of the queried criteria need to be met.
	TKPlacesQueryMatchingAll  = 1,
};

/**
 A query object used for fetching specific collections of `TKPlace` objects.
 
 To perform regional queries, use either `quadKeys` (preferred) or `bounds` property to specify the area of your interest.
 */
@interface TKPlacesQuery : NSObject <NSCopying, NSMutableCopying>

/// Search term to use. Usable for searching through English and localised names.
@property (nonatomic, copy, nullable) NSString *searchTerm;

/// Desired location to look around.
@property (nonatomic, strong) CLLocation *preferredLocation;

/// Desired levels of Places. Each place has a level property that describes the type of the place by administration
/// level. You can see supported levels in TKPlaceLevel enum.
///
/// @note Matches objects in **ANY** of the requested levels.
///
/// @see `TKPlaceLevel`
@property (atomic) TKPlaceLevel levels;

/// Listed map quad keys to query. Quad key represents map tile coordinate using Mercator (Google/Bing)
/// projection. For details see [Bing Maps](https://msdn.microsoft.com/en-us/library/bb259689.aspx) docs or
/// [maptiler.org](www.maptiler.org/google-maps-coordinates-tile-bounds-projection/) .
///
/// @note Length: `1`--`18`. All requested quad keys should be of the same length.
@property (nonatomic, copy, nullable) NSArray<NSString *> *quadKeys;

/// Desired area of the map, specified by south-west and north-east point in degrees.
@property (nonatomic, strong, nullable) TKMapRegion *bounds;

/// Division of each map tile when spreading.
/// Use mapSpread when you want to display the places on the map. The area is subdivided into more areas so places cover map equally.
///
/// @note Accepted values: `0`--`3`. Implicit value is `0`.
///
/// @warning Value of `limit` must be divisible by `4^mapSpread`.
@property (nonatomic, strong, nullable) NSNumber *mapSpread;

/// Array of the desired Category slugs.
///
/// @note Matches Places having **ALL** of the requested categories.
///       Switching to **ANY** is possible by using the `categoriesMatching` property.
///
/// @see `TKPlaceCategory`
/// @see `categoriesMatching`
@property (atomic) TKPlaceCategory categories;

/// Flag controlling the matching rule for `categories`.
@property (atomic) TKPlacesQueryMatching categoriesMatching;

/// Plain-text array of the desired Tag keys. Each place can have multiple tags which describe it or it’s properties.
/// Tags are used in query to filter places.
///
/// @note Matches Places having **ALL** of the requested tags.
///       Switching to **ANY** is possible by using the `tagsMatching` property.
///       See the [list of available tags](docs.sygictravelapi.com/taglist.html) .
///
/// @see `tagsMatching`
@property (nonatomic, copy, nullable) NSArray<NSString *> *tags;

/// Flag controlling the matching rule for `tags`.
@property (atomic) TKPlacesQueryMatching tagsMatching;

/// Desired identifiers of parent nodes.
///
/// @note Matches Places having **ALL** of the requested parents.
///       Switching to **ANY** is possible by using the `parentIDsMatching` property.
///
/// @see `parentIDsMatching`
@property (nonatomic, copy, nullable) NSArray<NSString *> *parentIDs;

/// Flag controlling the matching rule for `parentIDs`.
@property (atomic) TKPlacesQueryMatching parentIDsMatching;

/// Minimum rating of the queried Places.
///
/// @note The minimum value is `0`.
@property (nonatomic, strong, nullable) NSNumber *minimumRating;

/// Maximum rating of the queried Places.
///
/// @note The maximum value is `10`.
@property (nonatomic, strong, nullable) NSNumber *maximumRating;

/// Maximum number of results returned.
///
/// @note The default value is `10`. Accepted values: `0`--`512`.
///
/// @note If multiple quad keys specified, the limit applies to each map tile separately.
///
/// @warning The value requested must be divisible by `4^mapSpread`.
@property (nonatomic, strong, nullable) NSNumber *limit;

/// Offset index of the place to start with. Practically usable as paging.
///
/// @note The default value is `0`. Accepted values: `0`--`10000`.
///
/// @note Setting a limit of `512` and offset `512` effectively returns
///       the second page of results.
@property (nonatomic, strong, nullable) NSNumber *offset;

@end

NS_ASSUME_NONNULL_END
