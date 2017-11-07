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
#import <TravelKit/TKUserCredentials.h>

#import <TravelKit/TKPlacesManager.h>
#import <TravelKit/TKToursManager.h>
#import <TravelKit/TKTripsManager.h>
#import <TravelKit/TKSessionManager.h>
#import <TravelKit/TKSynchronizationManager.h>

#import <TravelKit/Foundation+TravelKit.h>
#import <TravelKit/NSDate+Tripomatic.h>
#import <TravelKit/NSObject+Parsing.h>

NS_ASSUME_NONNULL_BEGIN

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

// Ask kit for Eiffel Tower TKPlace object with details
[kit detailedPlaceWithID:@"poi:530" completion:^(TKPlace *place, NSError *e) {
    if (place) NSLog(@"Let's visit %@!", place.name);
    else NSLog(@"Something went wrong :/");
}];
```

 @warning API key must be provided, otherwise using any methods listed below will result
 in an error being returned in a call completion block.
 */
@interface TravelKit : NSObject

///---------------------------------------------------------------------------------------
/// @name Key properties
///---------------------------------------------------------------------------------------

/**
 Client API key you've obtained.

 @warning This needs to be set in order to perform data requests successfully.
 */
@property (nonatomic, copy, nullable) NSString *APIKey;

/**
 Preferred language of response data to use.

 @note Supported language codes: **`en`**, **`fr`**, **`de`**, **`es`**, **`nl`**,
       **`pt`**, **`it`**, **`ru`**, **`cs`**, **`sk`**, **`pl`**, **`tr`**,
       **`zh`**, **`ko`**.
 
 Default language code is `en`.

 If you want to enforce specific language or pick the one depending on your own choice,
 simply set one of the options listed.

 @warning This needs to be set in order to receive translated content.
 */
@property (nonatomic, copy, null_resettable) NSString *language;

///---------------------------------------------------------------------------------------
/// @name Initialisation
///---------------------------------------------------------------------------------------

/**
 Shared singleton object to work with.

 @return Singleton `TravelKit` object.

 @warning Regular `-init` and `+new` methods are not available.
 */
+ (nonnull TravelKit *)sharedKit NS_SWIFT_NAME(shared());

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)new UNAVAILABLE_ATTRIBUTE;

///---------------------------------------------------------------------------------------
/// @name Modules
///---------------------------------------------------------------------------------------

/**
 Shared Place Manager instance to provide Places-related stuff.
 */
@property (nonatomic, strong, readonly) TKPlacesManager *places;

/**
 Shared Tours Manager instance to provide Tours-related stuff.

 @warning Experimental.
 */
@property (nonatomic, strong, readonly) TKToursManager *_tours
	DEPRECATED_MSG_ATTRIBUTE("Experimental.");

/**
 Shared Trips Manager instance to provide Trips-related stuff.
 */
@property (nonatomic, strong, readonly) TKTripsManager *trips;

/**
 Shared Session Manager instance to provide Session-related stuff.
 */
@property (nonatomic, strong, readonly) TKSessionManager *session;

/**
 Shared Synchronization Manager instance to provide Sync-related stuff.
 */
@property (nonatomic, strong, readonly) TKSynchronizationManager *sync;

@end

///---------------------------------------------------------------------------------------
/// @name Deprecated interface stuff
///---------------------------------------------------------------------------------------

@interface TravelKit (Deprecated)

///---------------------------------------------------------------------------------------
/// @name Place working queries
///---------------------------------------------------------------------------------------

- (void)placesForQuery:(TKPlacesQuery *)query
	completion:(void (^)(NSArray<TKPlace *>  * _Nullable places, NSError * _Nullable error))completion
		DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKPlacesManager` instead.");

- (void)placesWithIDs:(NSArray<NSString *> *)placeIDs
	completion:(void (^)(NSArray<TKPlace *> * _Nullable places, NSError * _Nullable error))completion
		DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKPlacesManager` instead.");

- (void)detailedPlaceWithID:(NSString *)placeID
	completion:(void (^)(TKPlace * _Nullable place, NSError * _Nullable error))completion
		DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKPlacesManager` instead.");

///---------------------------------------------------------------------------------------
/// @name Media working queries
///---------------------------------------------------------------------------------------

- (void)mediaForPlaceWithID:(NSString *)placeID
	completion:(void (^)(NSArray<TKMedium *> * _Nullable media, NSError * _Nullable error))completion
		 DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKPlacesManager` instead.");

///---------------------------------------------------------------------------------------
/// @name Tours working queries
///---------------------------------------------------------------------------------------

- (void)toursForQuery:(TKToursQuery *)query
	completion:(void (^)(NSArray<TKTour *>  * _Nullable tours, NSError * _Nullable error))completion
		 DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKToursManager` instead.");

///---------------------------------------------------------------------------------------
/// @name Favorites
///---------------------------------------------------------------------------------------

- (NSArray<NSString *> *)favoritePlaceIDs DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKSessionManager` instead.");

- (void)updateFavoritePlaceID:(NSString *)favoriteID setFavorite:(BOOL)favorite
	DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKSessionManager` instead.");

///---------------------------------------------------------------------------------------
/// @name Map-related methods
///---------------------------------------------------------------------------------------

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

- (void)clearUserData DEPRECATED_MSG_ATTRIBUTE("Use a method on `TKSessionManager` instead.");

@end

NS_ASSUME_NONNULL_END
