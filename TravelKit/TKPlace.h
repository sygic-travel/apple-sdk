//
//  TKPlace.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import <TravelKit/TKMapRegion.h>
#import <TravelKit/TKReference.h>
#import <TravelKit/TKMedium.h>

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

/**
 Flag value defining which categories a particular `TKPlace` belongs to.
 */
typedef NS_OPTIONS(NSUInteger, TKPlaceCategory) {
	/// Default value.
	TKPlaceCategoryNone           = 0,
	/// Sightseeing.
	TKPlaceCategorySightseeing    = 1 << 0,
	/// Shopping.
	TKPlaceCategoryShopping       = 1 << 1,
	/// Eating.
	TKPlaceCategoryEating         = 1 << 2,
	/// Discovering.
	TKPlaceCategoryDiscovering    = 1 << 3,
	/// Playing.
	TKPlaceCategoryPlaying        = 1 << 4,
	/// Traveling.
	TKPlaceCategoryTraveling      = 1 << 5,
	/// Going out.
	TKPlaceCategoryGoingOut       = 1 << 6,
	/// Hiking.
	TKPlaceCategoryHiking         = 1 << 7,
	/// Doing sports.
	TKPlaceCategoryDoingSports    = 1 << 8,
	/// Relaxing.
	TKPlaceCategoryRelaxing       = 1 << 9,
	/// Sleeping.
	TKPlaceCategorySleeping       = 1 << 10,
};

/**
 Flag value indicating a source of a description.
 */
typedef NS_OPTIONS(NSUInteger, TKPlaceDescriptionProvider) {
	/// No or in-house description.
	TKPlaceDescriptionProviderNone           = 0,
	/// Wikipedia description.
	TKPlaceDescriptionProviderWikipedia      = 1 << 0,
	/// Wikivoyage description.
	TKPlaceDescriptionProviderWikivoyage     = 1 << 1,
};

/**
 Flag value indicating a source of a translation.
 */
typedef NS_OPTIONS(NSUInteger, TKTranslationProvider) {
	/// No or in-house translation.
	TKTranslationProviderNone           = 0,
	/// Google Translate.
	TKTranslationProviderGoogle         = 1 << 0,
};


NS_ASSUME_NONNULL_BEGIN

@class TKPlaceTag, TKPlaceDetail;


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Place object
///-----------------------------------------------------------------------------

/**
 Basic Place model keeping various information about its properties.
 */
@interface TKPlace : NSObject

///----------------------
/// @name Hard properties
///----------------------

/// Global identifier.
@property (nonatomic, copy, readonly) NSString *ID NS_SWIFT_NAME(ID);

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

/// Global rating value.
///
/// @note Possible values: double in range `0`--`10.0`.
@property (nonatomic, strong, nullable) NSNumber *rating;

/// Marker identifier usable for displayable icon.
@property (nonatomic, copy, nullable) NSString *marker;

/// List of Category slugs assigned.
///
/// @see `TKPlaceCategory`
@property (atomic) TKPlaceCategory categories;

/// List of Parent IDs.
@property (nonatomic, copy, nullable) NSArray<NSString *> *parents;

/// List of custom flags.
@property (nonatomic, copy, nullable) NSArray<NSString *> *flags;

/// Thumbnail URL to an image of size 150×150 pixels.
@property (nonatomic, strong, nullable) NSURL *thumbnailURL;

/// Place detail of `TKPlaceDetail` instance containing further attributes.
@property (nonatomic, strong, nullable) TKPlaceDetail *detail;

///-------------------------
/// @name Helping properties
///-------------------------

/// Default _HEX_ colour value. Values `0x000000` through `0xFFFFFF`.
@property (atomic, readonly) NSUInteger displayableHexColor;

@end


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Place Description object
///-----------------------------------------------------------------------------

/**
 Place description object.
 */
@interface TKPlaceDescription : NSObject

/// Full-length text description.
@property (nonatomic, copy) NSString *text;

/// Flag of the description provider.
@property (atomic) TKPlaceDescriptionProvider provider;

/// URL address of the description source.
@property (nonatomic, copy, nullable) NSURL *sourceURL;

/// Flag of the translation provider.
@property (atomic) TKTranslationProvider translationProvider;

/// Flag indicating whether the description provided is translated.
@property (atomic) BOOL translated;

@end


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Place Tag object
///-----------------------------------------------------------------------------

/**
 Place tag object.
 */
@interface TKPlaceTag : NSObject

/// Displayable key, always in English.
@property (nonatomic, copy, nonnull) NSString *key;

/// Displayable value, translated if available.
@property (nonatomic, copy, nullable) NSString *name;

@end


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Place Detail object
///-----------------------------------------------------------------------------

/**
 Detail object containing further attributes about the Place.
 */
@interface TKPlaceDetail : NSObject

/// `TKPlaceDescription` instance object containing a detailed description.
@property (nonatomic, strong, nullable) TKPlaceDescription *fullDescription;

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

/// Typical duration, in seconds.
@property (nonatomic, strong, nullable) NSNumber *duration;

/// Opening hours string.
@property (nonatomic, copy, nullable) NSString *openingHours;

/// Admission string.
@property (nonatomic, copy, nullable) NSString *admission;

@end

NS_ASSUME_NONNULL_END
