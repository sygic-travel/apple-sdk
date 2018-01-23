//
//  TKDirectionDefinitions.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/01/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import "TKDirectionDefinitions.h"


/////////////////////////////////
/////////////////////////////////

#pragma mark - Direction query

/////////////////////////////////
/////////////////////////////////


@implementation TKDirectionsQuery

- (instancetype)initFromLocation:(CLLocation *)startLocation toLocation:(CLLocation *)endLocation
{
	if (self = [super init])
	{
		_startLocation = startLocation;
		_endLocation = endLocation;
	}

	return self;
}

+ (instancetype)queryFromLocation:(CLLocation *)startLocation toLocation:(CLLocation *)endLocation
{
	if (!startLocation || !endLocation) return nil;

	return [[self alloc] initFromLocation:startLocation toLocation:endLocation];
}

@end


/////////////////////////////////
/////////////////////////////////

#pragma mark - Directions set

/////////////////////////////////
/////////////////////////////////


@implementation TKDirectionsSet

- (NSString *)description
{
	return [NSString stringWithFormat:
			@"<TKDirectionsSet %p>\n%@%@%@\n",
			self, _pedestrianDirections, _carDirections, _planeDirections];
}

@end


/////////////////////////////////
/////////////////////////////////

#pragma mark - Direction record

/////////////////////////////////
/////////////////////////////////


@implementation TKDirection

- (NSString *)description
{
	return [NSString stringWithFormat:
			@"<TKDirection %p | Mode %tu | Time: %.0f min | Distance: %.0f m>",
			self, _mode, round(_duration/60.0), round(_distance)];
}

//- (CLLocationDistance)idealDistance
//{
//	if (_walkDistance < kTKDistanceIdealWalkLimit) return _walkDistance;
//	if (_carDistance < kTKDistanceIdealCarLimit) return _carDistance;
//	return _flyDistance;
//}
//
//- (NSTimeInterval)idealTime
//{
//	if (_walkDistance < kTKDistanceIdealWalkLimit) return _walkTime;
//	if (_carDistance < kTKDistanceIdealCarLimit) return _carTime;
//	return _flyTime;
//}
//
//- (NSString *)idealPolyline
//{
//	if (_walkPolyline && _walkDistance < kTKDistanceIdealWalkLimit) return _walkPolyline;
//	if (_carPolyline && _carDistance < kTKDistanceIdealCarLimit) return _carPolyline;
//	return _flyPolyline;
//}
//
//- (TKDirectionTransportMode)idealType
//{
//	if (_walkDistance < kTKDistanceIdealWalkLimit) return TKDirectionTransportModePedestrian;
//	if (_carDistance < kTKDistanceIdealCarLimit) return TKDirectionTransportModeCar;
//	return TKDirectionTransportModePlane;
//}
//
//- (CLLocationDistance)distanceForType:(TKDirectionTransportMode)type
//{
//	switch (type) {
//		case TKDirectionTransportModePedestrian:
//			return  _walkDistance;
//		case TKDirectionTransportModeCar:
//			return _carDistance;
//		case TKDirectionTransportModePlane:
//			return _flyDistance;
//		default:
//			return [self idealDistance];
//	}
//}

//- (NSTimeInterval)timeForType:(TKDirectionTransportMode)type
//{
//	switch (type) {
//		case TKDirectionTransportModePedestrian:
//			return _walkTime;
//		case TKDirectionTransportModeCar:
//			return _carTime;
//		case TKDirectionTransportModePlane:
//			return _flyTime;
//		default:
//			return [self idealTime];
//	}
//}
//
//- (NSString *)polylineForType:(TKDirectionTransportMode)type
//{
//	switch (type) {
//		case TKDirectionTransportModePedestrian:
//			return  _walkPolyline;
//		case TKDirectionTransportModeCar:
//			return _carPolyline;
//		case TKDirectionTransportModePlane:
//			return _flyPolyline;
//		default:
//			return [self idealPolyline];
//	}
//}
//
//- (NSArray<NSNumber *> *)possibleTypes
//{
//	NSMutableArray *types = [NSMutableArray arrayWithCapacity:3];
//
//	if (_walkDistance <= kTKDistanceMaxWalkLimit) [types addObject:@(TKDirectionTransportModePedestrian)];
//	if (_carDistance <= kTKDistanceMaxCarLimit) [types addObject:@(TKDirectionTransportModeCar)];
//	if (_flyDistance > kTKDistanceMinFlightLimit) [types addObject:@(TKDirectionTransportModePlane)];
//
//	return types;
//}
//
//- (CLLocation *)startLocation
//{
//	NSString *coordString = [[_coordKey componentsSeparatedByString:@"|"] firstObject];
//	NSArray *coords = [coordString componentsSeparatedByString:@","];
//	NSString *latStr = coords.firstObject;
//	NSString *lngStr = coords.lastObject;
//	if (!latStr || !lngStr) return nil;
//	return [[CLLocation alloc] initWithLatitude:latStr.doubleValue longitude:lngStr.doubleValue];
//}
//
//- (CLLocation *)endLocation
//{
//	NSString *coordString = [[_coordKey componentsSeparatedByString:@"|"] lastObject];
//	NSArray *coords = [coordString componentsSeparatedByString:@","];
//	NSString *latStr = coords.firstObject;
//	NSString *lngStr = coords.lastObject;
//	if (!latStr || !lngStr) return nil;
//	return [[CLLocation alloc] initWithLatitude:latStr.doubleValue longitude:lngStr.doubleValue];
//}

@end
