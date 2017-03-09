//
//  TKPlace.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKPlace.h"
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

//		_detail = [[TKPlaceDetail alloc] initFromResponse:dictionary];

		// Properties

		_tier = [dictionary[@"meta"][@"tier"] parsedNumber];
		_rating = [dictionary[@"rating"] parsedNumber];

		_price = [dictionary[@"price"][@"value"] parsedNumber];

//		_hasPhoto = [dictionary[@"photo_url"] parsedString] != nil;
		_duration = [dictionary[@"duration"] parsedNumber];

		// URLs
		NSArray *refData = [dictionary[@"references"] parsedArray];
		NSMutableArray *refs = [NSMutableArray arrayWithCapacity:refData.count];
		for (NSDictionary *dict in refData) {
			TKReference *ref = [[TKReference alloc] initFromResponse:dict forItemWithID:_ID];
			if (ref) [refs addObject:ref];
		}
		_references = refs;

		// Parents
		NSMutableArray *locationIDs = [NSMutableArray array];
		for (NSString *parentID in [dictionary[@"parent_guids"] parsedArray])
			if ([parentID parsedString]) [locationIDs addObject:parentID];
		// Back-compatibility
		if (!locationIDs.count)
			for (NSDictionary *r in [dictionary[@"parents"] parsedArray]) {
				if (![r parsedDictionary]) continue;
				NSString *locationID = [r[@"guid"] parsedString];
				if (locationID) [locationIDs addObject:locationID];
			}

		_parents = locationIDs;

		// Feature marker
		_marker = [dictionary[@"marker"] parsedString];
		if ([_marker isEqualToString:@"default"])
			_marker = nil;

		// Fetch possible categories and tags
		NSMutableOrderedSet *categories = [NSMutableOrderedSet orderedSetWithCapacity:4];
		NSMutableOrderedSet *tags = [NSMutableOrderedSet orderedSetWithCapacity:16];
		NSMutableOrderedSet *flags = [NSMutableOrderedSet orderedSetWithCapacity:4];

		for (NSString *str in [dictionary[@"categories"] parsedArray])
			if ([str parsedString]) [categories addObject:str];

		for (NSString *str in [dictionary[@"tags"] parsedArray])
			if ([str parsedString]) [tags addObject:str];

		if ([[dictionary[@"has_fodors_content"] parsedNumber] boolValue])
			[flags addObject:@"has_fodors_content"];

		if ([[dictionary[@"is_translated"] parsedNumber] boolValue])
			[flags addObject:@"is_translated"];

		if ([[dictionary[@"perex_provider"] parsedString] isEqualToString:@"wikipedia"])
			[categories addObject:@"wikipedia_perex"];

		_categories = [categories array];
		_tags = [tags array];
		_flags = [flags array];
    }

    return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<TKPlace: %p | ID: %@ | Name: %@>", self, _ID, _name];
}

@end


@implementation TKPlaceDetail



@end
