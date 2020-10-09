//
//  TKCollection.m
//  TravelKit
//
//  Created by Michal Zelinka on 01/11/18.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <TravelKit/Foundation+TravelKit.h>
#import <TravelKit/NSObject+Parsing.h>
#import <TravelKit/TKCollection.h>

#import "TKPlace+Private.h"

@implementation TKCollection

- (instancetype)initFromResponse:(NSDictionary *)dictionary
{
	NSNumber *ID = [dictionary[@"id"] parsedNumber];
	NSString *fullName = [dictionary[@"name_long"] parsedString];
	NSString *parentID = [dictionary[@"parent_place_id"] parsedString];

	if (!ID || !fullName || !parentID)
		return nil;

	if (self = [super init])
	{
		// Basic attributes
		_ID = ID;
		_name = [dictionary[@"name_short"] parsedString];
		_fullName = fullName;
		_parentPlaceID = parentID;

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
