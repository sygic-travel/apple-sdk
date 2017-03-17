//
//  TKPlace.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKPlace+Private.h"
#import "NSObject+Parsing.h"
#import "MapWorkers.h"


@implementation TKPlace

- (instancetype)initFromResponse:(NSDictionary *)dictionary
{
	if (self = [super init])
	{
		// Basic attributes
		_ID = [dictionary[@"guid"] parsedString];
		_name = [dictionary[@"name"] parsedString];
		_suffix = [dictionary[@"name_suffix"] parsedString];

		if (!_ID || !_name) return nil;

		_perex = [dictionary[@"perex"] parsedString];

		// Coordinates
		NSDictionary *location = [dictionary[@"location"] parsedDictionary];
		NSNumber *lat = [location[@"lat"] parsedNumber];
		NSNumber *lng = [location[@"lng"] parsedNumber];

		if (lat && lng) _location = [[CLLocation alloc]
			initWithLatitude:lat.doubleValue longitude:lng.doubleValue];

		_quadKey = [dictionary[@"quadkey"] parsedString];
		if (!_quadKey && _location)
			_quadKey = toQuadKey(_location.coordinate.latitude,
				_location.coordinate.longitude, 18);

		// Activity details
		if (dictionary[@"description"])
			_detail = [[TKPlaceDetail alloc] initFromResponse:dictionary];

		// Properties
		_rating = [dictionary[@"rating"] parsedNumber];
		_price = [dictionary[@"price"][@"value"] parsedNumber];
		_duration = [dictionary[@"duration"] parsedNumber];

		// Parents
		NSMutableArray *locationIDs = [NSMutableArray array];
		for (NSString *parentID in [dictionary[@"parent_guids"] parsedArray])
			if ([parentID parsedString]) [locationIDs addObject:parentID];
		_parents = locationIDs;

		// Feature marker
		_marker = [dictionary[@"marker"] parsedString];
		if ([_marker isEqualToString:@"default"])
			_marker = nil;

		// Fetch possible categories, tags and flags
		NSMutableOrderedSet<NSString *> *categories = [NSMutableOrderedSet orderedSetWithCapacity:4];
		NSMutableOrderedSet<NSString *> *flags = [NSMutableOrderedSet orderedSetWithCapacity:4];

		for (NSString *str in [dictionary[@"categories"] parsedArray])
			if ([str parsedString]) [categories addObject:str];

		if ([[dictionary[@"description"][@"is_translated"] parsedNumber] boolValue])
			[flags addObject:@"translated_description"];

		if ([[dictionary[@"description"][@"provider"] parsedString] isEqualToString:@"wikipedia"])
			[flags addObject:@"wikipedia_description"];

		_categories = [categories array];
		_flags = [flags array];
    }

    return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<TKPlace: %p | ID: %@ | Name: %@>", self, _ID, _name];
}

@end


@implementation TKPlaceTag

- (instancetype)initFromResponse:(NSDictionary *)response
{
	if (self = [super init])
	{
		_key = [response[@"key"] parsedString];
		_name = [response[@"name"] parsedString];

		if (!_key) return nil;
	}

	return self;
}

@end


@implementation TKPlaceDetail

- (instancetype)initFromResponse:(NSDictionary *)response
{
	if (self = [super init])
	{
		// Tags
		NSMutableOrderedSet<TKPlaceTag *> *tags = [NSMutableOrderedSet orderedSetWithCapacity:16];

		TKPlaceTag *tag;
		for (NSDictionary *tagDict in [response[@"tags"] parsedArray])
			if ((tag = [[TKPlaceTag alloc] initFromResponse:tagDict]))
				[tags addObject:tag];
		_tags = [tags array];

		// References
		NSArray *refData = [response[@"references"] parsedArray];
		NSMutableArray *refs = [NSMutableArray arrayWithCapacity:refData.count];
		for (NSDictionary *dict in refData) {
			TKReference *ref = [[TKReference alloc] initFromResponse:dict];
			if (ref) [refs addObject:ref];
		}
		_references = refs;

		// Other properties
		_fullDescription = [response[@"description"][@"text"] parsedString];
		_address = [response[@"address"] parsedString];
		_phone = [response[@"phone"] parsedString];
		_email = [response[@"email"] parsedString];
		_duration = [response[@"duration"] parsedNumber];
		_openingHours = [response[@"opening_hours"] parsedString];
		_admission = [response[@"admission"] parsedString];
	}

	return self;
}

@end
