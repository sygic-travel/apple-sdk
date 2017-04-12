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

+ (NSArray<NSString *> *)supportedCategories
{
	static NSArray *categories = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		categories = @[
			@"sightseeing", @"shopping", @"eating", @"discovering", @"playing",
			@"traveling", @"going_out", @"hiking", @"sports", @"relaxing",
			@"sleeping",
		];
	});

	return categories;
}

+ (TKPlaceLevel)levelFromString:(NSString *)str
{
	str = str ?: @"";

	static NSDictionary<NSString *, NSNumber *> *levels = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		levels = @{
			@"poi": @(TKPlaceLevelPOI),
			@"neighbourhood": @(TKPlaceLevelNeighbourhood),
			@"locality": @(TKPlaceLevelLocality),
			@"settlement": @(TKPlaceLevelSettlement),
			@"village": @(TKPlaceLevelVillage),
			@"town": @(TKPlaceLevelTown),
			@"city": @(TKPlaceLevelCity),
			@"county": @(TKPlaceLevelCounty),
			@"region": @(TKPlaceLevelRegion),
			@"island": @(TKPlaceLevelIsland),
			@"archipelago": @(TKPlaceLevelArchipelago),
			@"state": @(TKPlaceLevelState),
			@"country": @(TKPlaceLevelCountry),
			@"continent": @(TKPlaceLevelContinent),
		};
	});

	return [levels[str] unsignedIntegerValue];
}

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
		_level = [TKPlace levelFromString:[dictionary[@"level"] parsedString]];

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

		// Bounding box
		if ((location = [dictionary[@"bounding_box"] parsedDictionary]))
		{
			lat = [dictionary[@"south"] parsedNumber];
			lng = [dictionary[@"west"] parsedNumber];
			CLLocation *southWest = (lat && lng) ? [[CLLocation alloc]
				initWithLatitude:lat.doubleValue longitude:lng.doubleValue] : nil;
			lat = [dictionary[@"north"] parsedNumber];
			lng = [dictionary[@"east"] parsedNumber];
			CLLocation *northEast = (lat && lng) ? [[CLLocation alloc]
				initWithLatitude:lat.doubleValue longitude:lng.doubleValue] : nil;
			_boundingBox = [[TKMapRegion alloc] initWithSouthWestPoint:southWest northEastPoint:northEast];
		}

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

- (NSArray<NSString *> *)displayableCategories
{
	NSMutableArray<NSString *> *ret = [NSMutableArray arrayWithCapacity:_categories.count];

	for (NSString *slug in _categories)
	{
		NSString *s = [self displayNameForSlug:slug];
		if (s) [ret addObject:s];
	}

	return ret;
}

- (NSString *)displayNameForSlug:(NSString *)slug
{
	NSDictionary *displayNames = @{
		@"sightseeing": NSLocalizedString(@"Sightseeing", @"Menu entry"),
		@"shopping": NSLocalizedString(@"Shopping", @"Menu entry"),
		@"eating": NSLocalizedString(@"Restaurants", @"Menu entry"),
		@"discovering": NSLocalizedString(@"Museums", @"Menu entry"),
		@"playing": NSLocalizedString(@"Family", @"Menu entry"),
		@"traveling": NSLocalizedString(@"Transport", @"Menu entry"),
		@"going_out": NSLocalizedString(@"Nightlife", @"Menu entry"),
		@"hiking": NSLocalizedString(@"Outdoors", @"Menu entry"),
		@"sports": NSLocalizedString(@"Sports", @"Menu entry"),
		@"relaxing": NSLocalizedString(@"Relaxation", @"Menu entry"),
		@"sleeping": NSLocalizedString(@"Accommodation", @"Menu entry"),
	};

	return displayNames[slug];
}

- (NSUInteger)displayableHexColor
{
	NSString *firstCategory = _categories.firstObject;

	if ([firstCategory isEqual:@"sightseeing"]) return 0xF6746C;
	if ([firstCategory isEqual:@"shopping"])    return 0xE7A41C;
	if ([firstCategory isEqual:@"eating"])      return 0xF6936C;
	if ([firstCategory isEqual:@"discovering"]) return 0x898F9A;
	if ([firstCategory isEqual:@"playing"])     return 0x6CD8F6;
	if ([firstCategory isEqual:@"traveling"])   return 0x6B91F6;
	if ([firstCategory isEqual:@"going_out"])   return 0xE76CA0;
	if ([firstCategory isEqual:@"hiking"])      return 0xD59B6B;
	if ([firstCategory isEqual:@"sports"])      return 0x68B277;
	if ([firstCategory isEqual:@"relaxing"])    return 0xA06CF6;
	if ([firstCategory isEqual:@"sleeping"])    return 0xA4CB69;

	return 0x999999;
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
		NSArray *arr = [response[@"references"] parsedArray];
		NSMutableArray *refs = [NSMutableArray arrayWithCapacity:arr.count];
		for (NSDictionary *dict in arr) {
			TKReference *ref = [[TKReference alloc] initFromResponse:dict];
			if (ref) [refs addObject:ref];
		}
		_references = refs;

		// Main media

		arr = [response[@"main_media"][@"media"] parsedArray];
		NSMutableArray *media = [NSMutableArray arrayWithCapacity:arr.count];
		for (NSDictionary *dict in arr) {
			TKMedium *medium = [[TKMedium alloc] initFromResponse:dict];
			if (medium) [media addObject:medium];
		}
		_mainMedia = media;

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
