//
//  TravelKit.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for TravelKit.
FOUNDATION_EXPORT double TravelKitVersionNumber;

//! Project version string for TravelKit.
FOUNDATION_EXPORT const unsigned char TravelKitVersionString[];

#import <TravelKit/TKPlace.h>
#import <TravelKit/TKPlacesQuery.h>
#import <TravelKit/TKReference.h>
#import <TravelKit/TKMedium.h>
#import <TravelKit/TKTour.h>
#import <TravelKit/TKTrip.h>
#import <TravelKit/TKToursQuery.h>
#import <TravelKit/TKMapRegion.h>
#import <TravelKit/TKMapWorker.h>
#import <TravelKit/TKMapPlaceAnnotation.h>
#import <TravelKit/TKSession.h>

#import <TravelKit/TKPlacesManager.h>
#import <TravelKit/TKToursManager.h>
#import <TravelKit/TKTripsManager.h>
#import <TravelKit/TKFavoritesManager.h>
#import <TravelKit/TKSessionManager.h>
#import <TravelKit/TKSynchronizationManager.h>
#import <TravelKit/TKDirectionsManager.h>
#import <TravelKit/TKEventsManager.h>

#import <TravelKit/Foundation+TravelKit.h>
#import <TravelKit/NSDate+Tripomatic.h>
#import <TravelKit/NSObject+Parsing.h>

NS_ASSUME_NONNULL_BEGIN

///---------------------------------------------------------------------------------------
/// @name TravelKit SDK
///---------------------------------------------------------------------------------------

/**
 The main class currently used for authentication and data fetching. It provides a singleton
 instance with the public `+sharedKit` method which may be used to work with the _Travel_
 backend.

 The basic workflow is pretty straightforward – to start using _TravelKit_, you only need a
 couple of lines to get the desired data.

```objc
// Get shared instance
TravelKit *kit = [TravelKit sharedKit];

// Set your API key
kit.APIKey = @"<YOUR_API_KEY_GOES_HERE>";

// Ask kit for Eiffel Tower TKDetailedPlace object with details
[kit.places detailedPlaceWithID:@"poi:530" completion:^(TKDetailedPlace *place, NSError *e) {
    if (place) NSLog(@"Let's visit %@!", place.name);
    else NSLog(@"Something went wrong :/");
}];
```
 
 ```swift
 // Use shared instance to set your API key
 TravelKit.shared.apiKey = "<YOUR_API_KEY_GOES_HERE>"
 
 // Ask TKPlaceManager for Eiffel Tower TKDetailedPlace object with details
 TravelKit.shared.places.detailedPlace(withID: "poi:530") { (place, e) in
     if let place = place {
        print("Let's visit \(place.name)")
     }
     else {
        print("Something went wrong :/")
     }
 }
 ```

 @warning API key must be provided, otherwise using any methods listed above will result
 in an error being returned in a call completion block.
 */
@interface TravelKit : NSObject

///---------------------------------------------------------------------------------------
/// @name Initialisation
///---------------------------------------------------------------------------------------

/**
 Shared singleton object to work with.

 @warning Regular `-init` and `+new` methods are not available.
 */
@property (class, readonly, strong) TravelKit *sharedKit NS_SWIFT_NAME(shared);

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)new UNAVAILABLE_ATTRIBUTE;

///---------------------------------------------------------------------------------------
/// @name Key properties
///---------------------------------------------------------------------------------------

/**
 Client API key you've obtained.

 @warning This needs to be set in order to perform static data requests successfully.
 */
@property (nonatomic, copy, nullable) NSString *APIKey;

/**
 Client ID key you've obtained.

 @warning This needs to be set in order to perform user-specific data requests successfully.
 */
@property (nonatomic, copy, nullable) NSString *clientID;

/**
 Preferred language of response data to use.

 @note Supported language codes: **`en`**, **`fr`**, **`de`**, **`es`**, **`nl`**,
       **`pt`**, **`it`**, **`ru`**, **`cs`**, **`sk`**, **`pl`**, **`tr`**,
       **`zh`**, **`ko`**, **`ar`**, **`da`**, **`el`**, **`fi`**, **`he`**,
       **`hu`**, **`no`**, **`ro`**, **`sv`**, **`th`**, **`uk`**.
 
 Default language code is `en`.

 If you want to enforce specific language or pick the one depending on your own choice,
 simply set one of the options listed.

 @warning This needs to be set in order to receive translated content.
 */
@property (nonatomic, copy, null_resettable) NSString *language;

///---------------------------------------------------------------------------------------
/// @name Modules
///---------------------------------------------------------------------------------------

/**
 Shared Place Manager instance to provide Places-related stuff.
 */
@property (nonatomic, strong, readonly) TKPlacesManager *places;

/**
 Shared Trips Manager instance to provide Trips-related stuff.
 */
@property (nonatomic, strong, readonly) TKTripsManager *trips;

/**
 Shared Trips Manager instance to provide Trips-related stuff.
 */
@property (nonatomic, strong, readonly) TKFavoritesManager *favorites;

/**
 Shared Tours Manager instance to provide Tours-related stuff.
 */
@property (nonatomic, strong, readonly) TKToursManager *tours;

/**
 Shared Session Manager instance to provide Session-related stuff.
 */
@property (nonatomic, strong, readonly) TKSessionManager *session;

/**
 Shared Synchronization Manager instance to provide Sync-related stuff.
 */
@property (nonatomic, strong, readonly) TKSynchronizationManager *sync;

/**
 Shared Directions Manager instance to provide directions- & routing-related stuff.

 @warning Experimental.
 */
@property (nonatomic, strong, readonly) TKDirectionsManager *_directions
	DEPRECATED_MSG_ATTRIBUTE("Experimental.");

/**
 Shared Events Manager instance to retain event handlers.
 */
@property (nonatomic, strong, readonly) TKEventsManager *events;

@end

///---------------------------------------------------------------------------------------
/// @name Deprecated interface stuff
///---------------------------------------------------------------------------------------

/**
 A set of deprecated stuff on `TravelKit` class.
 */
@interface TravelKit (NSDeprecated)

///---------------------------------------------------------------------------------------
/// @name Place working queries
///---------------------------------------------------------------------------------------

/// :nodoc:

- (void)placesForQuery:(TKPlacesQuery *)query
	completion:(void (^)(NSArray<TKPlace *>  * _Nullable places, NSError * _Nullable error))completion
		DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKPlacesManager` instead.");

- (void)placesWithIDs:(NSArray<NSString *> *)placeIDs
	completion:(void (^)(NSArray<TKDetailedPlace *> * _Nullable places, NSError * _Nullable error))completion
		DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKPlacesManager` instead.");

- (void)detailedPlaceWithID:(NSString *)placeID
	completion:(void (^)(TKDetailedPlace * _Nullable place, NSError * _Nullable error))completion
		DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKPlacesManager` instead.");

///---------------------------------------------------------------------------------------
/// @name Media working queries
///---------------------------------------------------------------------------------------

/// :nodoc:

- (void)mediaForPlaceWithID:(NSString *)placeID
	completion:(void (^)(NSArray<TKMedium *> * _Nullable media, NSError * _Nullable error))completion
		 DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKPlacesManager` instead.");

///---------------------------------------------------------------------------------------
/// @name Favorites
///---------------------------------------------------------------------------------------

/// :nodoc:

- (NSArray<NSString *> *)favoritePlaceIDs DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKSessionManager` instead.");

- (void)updateFavoritePlaceID:(NSString *)favoriteID setFavorite:(BOOL)favorite
	DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKSessionManager` instead.");

///---------------------------------------------------------------------------------------
/// @name Map-related methods
///---------------------------------------------------------------------------------------

/// :nodoc:

- (NSArray<NSString *> *)quadKeysForMapRegion:(MKCoordinateRegion)region
	DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKMapWorker` instead.");

- (NSArray<TKMapPlaceAnnotation *> *)spreadAnnotationsForPlaces:(NSArray<TKPlace *> *)places
            mapRegion:(MKCoordinateRegion)region mapViewSize:(CGSize)size
	DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKMapWorker` instead.");

- (void)interpolateNewAnnotations:(NSArray<TKMapPlaceAnnotation *> *)newAnnotations
                   oldAnnotations:(NSArray<TKMapPlaceAnnotation *> *)oldAnnotations
                            toAdd:(NSMutableArray<TKMapPlaceAnnotation *> *)toAdd
                           toKeep:(NSMutableArray<TKMapPlaceAnnotation *> *)toKeep
                         toRemove:(NSMutableArray<TKMapPlaceAnnotation *> *)toRemove
	DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKMapWorker` instead.");

///---------------------------------------------------------------------------------------
/// @name Session-related methods
///---------------------------------------------------------------------------------------

/// :nodoc:

- (void)clearUserData DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKSessionManager` instead.");

@end

NS_ASSUME_NONNULL_END
