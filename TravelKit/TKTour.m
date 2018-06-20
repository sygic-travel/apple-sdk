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
		_durationMin = [dictionary[@"duration_min"] parsedNumber];
		_durationMax = [dictionary[@"duration_max"] parsedNumber];

		NSArray *flags = [dictionary[@"flags"] parsedArray];
		if ([flags containsObject:@"bestseller"]) _flags |= TKTourFlagBestSeller;
		if ([flags containsObject:@"instant_confirmation"]) _flags |= TKTourFlagInstantConfirmation;
		if ([flags containsObject:@"portable_ticket"]) _flags |= TKTourFlagPortableTicket;
		if ([flags containsObject:@"wheelchair_access"]) _flags |= TKTourFlagWheelChairAccess;
		if ([flags containsObject:@"skip_the_line"]) _flags |= TKTourFlagSkipTheLine;
    }

    return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<TKTour: %p | ID: %@ | Title: %@>", self, _ID, _title];
}

@end
