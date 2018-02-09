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

@end
