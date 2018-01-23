//
//  TravelKit.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TravelKit.h"
#import "TKAPI+Private.h"
#import "TKMapWorker.h"
#import "Foundation+TravelKit.h"


@interface TravelKit ()
{
	NSString *_Nullable _language;
}
@end


@implementation TravelKit

+ (TravelKit *)sharedKit
{
	static TravelKit *shared = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{

#ifdef DEBUG
		NSLog(@"Running TravelKit in DEBUG mode.");
#endif

		shared = [self new];
	});

	return shared;
}

+ (NSArray<NSString *> *)supportedLanguages
{
	static NSArray *langs = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		langs = @[ @"en", @"fr", @"de", @"es", @"nl",
				   @"pt", @"it", @"ru", @"cs", @"sk",
				   @"pl", @"tr", @"zh", @"ko", @"en-GB",
		];
	});

	return langs;
}


#pragma mark -
#pragma mark Configuration


- (void)setAPIKey:(NSString *)APIKey
{
	_APIKey = [APIKey copy];

	[TKAPI sharedAPI].APIKey = _APIKey;
}

- (NSString *)language
{
	return _language ?: @"en";
}

- (void)setLanguage:(NSString *)language
{
	NSArray *supported = [[self class] supportedLanguages];
	NSString *newLanguage = (language &&
	  [supported containsObject:language]) ?
		language : nil;

	_language = [newLanguage copy];

	[TKAPI sharedAPI].language = language;
}


#pragma mark -
#pragma mark Generic methods


- (instancetype)init
{
	if (self = [super init])
	{
		_places = [TKPlacesManager sharedManager];
		__tours = [TKToursManager sharedManager];
		_trips = [TKTripsManager sharedManager];
		_session = [TKSessionManager sharedManager];
		_sync = [TKSynchronizationManager sharedManager];
		__directions = [TKDirectionsManager sharedManager];
	}

	return self;
}

@end


#pragma mark -
#pragma mark Deprecated namespace


@implementation TravelKit (NSDeprecated)

#pragma mark -
#pragma mark Session-related methods


- (void)clearUserData
{
	[_session clearUserData];
}


#pragma mark -
#pragma mark Places


- (void)placesForQuery:(TKPlacesQuery *)query
            completion:(void (^)(NSArray<TKPlace *> *, NSError *))completion
{
	[[TKPlacesManager sharedManager] placesForQuery:query completion:completion];
}

- (void)placesWithIDs:(NSArray<NSString *> *)placeIDs
           completion:(void (^)(NSArray<TKPlace *> *, NSError *))completion
{
	[[TKPlacesManager sharedManager] placesWithIDs:placeIDs completion:completion];
}

- (void)detailedPlaceWithID:(NSString *)placeID
                 completion:(void (^)(TKPlace *, NSError *))completion
{
	[[TKPlacesManager sharedManager] detailedPlaceWithID:placeID completion:completion];
}

- (void)mediaForPlaceWithID:(NSString *)placeID
                 completion:(void (^)(NSArray<TKMedium *> *, NSError *))completion
{
	[[TKPlacesManager sharedManager] mediaForPlaceWithID:placeID completion:completion];
}


#pragma mark -
#pragma mark Tours


- (void)toursForQuery:(TKToursQuery *)query
           completion:(void (^)(NSArray<TKTour *> *, NSError *))completion
{
	[[TKToursManager sharedManager] toursForQuery:query completion:completion];
}


#pragma mark -
#pragma mark Favorites


- (NSArray<NSString *> *)favoritePlaceIDs
{
	return [[TKSessionManager sharedManager] favoritePlaceIDs];
}

- (void)updateFavoritePlaceID:(NSString *)favoriteID setFavorite:(BOOL)favorite
{
	[[TKSessionManager sharedManager] updateFavoritePlaceID:favoriteID setFavorite:favorite];
}


#pragma mark -
#pragma mark Map


- (NSArray<NSString *> *)quadKeysForMapRegion:(MKCoordinateRegion)region
{
	return [TKMapWorker quadKeysForRegion:region];
}

- (NSArray<TKMapPlaceAnnotation *> *)spreadAnnotationsForPlaces:(NSArray<TKPlace *> *)places
	mapRegion:(MKCoordinateRegion)region mapViewSize:(CGSize)size
{
	return [TKMapWorker spreadAnnotationsForPlaces:places mapRegion:region mapViewSize:size];
}

- (void)interpolateNewAnnotations:(NSArray<TKMapPlaceAnnotation *> *)newAnnotations
				   oldAnnotations:(NSArray<TKMapPlaceAnnotation *> *)oldAnnotations
							toAdd:(NSMutableArray<TKMapPlaceAnnotation *> *)toAdd
						   toKeep:(NSMutableArray<TKMapPlaceAnnotation *> *)toKeep
						 toRemove:(NSMutableArray<TKMapPlaceAnnotation *> *)toRemove
{
	[TKMapWorker interpolateNewAnnotations:newAnnotations
	    oldAnnotations:oldAnnotations toAdd:toAdd
		    toKeep:toKeep toRemove:toRemove];
}

@end
