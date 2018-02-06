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


- (void)directionsSetForQuery:(TKDirectionsQuery *)query
                   completion:(nullable void (^)(TKDirectionsSet * _Nullable))completion
{
	// Get estimated set at first
	TKDirectionsSet *estimated = [self estimatedDirectionsSetForQuery:query];

	// Check equality of locations
	if ([query.startLocation distanceFromLocation:query.endLocation] < 16) {
		if (completion) completion(estimated);
		return;
	}

	// Get coord key from locations
	NSString *cacheKey = [self cacheKeyForQuery:query];

	// Return cached record when available
	TKDirectionsSet *set = [_directionsCache objectForKey:cacheKey];
	if (set) {
		if (completion) completion(set);
		return;
	}

	// Also enqueue API request for the record
	[_directionsQueue addOperationWithBlock:^{

		[[[TKAPIRequest alloc] initAsDirectionsRequestForQuery:query success:^(TKDirectionsSet *directionsSet) {

			// Fill with estimated data when no type-data available

			if (!directionsSet.pedestrianDirections.count)
				directionsSet.pedestrianDirections = estimated.pedestrianDirections;

			if (!directionsSet.bikeDirections.count)
				directionsSet.bikeDirections = estimated.bikeDirections;

			if (!directionsSet.carDirections.count)
				directionsSet.carDirections = estimated.carDirections;

			if (!directionsSet.planeDirections.count)
				directionsSet.planeDirections = estimated.planeDirections;

			// Cache
			[_directionsCache setObject:directionsSet forKey:cacheKey];

			// Completion
			if (completion) completion(directionsSet);

		} failure:^(TKAPIError *__unused error) {

			if (completion) completion(estimated);

		}] start];
	}];
}

- (TKDirectionsSet *)estimatedDirectionsSetForQuery:(TKDirectionsQuery *)query
{
	TKDirectionsSet *set = [TKDirectionsSet new];
	set.startLocation = query.startLocation;
	set.endLocation = query.endLocation;
	CLLocationDistance airDistance =
		set.airDistance = round([query.endLocation
			distanceFromLocation:query.startLocation]);

	if (query.waypointsPolyline) {
		NSArray<CLLocation *> *points = [TKMapWorker pointsFromPolyline:query.waypointsPolyline];
		CLLocation *prev = nil;
		CLLocationDistance sum = 0;
		for (CLLocation *p in points) {
			if (prev) sum += [p distanceFromLocation:prev];
			prev = p;
		}
		if (sum > 0) airDistance = set.airDistance = sum;
	}

	// Pedestrian

	TKDirection *direction = [TKDirection new];
	direction.startLocation = query.startLocation;
	direction.endLocation = query.endLocation;
	direction.mode = TKDirectionTransportModePedestrian;
	direction.estimated = YES;
	direction.distance = round(airDistance * (airDistance <= 2000 ? 1.35 : airDistance <= 6000 ? 1.22 : 1.106));
	direction.duration = round(direction.distance / 1.35); // 4.8 km/h
	direction.avoidOption = query.avoidOption;
	direction.waypointsPolyline = query.waypointsPolyline;

	set.pedestrianDirections = @[ direction ];

	// Bike

	direction = [TKDirection new];
	direction.startLocation = query.startLocation;
	direction.endLocation = query.endLocation;
	direction.mode = TKDirectionTransportModeBike;
	direction.estimated = YES;
	direction.distance = round(airDistance * (airDistance <= 2000 ? 1.35 : airDistance <= 6000 ? 1.22 : 1.106));
	direction.duration = round(direction.distance / 3.9); // 14 km/h
	direction.avoidOption = query.avoidOption;
	direction.waypointsPolyline = query.waypointsPolyline;

	set.bikeDirections = @[ direction ];

	// Car

	direction = [TKDirection new];
	direction.startLocation = query.startLocation;
	direction.endLocation = query.endLocation;
	direction.mode = TKDirectionTransportModeCar;
	direction.estimated = YES;
	direction.distance = round(airDistance * (airDistance <= 2000 ? 1.8 : airDistance <= 6000 ? 1.6 : 1.2));
	direction.duration = round(direction.distance / (airDistance > 40000 ? 25 : airDistance > 20000 ? 15 : 7.5)); // 90/54/27 km/h
	direction.avoidOption = query.avoidOption;
	direction.waypointsPolyline = query.waypointsPolyline;

	set.carDirections = @[ direction ];

	// Plane

	direction = [TKDirection new];
	direction.startLocation = query.startLocation;
	direction.endLocation = query.endLocation;
	direction.mode = TKDirectionTransportModePlane;
	direction.estimated = YES;
	direction.distance = set.airDistance;
	direction.duration = round(direction.distance / 250 + 40*60); // 900 km/h + 40 min dispatch
	direction.avoidOption = query.avoidOption;
	direction.waypointsPolyline = query.waypointsPolyline;

	set.planeDirections = @[ direction ];

	// Return

	return set;
}


#pragma mark - Helpers


- (NSString *)cacheKeyForQuery:(TKDirectionsQuery *)query
{
	NSMutableString *str = [[NSString stringWithFormat:@"%.5f,%.5f|%.5f,%.5f",
		query.startLocation.coordinate.latitude, query.startLocation.coordinate.longitude,
		query.endLocation.coordinate.latitude, query.endLocation.coordinate.longitude] mutableCopy];

	if (query.avoidOption)
		[str appendFormat:@"|A:%tu", query.avoidOption];

	if (query.waypointsPolyline)
		[str appendFormat:@"|P:%@", query.waypointsPolyline];

	return [str copy];
}

@end
