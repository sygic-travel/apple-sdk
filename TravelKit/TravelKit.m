//
//  TravelKit.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TravelKit.h"
#import "TKAPI+Private.h"
#import "TKMapWorker+Private.h"
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

+ (NSCache<NSString *, TKPlace *> *)placeCache
{
	static NSCache<NSString *, TKPlace *> *placeCache = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		placeCache = [NSCache new];
		placeCache.countLimit = 200;
	});

	return placeCache;
}

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

- (void)placesForQuery:(TKPlacesQuery *)query completion:(void (^)(NSArray<TKPlace *> *, NSError *))completion
{
	static NSCache<NSNumber *, NSArray<TKPlace *> *> *placesCache = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		placesCache = [NSCache new];
		placesCache.countLimit = 100;
	});

	if (query.quadKeys.count <= 1)
	{
		NSArray *cached = [placesCache objectForKey:@(query.hash)];
		if (cached) {
			if (completion)
				completion(cached, nil);
			return;
		}
	}

	NSMutableArray<NSString *> *neededQuadKeys =
		[NSMutableArray arrayWithCapacity:query.quadKeys.count];
	NSMutableArray<TKPlace *> *cachedPlaces =
		[NSMutableArray arrayWithCapacity:200];

	TKPlacesQuery *workingQuery = [query copy];

	for (NSString *quad in query.quadKeys) {

		workingQuery.quadKeys = @[ quad ];
		NSUInteger queryHash = workingQuery.hash;

		NSArray<TKPlace *> *cached = [placesCache objectForKey:@(queryHash)];

		if (cached)
			[cachedPlaces addObjectsFromArray:cached];
		else
			[neededQuadKeys addObject:quad];
	}

	if (query.quadKeys.count && !neededQuadKeys.count) {
		if (completion)
		{
			[cachedPlaces sortUsingComparator:^NSComparisonResult(TKPlace *lhs, TKPlace *rhs) {
				return [rhs.rating ?: @0 compare:lhs.rating ?: @0];
			}];
			completion(cachedPlaces, nil);
		}
		return;
	}

	workingQuery.quadKeys = neededQuadKeys;

	[[[TKAPIRequest alloc] initAsPlacesRequestForQuery:workingQuery success:^(NSArray<TKPlace *> *places) {

		if (neededQuadKeys.count)
		{
			[cachedPlaces addObjectsFromArray:places];

			NSMutableDictionary<NSString *, NSMutableArray<TKPlace *> *>
				*sorted = [NSMutableDictionary dictionaryWithCapacity:neededQuadKeys.count];

			for (NSString *quad in neededQuadKeys)
				sorted[quad] = [NSMutableArray arrayWithCapacity:64];

			for (TKPlace *p in places)
				for (NSString *quad in neededQuadKeys)
					if ([p.quadKey hasPrefix:quad])
					{
						[sorted[quad] addObject:p];
						break;
					}

			for (NSString *quad in sorted.allKeys)
			{
				workingQuery.quadKeys = @[ quad ];
				NSUInteger hash = workingQuery.hash;
				[placesCache setObject:sorted[quad] forKey:@(hash)];
			}

			places = [cachedPlaces sortedArrayUsingComparator:^NSComparisonResult(TKPlace *lhs, TKPlace *rhs) {
				return [rhs.rating ?: @0 compare:lhs.rating ?: @0];
			}];
		}
		else {
			NSUInteger queryHash = workingQuery.hash;
			[placesCache setObject:places forKey:@(queryHash)];

		}

		if (completion)
			completion(places, nil);

	} failure:^(TKAPIError *error) {

		if (completion)
			completion(nil, error);

	}] start];
}

- (void)placesWithIDs:(NSArray<NSString *> *)placeIDs completion:(void (^)(NSArray<TKPlace *> *, NSError *))completion
{
	NSCache<NSString *, TKPlace *> *placeCache = [self.class placeCache];

	NSMutableArray<TKPlace *> *ret = [NSMutableArray arrayWithCapacity:placeIDs.count];
	NSMutableArray *requested = [placeIDs mutableCopy];

	TKPlace *place = nil;
	for (NSString *placeID in placeIDs)
		if ((place = [placeCache objectForKey:placeID]))
		{
			[ret addObject:place];
			[requested removeObject:placeID];
		}

	if (!requested.count) {
		if (completion)
			completion(ret, nil);
		return;
	}

	[[[TKAPIRequest alloc] initAsPlacesRequestForIDs:requested success:^(NSArray<TKPlace *> *places) {

		for (TKPlace *p in places)
			[placeCache setObject:place forKey:p.ID];

		[requested addObjectsFromArray:places];

		if (completion)
			completion(requested, nil);

	} failure:^(TKAPIError *error) {

		if (completion)
			completion(nil, error);

	}] start];
}

- (void)detailedPlaceWithID:(NSString *)placeID completion:(void (^)(TKPlace *, NSError *))completion
{
	NSCache<NSString *, TKPlace *> *placeCache = [self.class placeCache];

	TKPlace *cached = [placeCache objectForKey:placeID];

	if (cached) {
		if (completion)
			completion(cached, nil);
		return;
	}

	[[[TKAPIRequest alloc] initAsPlaceRequestForItemWithID:placeID success:^(TKPlace *place) {

		[placeCache setObject:place forKey:placeID];

		if (completion)
			completion(place, nil);

	} failure:^(TKAPIError *error) {

		if (completion)
			completion(nil, error);

	}] start];
}

- (void)mediaForPlaceWithID:(NSString *)placeID completion:(void (^)(NSArray<TKMedium *> *, NSError *))completion
{
	static NSCache<NSString *, NSArray<TKMedium *> *> *mediaCache = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		mediaCache = [NSCache new];
		mediaCache.countLimit = 50;
	});

	NSArray *cached = [mediaCache objectForKey:placeID];

	if (cached) {
		if (completion)
			completion(cached, nil);
		return;
	}

	[[[TKAPIRequest alloc] initAsMediaRequestForPlaceWithID:placeID success:^(NSArray<TKMedium *> *media) {

		[mediaCache setObject:media forKey:placeID];

		if (completion)
			completion(media, nil);

	} failure:^(TKAPIError *error){

		if (completion)
			completion(nil, error);

	}] start];
}

- (NSArray<NSString *> *)quadKeysForMapRegion:(MKCoordinateRegion)region
{
	return [TKMapWorker quadKeysForRegion:region];
}

- (NSArray<TKMapPlaceAnnotation *> *)spreadedAnnotationsForPlaces:(NSArray<TKPlace *> *)places
	mapRegion:(MKCoordinateRegion)region mapViewSize:(CGSize)size
{
	NSMutableArray<TKPlace *> *workingPlaces = [places mutableCopy];

	// Minimal distance between annotations with basic size of 64 pixels
	CLLocationDistance minDistance = region.span.latitudeDelta / (size.height / 64) * 111000;

	NSMutableArray<TKMapPlaceAnnotation *> *annotations = [NSMutableArray arrayWithCapacity:workingPlaces.count];

	NSMutableArray<TKPlace *> *firstClass   = [NSMutableArray arrayWithCapacity:workingPlaces.count / 4];
	NSMutableArray<TKPlace *> *secondClass  = [NSMutableArray arrayWithCapacity:workingPlaces.count / 2];
	NSMutableArray<TKPlace *> *thirdClass   = [NSMutableArray arrayWithCapacity:workingPlaces.count / 2];

	for (TKPlace *p in workingPlaces)
	{
		if (p.rating.floatValue < 6.0 || !p.thumbnailURL) continue;

		BOOL conflict = NO;
		for (TKPlace *i in firstClass)
			if ([i.location distanceFromLocation:p.location] < minDistance)
			{ conflict = YES; break; }
		if (!conflict) [firstClass addObject:p];
	}

	[workingPlaces removeObjectsInArray:firstClass];

	for (TKPlace *p in workingPlaces)
	{
		if (!p.thumbnailURL) continue;

		BOOL conflict = NO;
		for (TKPlace *i in firstClass)
			if ([i.location distanceFromLocation:p.location] < 0.95*minDistance)
			{ conflict = YES; break; }
		for (TKPlace *i in secondClass)
			if ([i.location distanceFromLocation:p.location] < 0.85*minDistance)
			{ conflict = YES; break; }
		if (!conflict) [secondClass addObject:p];
	}

	[workingPlaces removeObjectsInArray:secondClass];

	for (TKPlace *p in workingPlaces)
	{
		BOOL conflict = NO;
		for (TKPlace *i in firstClass)
			if ([i.location distanceFromLocation:p.location] < 0.7*minDistance)
			{ conflict = YES; break; }
		for (TKPlace *i in secondClass)
			if ([i.location distanceFromLocation:p.location] < 0.6*minDistance)
			{ conflict = YES; break; }
		for (TKPlace *i in thirdClass)
			if ([i.location distanceFromLocation:p.location] < 0.5*minDistance)
			{ conflict = YES; break; }
		if (!conflict) [thirdClass addObject:p];
	}

	NSArray<TKMapPlaceAnnotation *> *classAnnotations = [firstClass
	  mappedArrayUsingBlock:^id(TKPlace *place, NSUInteger __unused idx) {
		TKMapPlaceAnnotation *anno = [[TKMapPlaceAnnotation alloc] initWithPlace:place];
		anno.pixelSize = 56;
		return anno;
	}];

	[annotations addObjectsFromArray:classAnnotations];

	classAnnotations = [secondClass
	  mappedArrayUsingBlock:^id(TKPlace *place, NSUInteger __unused idx) {
		TKMapPlaceAnnotation *anno = [[TKMapPlaceAnnotation alloc] initWithPlace:place];
		anno.pixelSize = 38;
		return anno;
	}];

	[annotations addObjectsFromArray:classAnnotations];

	classAnnotations = [thirdClass
	  mappedArrayUsingBlock:^id(TKPlace *place, NSUInteger __unused idx) {
		TKMapPlaceAnnotation *anno = [[TKMapPlaceAnnotation alloc] initWithPlace:place];
		anno.pixelSize = 14;
		return anno;
	}];

	[annotations addObjectsFromArray:classAnnotations];

	return annotations;
}

- (void)interpolateNewAnnotations:(NSArray<TKMapPlaceAnnotation *> *)newAnnotations
				   oldAnnotations:(NSArray<TKMapPlaceAnnotation *> *)oldAnnotations
							toAdd:(NSMutableArray<TKMapPlaceAnnotation *> *)toAdd
						   toKeep:(NSMutableArray<TKMapPlaceAnnotation *> *)toKeep
						 toRemove:(NSMutableArray<TKMapPlaceAnnotation *> *)toRemove
{
	NSArray<NSString *> *displayedIDs = [newAnnotations
	  mappedArrayUsingBlock:^id _Nonnull(TKMapPlaceAnnotation *p, NSUInteger __unused i) {
		return p.place.ID;
	}];

	for (TKMapPlaceAnnotation *p in oldAnnotations)
	{
		if (![p isKindOfClass:[TKMapPlaceAnnotation class]]) continue;

		if ([displayedIDs containsObject:p.place.ID])
			[toKeep addObject:p];
		else [toRemove addObject:p];
	}

	for (TKMapPlaceAnnotation *p in newAnnotations)
	{
		if (![p isKindOfClass:[TKMapPlaceAnnotation class]]) continue;

		BOOL displayed = NO;
		for (TKMapPlaceAnnotation *k in toKeep)
			if ([k.place.ID isEqual:p.place.ID])
				displayed = YES;
		if (!displayed)
			[toAdd addObject:p];
	}
}

@end
