//
//  TKPlacesManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 23/05/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKPlacesManager.h"
#import "TKAPI+Private.h"


@implementation TKPlacesManager


#pragma mark -
#pragma mark Initialization


+ (TKPlacesManager *)sharedManager
{
	static TKPlacesManager *shared = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[self alloc] init];
	});

	return shared;
}

- (instancetype)init
{
	if (self = [super init])
	{}

	return self;
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

+ (NSCache<NSString *, TKDetailedPlace *> *)detailedPlaceCache
{
	static NSCache<NSString *, TKDetailedPlace *> *placeCache = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		placeCache = [NSCache new];
		placeCache.countLimit = 200;
	});

	return placeCache;
}


#pragma mark -
#pragma mark General queries


- (void)placesForQuery:(TKPlacesQuery *)query completion:(void (^)(NSArray<TKPlace *> *, NSError *))completion
{
	static NSCache<NSNumber *, NSArray<TKPlace *> *> *placesCache = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		placesCache = [NSCache new];
		placesCache.countLimit = 256;
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
				NSMutableArray<TKPlace *> *quadPlaces = sorted[quad];
				[placesCache setObject:quadPlaces forKey:@(hash)];
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

- (void)detailedPlacesWithIDs:(NSArray<NSString *> *)placeIDs completion:(void (^)(NSArray<TKDetailedPlace *> *, NSError *))completion
{
	if (placeIDs.count > 32)
		placeIDs = [placeIDs subarrayWithRange:NSMakeRange(0, 32)];

	NSCache<NSString *, TKDetailedPlace *> *placeCache = [self.class detailedPlaceCache];

	NSMutableArray<TKDetailedPlace *> *ret = [NSMutableArray arrayWithCapacity:placeIDs.count];
	NSMutableArray<NSString *> *requestedIDs = [placeIDs mutableCopy];

	TKDetailedPlace *place = nil;
	for (NSString *placeID in placeIDs)
		if ((place = [placeCache objectForKey:placeID]))
		{
			[ret addObject:place];
			[requestedIDs removeObject:placeID];
		}

	if (!requestedIDs.count) {
		if (completion)
			completion(ret, nil);
		return;
	}

	[[[TKAPIRequest alloc] initAsPlacesRequestForIDs:requestedIDs success:^(NSArray<TKDetailedPlace *> *places) {

		for (TKDetailedPlace *p in places)
			[placeCache setObject:p forKey:p.ID];

		[ret addObjectsFromArray:places];

		if (completion)
			completion(ret, nil);

	} failure:^(TKAPIError *error) {

		if (completion)
			completion(nil, error);

	}] start];
}

- (void)detailedPlaceWithID:(NSString *)placeID completion:(void (^)(TKDetailedPlace *, NSError *))completion
{
	NSCache<NSString *, TKDetailedPlace *> *placeCache = [self.class detailedPlaceCache];

	TKDetailedPlace *cached = [placeCache objectForKey:placeID];

	if (cached) {
		if (completion)
			completion(cached, nil);
		return;
	}

	[[[TKAPIRequest alloc] initAsPlaceRequestForItemWithID:placeID success:^(TKDetailedPlace *place) {

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

- (void)placeCollectionsForQuery:(TKCollectionsQuery *)query
	completion:(void (^)(NSArray<TKCollection *> * _Nullable, NSError * _Nullable))completion
{
	[[[TKAPIRequest alloc] initAsCollectionsRequestForQuery:query success:^(NSArray<TKCollection *> *collections) {

		if (completion)
			completion(collections, nil);

	} failure:^(TKAPIError *error) {

		if (completion)
			completion(nil, error);

	}] start];
}

@end
