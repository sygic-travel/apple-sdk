//
//  TravelKit.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TravelKit.h"
#import "TKAPI+Private.h"


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

	NSUInteger queryHash = query.hash;

	NSArray<TKPlace *> *cached = [placesCache objectForKey:@(queryHash)];

	if (cached) {
		if (completion)
			completion(cached, nil);
		return;
	}

	[[[TKAPIRequest alloc] initAsPlacesRequestForQuery:query success:^(NSArray<TKPlace *> *places) {

		[placesCache setObject:places forKey:@(queryHash)];

		if (completion)
			completion(places, nil);

	} failure:^(TKAPIError *error) {

		if (completion)
			completion(nil, error);

	}] start];
}

- (void)detailedPlaceWithID:(NSString *)placeID completion:(void (^)(TKPlace *, NSError *))completion
{
	static NSCache<NSString *, TKPlace *> *placeCache = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		placeCache = [NSCache new];
		placeCache.countLimit = 200;
	});

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
