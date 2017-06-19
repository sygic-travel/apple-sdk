//
//  TKToursManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 19/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKToursManager+Private.h"
#import "TKAPI+Private.h"


@implementation TKToursManager

+ (instancetype)sharedManager
{
	static TKToursManager *shared = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[self alloc] init];
	});

	return shared;
}

- (void)toursForQuery:(TKToursQuery *)query completion:(void (^)(NSArray<TKTour *> *, NSError *))completion
{
	static NSCache<NSNumber *, NSArray<TKTour *> *> *placesCache = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		placesCache = [NSCache new];
		placesCache.countLimit = 256;
	});

	NSArray *cached = [placesCache objectForKey:@(query.hash)];
	if (cached) {
		if (completion)
			completion(cached, nil);
		return;
	}

	[[[TKAPIRequest alloc] initAsToursRequestForQuery:query success:^(NSArray<TKTour *> *tours) {

		[placesCache setObject:tours forKey:@(query.hash)];

		if (completion)
			completion(tours, nil);

	} failure:^(TKAPIError *error) {

		if (completion)
			completion(nil, error);

	}] start];
}

@end
