//
//  TKToursManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 19/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKToursManager.h"
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

- (void)toursForQuery:(TKToursQuery *)query completion:(void (^)(NSArray<TKTour *> *, NSError *))completion
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

	[[[TKAPIRequest alloc] initAsToursRequestForQuery:query success:^(NSArray<TKTour *> *tours) {

		[toursCache setObject:tours forKey:@(query.hash)];

		if (completion)
			completion(tours, nil);

	} failure:^(TKAPIError *error) {

		if (completion)
			completion(nil, error);

	}] start];
}

@end
