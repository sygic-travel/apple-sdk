//
//  TKDirection.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/01/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import "TKDirection+Private.h"
#import "TKMapWorker.h"
#import "NSDate+Tripomatic.h"
#import "NSObject+Parsing.h"
#import "Foundation+TravelKit.h"


/////////////////////////////////
/////////////////////////////////

#pragma mark - Directions query

/////////////////////////////////
/////////////////////////////////


@implementation TKDirectionsQuery

- (nullable instancetype)initFromLocation:(CLLocation *)sourceLocation toLocation:(CLLocation *)destinationLocation
{
	if (!sourceLocation || !destinationLocation) return nil;

	if (self = [super init])
	{
		_mode = TKDirectionModeDefault;
		_sourceLocation = sourceLocation;
		_destinationLocation = destinationLocation;
	}

	return self;
}

+ (nullable instancetype)queryFromLocation:(CLLocation *)sourceLocation toLocation:(CLLocation *)destinationLocation
{
	return [[self alloc] initFromLocation:sourceLocation toLocation:destinationLocation];
}

- (NSString *)cacheKey
{
	NSMutableString *str = [[NSString stringWithFormat:@"%.5f,%.5f;%.5f,%.5f",
		_sourceLocation.coordinate.latitude, _sourceLocation.coordinate.longitude,
		_destinationLocation.coordinate.latitude, _destinationLocation.coordinate.longitude] mutableCopy];

	NSDate *date = nil;

	if ((date = _relativeDepartureDate))
		[str appendFormat:@"|Depart:%@", [[NSDateFormatter
			shared8601RelativeDateTimeFormatter] stringFromDate:date]];

	if ((date = _relativeArrivalDate))
		[str appendFormat:@"|Arrive:%@", [[NSDateFormatter
			shared8601RelativeDateTimeFormatter] stringFromDate:date]];

	if (_avoidOption)
		[str appendFormat:@"|Avoid:%tu", _avoidOption];

	NSArray<CLLocation *> *waypoints = _waypoints;

	if (waypoints.count)
		[str appendFormat:@"|Poly:%@", [TKMapWorker polylineFromPoints:waypoints]];

	return [str copy];
}

@end


/////////////////////////////////
/////////////////////////////////

#pragma mark - Directions set

/////////////////////////////////
/////////////////////////////////


@implementation TKDirectionsSet

- (instancetype)initFromDictionary:(NSDictionary *)dictionary
{
	if (self = [super init])
	{
		NSNumber *lat = [dictionary[@"origin"][@"lat"] parsedNumber];
		NSNumber *lng = [dictionary[@"origin"][@"lng"] parsedNumber];
		if (lat != nil && lng != nil) _sourceLocation = [[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lng.doubleValue];
		lat = [dictionary[@"destination"][@"lat"] parsedNumber];
		lng = [dictionary[@"destination"][@"lng"] parsedNumber];
		if (lat != nil && lng != nil) _destinationLocation = [[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lng.doubleValue];

		if (!_sourceLocation || !_destinationLocation)
			return nil;

		_directions = [[dictionary[@"directions"] parsedArray]
		  mappedArrayUsingBlock:^TKDirection *(NSDictionary *dict) {
			TKDirection *variant = [[TKDirection alloc] initFromDictionary:dict];
			if (!_idealDirection)
				_idealDirection = variant;
			if (variant.mode == TKDirectionModeWalk && !_idealWalkDirection)
				_idealWalkDirection = variant;
			if (variant.mode == TKDirectionModeCar && !_idealCarDirection)
				_idealCarDirection = variant;
			if (variant.mode == TKDirectionModePublicTransport && !_idealPublicTransportDirection)
				_idealPublicTransportDirection = variant;
			return variant;
		}] ?: @[ ];
	}

	return self;
}

@end


/////////////////////////////////
/////////////////////////////////

#pragma mark - Direction variant

/////////////////////////////////
/////////////////////////////////


@implementation TKDirection

- (instancetype)initFromDictionary:(NSDictionary *)dictionary
{
	if (self = [super init])
	{
		_distance = [[dictionary[@"distance"] parsedNumber] doubleValue];
		_duration = [[dictionary[@"duration"] parsedNumber] doubleValue];

		NSString *mode = [dictionary[@"mode"] parsedString];

		NSDictionary<NSString *, NSNumber *> *modes = @{
			@"pedestrian": @(TKDirectionModeWalk),
			@"car": @(TKDirectionModeCar),
			@"public_transit": @(TKDirectionModePublicTransport),
		};
		_mode = modes[mode].unsignedIntegerValue;

		_steps = [[dictionary[@"legs"] parsedArray]
		  mappedArrayUsingBlock:^TKDirectionStep *(NSDictionary *leg) {
			return [[TKDirectionStep alloc] initFromDictionary:leg];
		}] ?: @[ ];

		_source = [dictionary[@"source"] parsedString];
		_routeID = [dictionary[@"route_id"] parsedString];
	}

	return self;
}

- (NSString *)calculatedPolyline
{
	NSMutableArray<CLLocation *> *coords = [NSMutableArray arrayWithCapacity:_steps.count+1];

	for (TKDirectionStep *step in _steps)
	{
		NSString *polyline = step.polyline;

		if (polyline) {
			NSArray<CLLocation *> *points = [TKMapWorker pointsFromPolyline:polyline] ?: @[ ];
			[coords addObjectsFromArray:points];
		} else {
			CLLocation *loc = nil;
			if (step == _steps.firstObject)
				if ((loc = step.originLocation))
					[coords addObject:loc];
			if ((loc = step.destinationLocation))
				[coords addObject:loc];
		}
	}

	return [TKMapWorker polylineFromPoints:coords];
}

@end


/////////////////////////////////
/////////////////////////////////

#pragma mark - Direction step

/////////////////////////////////
/////////////////////////////////


@implementation TKDirectionStep

- (instancetype)initFromDictionary:(NSDictionary *)dictionary
{
	if (self = [super init])
	{
		_distance = [[dictionary[@"distance"] parsedNumber] doubleValue];
		_duration = [[dictionary[@"duration"] parsedNumber] doubleValue];

		NSString *mode = [dictionary[@"mode"] parsedString];

		NSDictionary<NSString *, NSNumber *> *modes = @{
			@"bike": @(TKDirectionStepModeBike),
			@"boat": @(TKDirectionStepModeBoat),
			@"bus": @(TKDirectionStepModeBus),
			@"car": @(TKDirectionStepModeCar),
			@"funicular": @(TKDirectionStepModeFunicular),
			@"pedestrian": @(TKDirectionStepModePedestrian),
			@"plane": @(TKDirectionStepModePlane),
			@"subway": @(TKDirectionStepModeSubway),
			@"taxi": @(TKDirectionStepModeTaxi),
			@"train": @(TKDirectionStepModeTrain),
			@"tram": @(TKDirectionStepModeTram),
		};
		_mode = modes[mode].unsignedIntegerValue;

		_polyline = [dictionary[@"polyline"] parsedString];

		_originName = [dictionary[@"origin"][@"name"] parsedString];
		NSNumber *lat = [dictionary[@"origin"][@"location"][@"lat"] parsedNumber];
		NSNumber *lng = [dictionary[@"origin"][@"location"][@"lng"] parsedNumber];
		if (lat != nil && lng != nil) _originLocation = [[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lng.doubleValue];

		_destinationName = [dictionary[@"destination"][@"name"] parsedString];
		lat = [dictionary[@"destination"][@"location"][@"lat"] parsedNumber];
		lng = [dictionary[@"destination"][@"location"][@"lng"] parsedNumber];
		if (lat != nil && lng != nil) _destinationLocation = [[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lng.doubleValue];

		_headsign = [dictionary[@"display_info"][@"headsign"] parsedString];
		_shortName = [dictionary[@"display_info"][@"name_short"] parsedString];
		_longName = [dictionary[@"display_info"][@"name_long"] parsedString];

		NSString *color = [[dictionary[@"display_info"][@"line_color"] parsedString] uppercaseString];
		if (color) {
			unsigned result = 0;
			NSScanner *scanner = [NSScanner scannerWithString:color];
			[scanner setScanLocation:1];
			[scanner scanHexInt:&result];
			if (result == 0xFFFFFF) result = 0xEDEDED;
			_lineColor = @(result);
		}

		_displayMode = [dictionary[@"display_info"][@"display_mode"] parsedString];
		_attribution = [dictionary[@"attribution"][@"name"] parsedString];

		NSDateFormatter *dateFormatter = [NSDateFormatter shared8601DateTimeFormatter];

		id dateString = [dictionary[@"start_time"][@"datetime"] parsedString];
		if (dateString) _departureDate = [dateFormatter dateFromString:dateString];
		_departureLocalString = [dictionary[@"start_time"][@"datetime_local"] parsedString];

		dateString = [dictionary[@"end_time"][@"datetime"] parsedString];
		if (dateString) _arrivalDate = [dateFormatter dateFromString:dateString];
		_arrivalLocalString = [dictionary[@"end_time"][@"datetime_local"] parsedString];

		_intermediateStops = [[dictionary[@"intermediate_stops"] parsedArray]
		  mappedArrayUsingBlock:^TKDirectionIntermediateStop *(NSDictionary *stopDict) {
			return [[TKDirectionIntermediateStop alloc] initFromDictionary:stopDict];
		}] ?: @[ ];
	}

	return self;
}

@end


/////////////////////////////////
/////////////////////////////////

#pragma mark - Direction intermediate stop

/////////////////////////////////
/////////////////////////////////


@implementation TKDirectionIntermediateStop

- (instancetype)initFromDictionary:(NSDictionary *)dictionary
{
	if (self = [super init])
	{
		_name = [dictionary[@"name"] parsedString];

		NSNumber *lat = [dictionary[@"location"][@"lat"] parsedNumber];
		NSNumber *lng = [dictionary[@"location"][@"lng"] parsedNumber];
		if (lat == nil || lng == nil) return nil;
		_location = [[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lng.doubleValue];

		NSDateFormatter *dateFormatter = [NSDateFormatter shared8601DateTimeFormatter];

		id dateString = [dictionary[@"arrival_at"][@"datetime"] parsedString];
		if (dateString) _arrivalDate = [dateFormatter dateFromString:dateString];
		_arrivalLocalString = [dictionary[@"arrival_at"][@"datetime_local"] parsedString];

		dateString = [dictionary[@"departure_at"][@"datetime"] parsedString];
		if (dateString) _departureDate = [dateFormatter dateFromString:dateString];
		_departureLocalString = [dictionary[@"departure_at"][@"datetime_local"] parsedString];
	}

	return self;
}

@end


/////////////////////////////////
/////////////////////////////////

#pragma mark - Estimate Directions info

/////////////////////////////////
/////////////////////////////////


@implementation TKEstimateDirectionsInfo : NSObject

- (nullable instancetype)initFromLocation:(CLLocation *)sourceLocation toLocation:(CLLocation *)destinationLocation
{
	if (!sourceLocation || !destinationLocation) return nil;

	if (self = [super init])
	{
		_sourceLocation = sourceLocation;
		_destinationLocation = destinationLocation;

		[self recalculate];
	}

	return self;
}

+ (nullable instancetype)infoFromLocation:(CLLocation *)sourceLocation toLocation:(CLLocation *)destinationLocation
{
	return [[self alloc] initFromLocation:sourceLocation toLocation:destinationLocation];
}

- (nullable instancetype)initForQuery:(TKDirectionsQuery *)query
{
	if (!query.sourceLocation || !query.destinationLocation) return nil;

	if (self = [super init])
	{
		_sourceLocation = query.sourceLocation;
		_destinationLocation = query.destinationLocation;
		_avoidOption = query.avoidOption;
		_waypoints = query.waypoints;

		[self recalculate];
	}

	return self;
}

+ (nullable instancetype)infoForQuery:(TKDirectionsQuery *)query
{
	return [[self alloc] initForQuery:query];
}

- (void)recalculate
{
	CLLocationDistance airDistance = [_destinationLocation distanceFromLocation:_sourceLocation];

	if (_waypoints.count) {
		airDistance = 0;
		NSMutableArray<CLLocation *> *waypoints = [_waypoints mutableCopy];
		[waypoints insertObject:_sourceLocation atIndex:0];
		[waypoints addObject:_destinationLocation];
		CLLocation *prev = nil;
		for (CLLocation *wp in waypoints) {
			if (prev) airDistance += [wp distanceFromLocation:prev];
			prev = wp;
		}
	}

	_airDistance = airDistance;

	_walkDistance = round(airDistance * (airDistance <= 2000 ? 1.35 : airDistance <= 6000 ? 1.22 : 1.106));
	_bikeDistance = round(_walkDistance * 1.1);
	_carDistance = round(airDistance * (airDistance <= 2000 ? 1.8 : airDistance <= 6000 ? 1.6 : 1.2));
	_flyDistance = round(airDistance);
	_walkDuration = round(_walkDistance / 1.35); // 4.8 km/h
	_bikeDuration = round(_bikeDistance / 3.35); // 12 km/h
	_carDuration = round(_carDistance / (airDistance > 40000 ? 25 : airDistance > 20000 ? 15 : 7.5)); // 90/54/27 km/h
	_flyDuration = round(40*60 + _flyDistance / 250); // 900 km/h + 40 min

	// TODO: ~Apply waypoints~, new multiplying constants for 'avoid' options?
}

@end
