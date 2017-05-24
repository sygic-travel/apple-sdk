//
//  TKMapRegion.m
//  TravelKit
//
//  Created by Michal Zelinka on 18/02/2016.
//  Copyright (c) 2016- Tripomatic. All rights reserved.
//

#import "TKMapRegion.h"


#pragma mark Map Region wrapper -


@implementation TKMapRegion

- (instancetype)init
{
	if (self = [super init])
		_coordinateRegion = MKCoordinateRegionMake(kCLLocationCoordinate2DInvalid, MKCoordinateSpanMake(0, 0));

	return self;
}

- (instancetype)initWithCoordinateRegion:(MKCoordinateRegion)region
{
	if (self = [super init])
		_coordinateRegion = region;

	return self;
}

- (instancetype)initWithSouthWestPoint:(CLLocation *)southWest northEastPoint:(CLLocation *)northEast
{
	if (self = [super init])
	{
		CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(
			(southWest.coordinate.latitude+northEast.coordinate.latitude)/2.0,
			(southWest.coordinate.longitude+northEast.coordinate.longitude)/2.0);
		MKCoordinateSpan span = MKCoordinateSpanMake(
			fabs(northEast.coordinate.latitude-southWest.coordinate.latitude),
			fabs(northEast.coordinate.longitude-southWest.coordinate.longitude));
		_coordinateRegion = MKCoordinateRegionMake(centerCoordinate, span);
	}

	return self;
}

- (CLLocation *)southWestPoint
{
	return [[CLLocation alloc] initWithLatitude:
			_coordinateRegion.center.latitude-_coordinateRegion.span.latitudeDelta/2.0
		longitude:
			_coordinateRegion.center.longitude-_coordinateRegion.span.longitudeDelta/2.0];
}

- (CLLocation *)northEastPoint
{
	return [[CLLocation alloc] initWithLatitude:
			_coordinateRegion.center.latitude+_coordinateRegion.span.latitudeDelta/2.0
		longitude:
			_coordinateRegion.center.longitude+_coordinateRegion.span.longitudeDelta/2.0];
}

- (BOOL)containsLocation:(CLLocation *)location
{
	if (!location) return NO;

	CLLocationCoordinate2D center = _coordinateRegion.center;
	MKCoordinateSpan span = _coordinateRegion.span;
	CLLocationCoordinate2D coord = location.coordinate;

	BOOL result = YES;
	result &= cos((center.latitude - coord.latitude)*M_PI/180.0) > cos(span.latitudeDelta/2.0*M_PI/180.0);
	result &= cos((center.longitude - coord.longitude)*M_PI/180.0) > cos(span.longitudeDelta/2.0*M_PI/180.0);
	return result;
}

- (BOOL)hasValidCoordinate
{
	return (CLLocationCoordinate2DIsValid(_coordinateRegion.center) &&
			_coordinateRegion.span.latitudeDelta != 0.0 &&
			_coordinateRegion.span.longitudeDelta != 0.0);
}

- (NSString *)description
{
	return [NSString stringWithFormat:
		@"<MapRegion %p @ [%.3f, %3f] {%.3f, %.3f}>", self,
		_coordinateRegion.center.latitude,
		_coordinateRegion.center.longitude,
		_coordinateRegion.span.latitudeDelta,
		_coordinateRegion.span.longitudeDelta];
}

@end
