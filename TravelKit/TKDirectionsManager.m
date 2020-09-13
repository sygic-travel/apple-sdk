//
//  TKDirectionsManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/01/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import "TKDirectionsManager.h"
#import "TKMapWorker.h"
#import "TKAPI+Private.h"
#import "TKReachability+Private.h"
#import "NSObject+Parsing.h"


/////////////////////////////////
/////////////////////////////////

#pragma mark - Directions manager

/////////////////////////////////
/////////////////////////////////


@interface TKDirectionsManager ()

@property (nonatomic, strong) NSCache<NSString *, TKDirectionsSet *> *directionsCache;
@property (nonatomic, strong) NSOperationQueue *directionsQueue;

@end

@implementation TKDirectionsManager

- (instancetype)init
{
	if (self = [super init])
	{
		_directionsCache = [NSCache new];
		_directionsQueue = [NSOperationQueue new];
		_directionsQueue.name = @"Directions queue";
		_directionsQueue.maxConcurrentOperationCount = 8;
		if ([_directionsQueue respondsToSelector:@selector(setQualityOfService:)])
			_directionsQueue.qualityOfService = NSQualityOfServiceBackground;
	}

	return self;
}

+ (TKDirectionsManager *)sharedManager
{
	static dispatch_once_t once = 0;
	static TKDirectionsManager *shared = nil;
	dispatch_once(&once, ^{	shared = [[self alloc] init]; });
	return shared;
}


#pragma mark - Directions stuff


- (void)directionsSetForQuery:(TKDirectionsQuery *)query completion:(nullable void (^)(TKDirectionsSet *_Nullable))completion
{
	// Check equality of locations
	if ([query.sourceLocation distanceFromLocation:query.destinationLocation] < 16)
	{
		if (completion) completion(nil);
		return;
	}

	// Get coord key from locations
	NSString *cacheKey = [query cacheKey];

	// Return cached record when available
	TKDirectionsSet *record = [_directionsCache objectForKey:cacheKey];
	if (record) {
		if (completion) completion(record);
		return;
	}

	[_directionsQueue addOperationWithBlock:^{
		[[[TKAPIRequest alloc] initAsDirectionsRequestForQuery:query success:^(TKDirectionsSet *directionsSet) {

			if (directionsSet)
				[_directionsCache setObject:directionsSet forKey:cacheKey];

			if (completion) completion(directionsSet);

		} failure:^(TKAPIError *__unused e) {
			if (completion) completion(nil);
		}] silentStart];
	}];
}

- (nullable TKEstimateDirectionsInfo *)estimatedDirectionsInfoForQuery:(TKDirectionsQuery *)query
{
	return [TKEstimateDirectionsInfo infoForQuery:query];
}

@end
