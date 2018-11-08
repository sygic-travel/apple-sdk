//
//  TKCollection.m
//  TravelKit
//
//  Created by Michal Zelinka on 01/11/18.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <TravelKit/TKCollection.h>
#import <TravelKit/TKPlace+Private.h>
#import <TravelKit/NSObject+Parsing.h>
#import <TravelKit/Foundation+TravelKit.h>

@implementation TKCollection

- (instancetype)initFromResponse:(NSDictionary *)dictionary
{
	if (self = [super init])
	{
		// Basic attributes
		_ID = [dictionary[@"id"] parsedNumber];
		_name = [dictionary[@"name_short"] parsedString];
		_fullName = [dictionary[@"name_long"] parsedString];
		_parentPlaceID = [dictionary[@"parent_place_id"] parsedString];

		_placeIDs = [[dictionary[@"place_ids"] parsedArray] mappedArrayUsingBlock:^id(id obj) {
			return [obj parsedString];
		}] ?: @[ ];

		if (_ID == nil || !_fullName || !_placeIDs.count || !_parentPlaceID) return nil;

		_perex = [dictionary[@"description"] parsedString];

		_tags = [[dictionary[@"tags"] parsedArray] mappedArrayUsingBlock:^id(id obj) {
			if (![obj parsedDictionary]) return nil;
			return [[TKPlaceTag alloc] initFromResponse:obj];
		  }] ?: @[ ];
	}

	return self;
}

- (BOOL)isEqual:(TKCollection *)object
{
	if (![object isKindOfClass:[TKCollection class]])
		return NO;

	return [_ID isEqual:object.ID];
}

@end
