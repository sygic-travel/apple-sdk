//
//  TKTour.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKTour+Private.h"
#import "NSObject+Parsing.h"


@implementation TKTour

- (instancetype)initFromResponse:(NSDictionary *)dictionary
{
	if (self = [super init])
	{
		// Basic attributes
		_ID = [dictionary[@"id"] parsedString];
		_title = [dictionary[@"title"] parsedString];

		NSString *stored = [dictionary[@"url"] parsedString];
		if (stored) _URL = [NSURL URLWithString:stored];

		if (!_ID || !_title || !_URL) return nil;

		_perex = [dictionary[@"perex"] parsedString];

		stored = [dictionary[@"photo_url"] parsedString];
		if (stored) _photoURL = [NSURL URLWithString:stored];

		// Properties
		_rating = [dictionary[@"rating"] parsedNumber];
		_price = [dictionary[@"price"] parsedNumber];
		_originalPrice = [dictionary[@"original_price"] parsedNumber];
		if (_originalPrice.intValue == 0) _originalPrice = nil;
		_reviewsCount = [dictionary[@"review_count"] parsedNumber];
		_duration = [dictionary[@"duration"] parsedString];
    }

    return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<TKTour: %p | ID: %@ | Title: %@>", self, _ID, _title];
}

@end
