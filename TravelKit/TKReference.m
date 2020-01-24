//
//  TKReference.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKReference+Private.h"
#import "NSObject+Parsing.h"


@implementation TKReference

- (instancetype)initFromResponse:(NSDictionary *)response
{
	if (!response) return nil;

	if (self = [super init])
	{
		NSNumber *ID = [response[@"id"] parsedNumber];
		_ID = [ID unsignedIntegerValue];
		_title = [response[@"title"] parsedString];
		_type = [response[@"type"] parsedString];
		_languageID = [response[@"language_id"] parsedString];

		NSMutableArray *flags = [NSMutableArray arrayWithCapacity:3];

		for (NSString *str in [response[@"flags"] parsedArray]) {
			NSString *f = [str parsedString];
			if (f) [flags addObject:f]; }

		for (NSString *str in [[response[@"flags"]
		  parsedString] componentsSeparatedByString:@"|"]) {
			NSString *f = [str parsedString];
			if (f) [flags addObject:f]; }

		_flags = flags;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

		NSString *url = [response[@"url"] parsedString];
		if (url) _onlineURL = [NSURL URLWithString:url];
		if (url && !_onlineURL)
			_onlineURL = [NSURL URLWithString:
				[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

#pragma clang diagnostic pop

		if (ID == nil || !_title || !_type || !_onlineURL)
			return nil;

		_supplier = [response[@"supplier"] parsedString];
		_priority = [response[@"priority"] integerValue];
		_price = [response[@"price"] parsedNumber];
	}

	return self;
}

- (instancetype)initWithReference:(TKReference *)ref
{
	if (self = [super init])
	{
		_ID = ref.ID;
		_title = ref.title;
		_type = ref.type;
		_supplier = ref.supplier;
		_price = ref.price;
		_languageID = ref.languageID;
		_onlineURL = ref.onlineURL;
		_flags = ref.flags;
		_priority = ref.priority;
	}

	return self;
}

- (id)copy
{
	return [[self.class alloc] initWithReference:self];
}

- (id)copyWithZone:(__unused NSZone *)zone
{
	return [self copy];
}

- (NSString *)iconName
{
	NSDictionary * menuIconNames = @{
		@"info": @"menuicon-about",
		@"taxi": @"menuicon-taxi",
		@"city_card": @"menuicon-card",
		@"public_transportation": @"menuicon-bus",
		@"guide": @"menuicon-guide",
		@"fodors_guide": @"menuicon-guide",
		@"link": @"menuicon-link",
		@"exclamation_mark": @"menuicon-exclamation",
		@"bus": @"menuicon-bus",
		@"airport_transfer": @"menuicon-airplane",
	};

	return menuIconNames[_type];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<TKReference %tu>\n\tTitle: %@", _ID, _title];
}

@end
