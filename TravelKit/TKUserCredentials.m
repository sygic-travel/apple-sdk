//
//  TKUserCredentials.m
//  TravelKit
//
//  Created by Michal Zelinka on 04/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKUserCredentials.h"
#import "NSObject+Parsing.h"
#import "Foundation+TravelKit.h"

@implementation TKUserCredentials

- (instancetype)initFromDictionary:(NSDictionary *)dictionary
{
	if (self = [super init])
	{
		_accessToken = [dictionary[@"accessToken"] parsedString] ?:
		               [dictionary[@"access_token"] parsedString];

		_refreshToken = [dictionary[@"refreshToken"] parsedString] ?:
		                [dictionary[@"refresh_token"] parsedString];

		NSNumber *expiration = [dictionary[@"expires_in"] parsedNumber];
		if (expiration) _expiration = [[NSDate new] dateByAddingTimeInterval:expiration.doubleValue];
		else {
			expiration = [dictionary[@"expiration"] parsedNumber];
			if (expiration) _expiration = [NSDate dateWithTimeIntervalSince1970:expiration.doubleValue];
		}

		if (!_accessToken || !_refreshToken || !_expiration)
			return nil;
	}

	return self;
}

- (BOOL)isExpiring
{
	return !_expiration || [_expiration timeIntervalSinceNow] < 30*86400;
}

- (NSDictionary *)asDictionary
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];

	if (_accessToken) dict[@"accessToken"] = _accessToken;
	if (_refreshToken) dict[@"refreshToken"] = _refreshToken;
	if (_expiration) dict[@"expiration"] = @([_expiration timeIntervalSince1970]);

	return dict;
}

- (BOOL)isEqual:(id)object
{
	if (![object isKindOfClass:[TKUserCredentials class]]) return NO;

	TKUserCredentials *userCredentials = object;

	return [[self asDictionary] isEqualToDictionary:[userCredentials asDictionary]];
}

- (instancetype)copy
{
	return [[self.class alloc] initFromDictionary:[self asDictionary]];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@\n\tToken: %@\n\tExpiration: %@",
		super.description, _accessToken, _expiration];
}

@end
