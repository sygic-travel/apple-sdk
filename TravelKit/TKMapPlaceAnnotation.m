//
//  TKMapPlaceAnnotation.m
//  TravelKit
//
//  Created by Michal Zelinka on 03/05/2017.
//  Copyright (c) 2017- Tripomatic. All rights reserved.
//

#import "TKMapPlaceAnnotation.h"


#pragma mark Map Annotation wrapper -


@implementation TKMapPlaceAnnotation

- (instancetype)initWithPlace:(TKPlace *)place
{
	if (self = [super init])
	{
		_place = place;
		_title = [place.name copy];
		_location = place.location;
		_coordinate = place.location.coordinate;
		self.title = place.name;
		self.location = place.location;
	}

	return self;
}

- (void)setLocation:(CLLocation *)location
{
	_location = location;
	_coordinate = location.coordinate;
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate
{
	_coordinate = coordinate;
	_location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
}

@end
