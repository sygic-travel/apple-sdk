//
//  TKPlace.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <TravelKit/Foundation+TravelKit.h>
#import <TravelKit/NSObject+Parsing.h>
#import <TravelKit/TKMapWorker.h>

#import "TKPlace+Private.h"
#import "TKMedium+Private.h"
#import "TKReference+Private.h"


@implementation TKPlace

+ (NSDictionary<NSNumber *, NSString *> *)categorySlugs
{
	static NSDictionary<NSNumber *, NSString *> *slugs = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		slugs = @{
			@(TKPlaceCategorySightseeing): @"sightseeing",
			@(TKPlaceCategoryShopping): @"shopping",
			@(TKPlaceCategoryEating): @"eating",
			@(TKPlaceCategoryDiscovering): @"discovering",
			@(TKPlaceCategoryPlaying): @"playing",
			@(TKPlaceCategoryTraveling): @"traveling",
			@(TKPlaceCategoryGoingOut): @"going_out",
			@(TKPlaceCategoryHiking): @"hiking",
			@(TKPlaceCategoryDoingSports): @"doing_sports",
			@(TKPlaceCategoryRelaxing): @"relaxing",
			@(TKPlaceCategorySleeping): @"sleeping",
		};
	});

	return slugs;
}

+ (NSDictionary<NSNumber *, NSString *> *)levelStrings
{
	static NSDictionary<NSNumber *, NSString *> *levels = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		levels = @{
			@(TKPlaceLevelPOI): @"poi",
			@(TKPlaceLevelNeighbourhood): @"neighbourhood",
			@(TKPlaceLevelLocality): @"locality",
			@(TKPlaceLevelSettlement): @"settlement",
			@(TKPlaceLevelVillage): @"village",
			@(TKPlaceLevelTown): @"town",
			@(TKPlaceLevelCity): @"city",
			@(TKPlaceLevelCounty): @"county",
			@(TKPlaceLevelRegion): @"region",
			@(TKPlaceLevelIsland): @"island",
			@(TKPlaceLevelArchipelago): @"archipelago",
			@(TKPlaceLevelState): @"state",
			@(TKPlaceLevelCountry): @"country",
			@(TKPlaceLevelContinent): @"continent",
		};
	});

	return levels;
}

+ (TKPlaceLevel)levelFromString:(NSString *)str
{
	NSDictionary *levels = [self levelStrings];

	if (str)
		for (NSNumber *key in levels.allKeys)
			if ([levels[key] isEqual:str])
				return key.unsignedIntegerValue;

	return TKPlaceLevelUnknown;
}

+ (TKPlaceCategory)categoriesFromSlugArray:(NSArray<NSString *> *)categories
{
	TKPlaceCategory __block res = TKPlaceCategoryNone;

	NSDictionary<NSNumber *, NSString *> *slugs = [self categorySlugs];

	[slugs enumerateKeysAndObjectsUsingBlock:^(NSNumber *cat, NSString *slug, BOOL *__unused stop) {
		if ([categories containsObject:slug])
			res |= cat.unsignedIntegerValue;
	}];

	return res;
}

- (instancetype)initFromResponse:(NSDictionary *)dictionary
{
	NSString *ID = [dictionary[@"id"] parsedString];
	NSString *name = [dictionary[@"name"] parsedString];

	if (!ID || !name) return nil;

	if (self = [super init])
	{
		// Basic attributes
		_ID = ID;
		_name = name;
		_suffix = [dictionary[@"name_suffix"] parsedString];

		// Coordinates
		NSDictionary *location = [dictionary[@"location"] parsedDictionary];
		NSNumber *lat = [location[@"lat"] parsedNumber];
		NSNumber *lng = [location[@"lng"] parsedNumber];

		if (lat != nil && lng != nil) _location = [[CLLocation alloc]
			initWithLatitude:lat.doubleValue longitude:lng.doubleValue];

		if (!_ID || !_name || !_location) return nil;

		_perex = [dictionary[@"perex"] parsedString];

		NSString *level = [dictionary[@"level"] parsedString];
		_level = [[self class] levelFromString:level];

		NSString *thumbnail = [dictionary[@"thumbnail_url"] parsedString];
		if (thumbnail) {
			NSURL *thumbURL = [NSURL URLWithString:thumbnail];
			if (thumbURL) _thumbnailURL = thumbURL;
		}

		_quadKey = [dictionary[@"quadkey"] parsedString];
		if (!_quadKey && _location)
			_quadKey = [TKMapWorker quadKeyForCoordinate:_location.coordinate detailLevel:18];

		// Bounding box
		if ((location = [dictionary[@"bounding_box"] parsedDictionary]))
		{
			lat = [location[@"south"] parsedNumber];
			lng = [location[@"west"] parsedNumber];
			CLLocation *southWest = (lat != nil && lng != nil) ? [[CLLocation alloc]
				initWithLatitude:lat.doubleValue longitude:lng.doubleValue] : nil;
			lat = [location[@"north"] parsedNumber];
			lng = [location[@"east"] parsedNumber];
			CLLocation *northEast = (lat != nil && lng != nil) ? [[CLLocation alloc]
				initWithLatitude:lat.doubleValue longitude:lng.doubleValue] : nil;
			if (southWest && northEast)
				_boundingBox = [[TKMapRegion alloc]
					initWithSouthWestPoint:southWest northEastPoint:northEast];
		}

		// Properties
		_rating = [dictionary[@"rating"] parsedNumber];

		// Parents
		NSString *parentID = nil;
		NSMutableArray *locationIDs = [NSMutableArray array];
		for (NSString *parentDict in [dictionary[@"parents"] parsedArray])
			if ((parentID = [parentDict[@"id"] parsedString]))
				[locationIDs addObject:parentID];
		_parents = locationIDs;

		// Feature marker
		_kind = [dictionary[@"class"][@"name"] parsedString];
 		_marker = [dictionary[@"class"][@"slug"] parsedString];
		if ([_marker isEqualToString:@"default"])
			_marker = nil;

		// Fetch possible categories, tags and flags
		NSMutableOrderedSet<NSString *> *flags = [NSMutableOrderedSet orderedSetWithCapacity:4];

		_categories = [[self class] categoriesFromSlugArray:[dictionary[@"categories"] parsedArray]];

		if ([[dictionary[@"description"][@"provider"] parsedString] isEqualToString:@"wikipedia"])
			[flags addObject:@"wikipedia_description"];

		if ([[dictionary[@"has_shape_geometry"] parsedNumber] boolValue])
			[flags addObject:@"has_geometry"];

		_flags = [flags array];
	}

	return self;
}

- (NSUInteger)displayableHexColor
{
	TKPlaceCategory cat = _categories;

	if (cat & TKPlaceCategorySightseeing) return 0xF6746C;
	if (cat & TKPlaceCategoryShopping)    return 0xE7A41C;
	if (cat & TKPlaceCategoryEating)      return 0xF6936C;
	if (cat & TKPlaceCategoryDiscovering) return 0x898F9A;
	if (cat & TKPlaceCategoryPlaying)     return 0x6CD8F6;
	if (cat & TKPlaceCategoryTraveling)   return 0x6B91F6;
	if (cat & TKPlaceCategoryGoingOut)    return 0xE76CA0;
	if (cat & TKPlaceCategoryHiking)      return 0xD59B6B;
	if (cat & TKPlaceCategoryDoingSports) return 0x68B277;
	if (cat & TKPlaceCategoryRelaxing)    return 0xA06CF6;
	if (cat & TKPlaceCategorySleeping)    return 0xA4CB69;

	return 0x999999;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<TKPlace: %p | ID: %@ | Name: %@>", self, _ID, _name];
}

@end


@implementation TKDetailedPlace

- (instancetype)initFromResponse:(NSDictionary *)dictionary
{
	if (self = [super initFromResponse:dictionary])
	{
		// Place detail
		if (dictionary[@"description"])
			_detail = [[TKPlaceDetail alloc] initFromResponse:dictionary];
	}

	return self;
}

@end


@implementation TKPlaceDescription

- (instancetype)initFromResponse:(NSDictionary *)response
{
	NSString *text = [response[@"text"] parsedString];

	if (!text) return nil;

	if (self = [super init])
	{
		_text = text;
		_languageID = [response[@"language_id"] parsedString];

		NSString *provider = [response[@"provider"] parsedString];
		if ([provider isEqualToString:@"wikipedia"])
			_provider = TKPlaceDescriptionProviderWikipedia;
		else if ([provider isEqualToString:@"wikivoyage"])
			_provider = TKPlaceDescriptionProviderWikivoyage;
		else if ([provider isEqualToString:@"booking.com"])
			_provider = TKPlaceDescriptionProviderBookingCom;

		NSString *source = [response[@"link"] parsedString];
		if (source) _sourceURL = [NSURL URLWithString:source];

		provider = [response[@"translation_provider"] parsedString];
		if ([provider isEqualToString:@"google"])
			_translationProvider = TKTranslationProviderGoogle;
		else if ([provider isEqualToString:@"bing"])
			_translationProvider = TKTranslationProviderBing;
	}

	return self;
}

@end


@implementation TKPlaceTag

- (instancetype)initFromResponse:(NSDictionary *)response
{
	NSString *key = [response[@"key"] parsedString];

	if (!key) return nil;

	if (self = [super init])
	{
		_key = key;
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
		// Names
		_localName = [response[@"name_local"] parsedString];
		_translatedName = [response[@"name_translated"] parsedString];
		_englishName = [response[@"name_en"] parsedString];

		// Timezone
		_timezone = [response[@"timezone"] parsedString];

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

		NSDictionary *description = [response[@"description"] parsedDictionary];
		if (description) _fullDescription = [[TKPlaceDescription alloc] initFromResponse:description];

		_address = [response[@"address"] parsedString];
		_phone = [response[@"phone"] parsedString];
		_email = [response[@"email"] parsedString];
		_duration = [response[@"duration_estimate"] parsedNumber];
		_openingHours = [response[@"opening_hours_raw"] parsedString];
		_openingHoursNote = [response[@"opening_hours_note"] parsedString];
		_admission = [response[@"admission"] parsedString];

		NSDictionary *attributes = [response[@"attributes"] parsedDictionary];
 		Class attributesClass = [NSString class];

 		_attributes = [attributes filteredDictionaryUsingBlock:^BOOL(id key, id value) {
 			return [key isKindOfClass:attributesClass] && [value isKindOfClass:attributesClass];
 		}];
	}

	return self;
}

@end
