//
//  TKPlacesManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 23/05/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKPlacesManager+Private.h"
#import "TKAPI+Private.h"


@implementation TKPlacesManager

+ (instancetype)sharedManager
{
	static TKPlacesManager *shared = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[self alloc] init];
	});

	return shared;
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

@end
