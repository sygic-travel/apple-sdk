//
//  TKToursManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 19/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <TravelKit/TKToursManager.h>
#import "TKAPI+Private.h"


@implementation TKToursManager

+ (TKToursManager *)sharedManager
{
	static TKToursManager *shared = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[self alloc] init];
	});

	return shared;
}

- (void)toursForViatorQuery:(TKToursViatorQuery *)query
                 completion:(void (^)(NSArray<TKTour *> * _Nullable, NSError * _Nullable))completion
{
	static NSCache<NSNumber *, NSArray<TKTour *> *> *toursCache = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		toursCache = [NSCache new];
		toursCache.countLimit = 32;
	});

	NSArray *cached = [toursCache objectForKey:@(query.hash)];
	if (cached) {
		if (completion)
			completion(cached, nil);
		return;
	}

	[[[TKAPIRequest alloc] initAsViatorToursRequestForQuery:query success:^(NSArray<TKTour *> *tours) {

		[toursCache setObject:tours forKey:@(query.hash)];

		if (completion)
			completion(tours, nil);

	} failure:^(TKAPIError *error) {

		if (completion)
			completion(nil, error);

	}] start];
}

- (void)toursForGYGQuery:(TKToursGYGQuery *)query
              completion:(void (^)(NSArray<TKTour *> * _Nullable, NSError * _Nullable))completion
{
	static NSCache<NSNumber *, NSArray<TKTour *> *> *toursCache = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		toursCache = [NSCache new];
		toursCache.countLimit = 32;
	});

	NSArray *cached = [toursCache objectForKey:@(query.hash)];
	if (cached) {
		if (completion)
			completion(cached, nil);
		return;
	}

	[[[TKAPIRequest alloc] initAsGYGToursRequestForQuery:query success:^(NSArray<TKTour *> *tours) {

		[toursCache setObject:tours forKey:@(query.hash)];

		if (completion)
			completion(tours, nil);

	} failure:^(TKAPIError *error) {

		if (completion)
			completion(nil, error);

	}] start];
}

@end
