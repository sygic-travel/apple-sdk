//
//  TKPlace.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "TKMapRegion.h"
#import "TKReference.h"
#import "TKMedium.h"

/**
 Flag value denoting level value of a `TKPlace`.
 */
typedef NS_OPTIONS(NSUInteger, TKPlaceLevel) {
	/// Unknown level. _Fallback value_
	TKPlaceLevelUnknown           = 0,
	/// Point of interest. _Examples: Eiffel Tower, Big Ben, Golden Gate bridge_
	TKPlaceLevelPOI               = 1 << 0,
	/// Neighbourhood.
	TKPlaceLevelNeighbourhood     = 1 << 1,
	/// Locality.
	TKPlaceLevelLocality          = 1 << 2,
	/// Settlement.
	TKPlaceLevelSettlement        = 1 << 3,
	/// Village.
	TKPlaceLevelVillage           = 1 << 4,
	/// Town. Smaller than city, bigger than village. _Examples: Camden Town in London_
	TKPlaceLevelTown              = 1 << 5,
	/// City. _Example: London, New York, Paris_
	TKPlaceLevelCity              = 1 << 6,
	/// County. _Example: Orange County_
	TKPlaceLevelCounty            = 1 << 7,
	/// Region. _Example: Champagne_
	TKPlaceLevelRegion            = 1 << 8,
	/// Island.
	TKPlaceLevelIsland            = 1 << 9,
	/// Archipelago.
	TKPlaceLevelArchipelago       = 1 << 10,
	/// State. _Example: California_
	TKPlaceLevelState             = 1 << 11,
	/// Country. _Example: France_
	TKPlaceLevelCountry           = 1 << 12,
	/// Continent. _Example: Europe_
	TKPlaceLevelContinent         = 1 << 13,
};

NS_ASSUME_NONNULL_BEGIN

@class TKPlaceTag, TKPlaceDetail;


/**
 Basic Place model keeping various information about its properties.
 */

@interface TKPlace : NSObject

///---------------------------------------------------------------------------------------
/// @name Hard properties
///---------------------------------------------------------------------------------------

/// Global identifier.
@property (nonatomic, copy) NSString *ID NS_SWIFT_NAME(ID);

/// Displayable name of the place, translated if possible. Example: _Buckingham Palace_.
@property (nonatomic, copy) NSString *name;

/// Displayable name suffix. Example: _London, United Kingdom_.
@property (nonatomic, copy, nullable) NSString *suffix;

/// Denotable place level.
@property (atomic) TKPlaceLevel level;

/// Short perex introducing the place.
@property (nonatomic, copy, nullable) NSString *perex;

/// Location of the place.
@property (nonatomic, strong) CLLocation *location;

/// 18-character Quad key.
@property (nonatomic, copy, nullable) NSString *quadKey;

/// Bounding box.
@property (nonatomic, strong, nullable) TKMapRegion *boundingBox;

/// Price value. Value in `USD`.
@property (nonatomic, strong, nullable) NSNumber *price;

/// Global rating value.
///
/// @note Possible values: double in range `0`--`10.0`.
@property (nonatomic, strong, nullable) NSNumber *rating;

/// Marker identifier usable for displayable icon.
@property (nonatomic, copy, nullable) NSString *marker;

/// List of Category slugs assigned.
///
/// @note Possible values:
///       - **`sightseeing`**
///       - **`shopping`**
///       - **`eating`**
///       - **`discovering`**
///       - **`playing`**
///       - **`traveling`**
///       - **`going_out`**
///       - **`hiking`**
///       - **`sports`**
///       - **`relaxing`**
///       - **`sleeping`**
///
/// @note All supported keys may be obtained by calling `+supportedCategories`.
@property (nonatomic, copy, nullable) NSArray<NSString *> *categories;

/// List of Parent IDs.
@property (nonatomic, copy, nullable) NSArray<NSString *> *parents;

/// List of custom flags.
@property (nonatomic, copy, nullable) NSArray<NSString *> *flags;

/// Thumbnail URL to an image of size 150×150 pixels.
@property (nonatomic, strong, nullable) NSURL *thumbnailURL;

/// Place detail of `TKPlaceDetail` instance containing further attributes.
@property (nonatomic, strong, nullable) TKPlaceDetail *detail;

///---------------------------------------------------------------------------------------
/// @name Helping properties
///---------------------------------------------------------------------------------------

/// Default _HEX_ colour value. Values `0x000000` through `0xFFFFFF`.
@property (atomic, readonly) NSUInteger displayableHexColor;

///---------------------------------------------------------------------------------------
/// @name Helping methods
///---------------------------------------------------------------------------------------

/**
 Returns a list of currently supported Category slugs.

 @return Array of category slugs as strings.
 */
+ (NSArray<NSString *> *)supportedCategories;

@end


/**
 Place tag object.
 */

@interface TKPlaceTag : NSObject

/// Displayable key, always in English.
@property (nonatomic, copy, nonnull) NSString *key;

/// Displayable value, translated if available.
@property (nonatomic, copy, nullable) NSString *name;

@end


/**
 Detail object containing further attributes about the Place.
 */
@interface TKPlaceDetail : NSObject

/// Full-length description.
@property (nonatomic, copy, nullable) NSString *fullDescription;

/// List of Place Tags.
@property (nonatomic, copy, nullable) NSArray<TKPlaceTag *> *tags;

/// List of external References.
@property (nonatomic, copy, nullable) NSArray<TKReference *> *references;

/// List of main Media for use.
@property (nonatomic, copy, nullable) NSArray<TKMedium *> *mainMedia;

/// Address string.
@property (nonatomic, copy, nullable) NSString *address;

/// Phone number string.
@property (nonatomic, copy, nullable) NSString *phone;

/// Email string.
@property (nonatomic, copy, nullable) NSString *email;

/// Average duration, in seconds.
@property (nonatomic, strong, nullable) NSNumber *duration;

/// Opening hours string.
@property (nonatomic, copy, nullable) NSString *openingHours;

/// Admission string.
@property (nonatomic, copy, nullable) NSString *admission;

@end

NS_ASSUME_NONNULL_END
