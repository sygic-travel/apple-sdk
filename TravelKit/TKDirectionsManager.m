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

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
	if (!query) return nil;

	CLLocationDistance airDistance = [query.destinationLocation distanceFromLocation:query.sourceLocation];

	if (query.waypoints.count) {
		airDistance = 0;
		NSMutableArray<CLLocation *> *waypoints = [query.waypoints mutableCopy];
		[waypoints insertObject:query.sourceLocation atIndex:0];
		[waypoints addObject:query.destinationLocation];
		CLLocation *prev = nil;
		for (CLLocation *wp in waypoints) {
			if (prev) airDistance += [wp distanceFromLocation:prev];
			prev = wp;
		}
	}

	TKEstimateDirectionsInfo *record = [TKEstimateDirectionsInfo new];

	record.startLocation = query.sourceLocation;
	record.endLocation = query.destinationLocation;
	record.airDistance = airDistance;
	record.avoidOption = query.avoidOption;
	record.waypointsPolyline = [TKMapWorker polylineFromPoints:query.waypoints];

	record.airDistance = round([query.sourceLocation distanceFromLocation:query.destinationLocation]);
	record.walkDistance = round(airDistance * (airDistance <= 2000 ? 1.35 : airDistance <= 6000 ? 1.22 : 1.106));
	record.bikeDistance = round(record.walkDistance * 1.1);
	record.carDistance = round(airDistance * (airDistance <= 2000 ? 1.8 : airDistance <= 6000 ? 1.6 : 1.2));
	record.flyDistance = round(airDistance);
	record.walkTime = round(record.walkDistance / 1.35); // 4.8 km/h
	record.bikeTime = round(record.bikeDistance / 3.35); // 12 km/h
	record.carTime = round(record.carDistance / (airDistance > 40000 ? 25 : airDistance > 20000 ? 15 : 7.5)); // 90/54/27 km/h
	record.flyTime = round(40*60 + record.flyDistance / 250); // 900 km/h + 40 min
//
//	// TODO: ~Apply waypoints~, new multiplying constants for 'avoid' options?

	return record;
}

@end
