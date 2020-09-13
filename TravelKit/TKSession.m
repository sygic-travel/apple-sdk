//
//  TKSession.m
//  TravelKit
//
//  Created by Michal Zelinka on 04/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKSession.h"
#import "NSObject+Parsing.h"
#import "Foundation+TravelKit.h"


@interface TKSession ()

@property (nonatomic, strong, readonly) NSDate *refreshDate;

@end


@implementation TKSession

- (instancetype)initFromDictionary:(NSDictionary *)dictionary
{
	NSString *accessToken = [dictionary[@"accessToken"] parsedString] ?:
		                    [dictionary[@"access_token"] parsedString];
	NSString *refreshToken = [dictionary[@"refreshToken"] parsedString] ?:
		                     [dictionary[@"refresh_token"] parsedString];

	if (!accessToken || !refreshToken)
		return nil;

	if (self = [super init])
	{
		// Tokens parsing

		_accessToken = accessToken;
		_refreshToken = refreshToken;

		// Expiration parsing
		// Local part

		NSNumber *refresh = [dictionary[@"refreshDate"] parsedNumber];
		NSNumber *expiration = [dictionary[@"expirationDate"] parsedNumber];

		if (refresh != nil) _refreshDate = [NSDate dateWithTimeIntervalSince1970:floor(refresh.doubleValue)];
		if (expiration != nil) _expirationDate = [NSDate dateWithTimeIntervalSince1970:floor(expiration.doubleValue)];
		else {
			expiration = [dictionary[@"expires_in"] parsedNumber];
			NSTimeInterval refreshInterval = floor(expiration.doubleValue * 0.8);
			NSTimeInterval expiryInterval = floor(expiration.doubleValue);
			if (expiration != nil) _refreshDate = [[NSDate new] dateByAddingTimeInterval:refreshInterval];
			if (expiration != nil) _expirationDate = [[NSDate new] dateByAddingTimeInterval:expiryInterval];
		}

		if (!_expirationDate)
			return nil;
	}

	return self;
}

- (BOOL)isExpiring
{
	if (_refreshDate) return [_refreshDate timeIntervalSinceNow] < 60;
	if (_expirationDate) return [_expirationDate timeIntervalSinceNow] < 60*60;
	return YES;
}

- (NSDictionary *)asDictionary
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];

	if (_accessToken) dict[@"accessToken"] = _accessToken;
	if (_refreshToken) dict[@"refreshToken"] = _refreshToken;
	if (_refreshDate) dict[@"refreshDate"] = @([_refreshDate timeIntervalSince1970]);
	if (_expirationDate) dict[@"expirationDate"] = @([_expirationDate timeIntervalSince1970]);

	return dict;
}

- (BOOL)isEqual:(id)object
{
	if (![object isKindOfClass:[TKSession class]]) return NO;

	TKSession *session = object;

	return [[self asDictionary] isEqualToDictionary:[session asDictionary]];
}

- (instancetype)copy
{
	return [[self.class alloc] initFromDictionary:[self asDictionary]];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@\n\tToken: %@\n\tExpiration: %@",
		super.description, _accessToken, _expirationDate];
}

@end
