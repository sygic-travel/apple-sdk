//
//  TKReference.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKReference.h"
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

		if (!ID || !_type || !_onlineURL)
			return nil;

		_supplier = [response[@"supplier"] parsedString];
		_priority = [response[@"priority"] integerValue];
		_price = [response[@"price"] parsedNumber];
	}

	return self;
}

- (id)copy
{
	return [self copyWithZone:nil];
}

- (id)copyWithZone:(NSZone *)zone
{
	TKReference *ref = [TKReference new];
	ref.ID = _ID;
	ref.title = _title;
	ref.type = _type;
	ref.supplier = _supplier;
	ref.price = _price;
	ref.languageID = _languageID;
	ref.onlineURL = _onlineURL;
	ref.flags = _flags;
	ref.priority = _priority;

	return ref;
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
