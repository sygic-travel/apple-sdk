//
//  TKSSOAPI.m
//  TravelKit
//
//  Created by Michal Zelinka on 04/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKSSOAPI+Private.h"
#import "TKSessionManager+Private.h"
#import "NSObject+Parsing.h"
#import "Foundation+TravelKit.h"


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark Definitions -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#define tkAPIEndpoint        @"https://auth.sygic.com"
#define tkAPIClientID        @"sdk.sygictravel.ios"

#ifdef DEBUG
#undef  tkAPIEndpoint
#define tkAPIEndpoint        @"https://tripomatic-auth-master-testing.sygic.com"
#undef  tkAPIClientID
#define tkAPIClientID        @"sygictravel_ios_sdk_demo"
#endif

// SSO endpoint URLs // TODO: Remove testing stage
NSString *const TKSSOEndpointURL = tkAPIEndpoint;

#define objectOrNull(x)      (x ?: [NSNull null])

#if TARGET_OS_OSX == 1
#define tkPlatform @"macos"
#endif // TARGET_OS_OSX

#if TARGET_OS_IOS == 1
#define tkPlatform @"ios"
#endif // TARGET_OS_IOS

#if TARGET_OS_TV == 1
#define tkPlatform @"tvos"
#endif // TARGET_OS_TV

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark - SSO API singleton -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@interface TKSSOAPI ()

@property (nonatomic, copy) NSString *apiURL;

@end

@implementation TKSSOAPI

#pragma mark -
#pragma mark Shared instance

+ (TKSSOAPI *)sharedAPI
{
	static TKSSOAPI *shared = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{ shared = [[self alloc] init]; });
	return shared;
}

+ (NSURLSession *)sharedSession
{
	static NSURLSession *ssoSession = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
//		config.timeoutIntervalForRequest = 12.0;
//		config.URLCache = nil;
		ssoSession = [NSURLSession sessionWithConfiguration:config];
	});

	return ssoSession;
}

- (NSString *)domain
{
	return TKSSOEndpointURL;
}


////////////////////
#pragma mark - Request workers
////////////////////


- (void)performRequest:(NSURLRequest *)request
            completion:(void (^)(NSInteger status, NSDictionary *response, NSError *error))completion
{
	[[[self.class sharedSession] dataTaskWithRequest:request
	  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

		if (error) {
			if (completion) completion(0, nil, [TKAPIError errorWithCode:error.code userInfo:error.userInfo]);
			return;
		}

		if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
			if (completion) completion(0, nil, [TKAPIError errorWithCode:-349852 userInfo:nil]);
			return;
		}

		NSInteger status = ((NSHTTPURLResponse *)response).statusCode;

		NSDictionary *resp = nil;

		if (data.length)
			resp = [[NSJSONSerialization JSONObjectWithData:data
				options:(NSJSONReadingOptions)0 error:NULL] parsedDictionary];

		if (status < 200 || status >= 300) {
			if (completion) completion(status, nil, [TKAPIError errorWithCode:status userInfo:@{
				NSDebugDescriptionErrorKey: resp[@"type"] ?: @"",
				NSLocalizedDescriptionKey: resp[@"detail"] ?: @"",
				NSLocalizedFailureReasonErrorKey: resp[@"detail"] ?: @"",
			}]);
			return;
		}

		if (completion) completion(status, resp, nil);

	}] resume];
}

+ (NSMutableURLRequest *)standardRequestWithURL:(NSURL *)URL data:(NSData *)data
{
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL];
	req.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	req.timeoutInterval = 12.0;
	req.HTTPMethod = @"POST";
	req.HTTPBody = data;

	[req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[req setValue:[@(data.length) stringValue] forHTTPHeaderField:@"Content-Length"];

	return req;
}


////////////////////
#pragma mark - Requests
////////////////////


- (void)performDeviceAuthWithSuccess:(void (^)(TKSession *))success failure:(void (^)(TKAPIError *))failure
{
	NSString *path = @"/oauth2/token";

	NSDictionary *post = @{
		@"client_id": tkAPIClientID,
		@"grant_type": @"client_credentials",
		@"device_code": [TKSessionManager sharedManager].uniqueID,
		@"device_platform": tkPlatform,
	};

	NSData *data = [post asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary *response, NSError *error) {

		TKSession *session = [[TKSession alloc] initFromDictionary:response];

		if (session && success) success(session);
		if (!session && failure) failure([TKAPIError errorWithCode:-20934 userInfo:error.userInfo]);

	}];
}

- (void)performSessionRefreshWithToken:(NSString *)refreshToken
	success:(void (^)(TKSession *))success failure:(void (^)(TKAPIError *))failure
{
	NSString *path = @"/oauth2/token";

	NSDictionary *post = @{
		@"client_id": tkAPIClientID,
		@"grant_type": @"refresh_token",
		@"device_code": [TKSessionManager sharedManager].uniqueID,
		@"device_platform": tkPlatform,
		@"refresh_token": objectOrNull(refreshToken),
	};

	NSData *data = [post asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary *response, NSError *error) {

		TKSession *session = [[TKSession alloc] initFromDictionary:response];

		if (session && success) success(session);
		if (!session && failure) failure([TKAPIError errorWithCode:-20935 userInfo:error.userInfo]);

	}];
}

- (void)performUserCredentialsAuthWithUsername:(NSString *)username password:(NSString *)password
	success:(void (^)(TKSession *))success failure:(TKAPIFailureBlock)failure
{
	NSString *path = @"/oauth2/token";

	NSDictionary *post = @{
		@"client_id": tkAPIClientID,
		@"grant_type": @"password",
		@"username": objectOrNull(username),
		@"password": objectOrNull(password),
		@"device_code": [TKSessionManager sharedManager].uniqueID,
		@"device_platform": tkPlatform,
	};

	NSData *data = [post asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary *response, NSError *error) {

		TKSession *session = [[TKSession alloc] initFromDictionary:response];

		if (session && success) success(session);
		if (!session && failure) failure([TKAPIError errorWithCode:-20936 userInfo:error.userInfo]);

	}];
}

- (void)performUserSocialAuthWithFacebookAccessToken:(NSString *)facebookAccessToken
	googleIDToken:(NSString *)googleIDToken success:(void (^)(TKSession *))success failure:(TKAPIFailureBlock)failure
{
	NSString *path = @"/oauth2/token";

	NSString *type = facebookAccessToken ? @"facebook" : googleIDToken ? @"google" : nil;
	NSString *key = googleIDToken ? @"id_token" : @"access_token";
	NSString *token = facebookAccessToken ?: googleIDToken;

	NSDictionary *post = @{
		@"client_id": tkAPIClientID,
		@"grant_type": objectOrNull(type),
		key: objectOrNull(token),
		@"device_code": [TKSessionManager sharedManager].uniqueID,
		@"device_platform": tkPlatform,
	};

	NSData *data = [post asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary *response, NSError *error) {

		TKSession *session = [[TKSession alloc] initFromDictionary:response];

		if (session && success) success(session);
		if (!session && failure) failure([TKAPIError errorWithCode:-20937 userInfo:error.userInfo]);

	}];
}

- (void)performJWTAuthWithToken:(NSString *)jwtToken
	success:(void (^)(TKSession *))success failure:(TKAPIFailureBlock)failure
{
	NSString *path = @"/oauth2/token";

	NSDictionary *post = @{
		@"client_id": tkAPIClientID,
		@"grant_type": @"external",
		@"token": objectOrNull(jwtToken),
		@"device_code": [TKSessionManager sharedManager].uniqueID,
		@"device_platform": tkPlatform,
	};

	NSData *data = [post asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary *response, NSError *error) {

		TKSession *session = [[TKSession alloc] initFromDictionary:response];

		if (session && success) success(session);
		if (!session && failure) failure([TKAPIError errorWithCode:-20938 userInfo:error.userInfo]);

	}];
}

- (void)performMagicAuthWithMagicLink:(NSString *)magicLink
	success:(void (^)(TKSession *))success failure:(TKAPIFailureBlock)failure
{
	NSString *path = @"/oauth2/token";

	NSDictionary *post = @{
		@"client_id": @"sygictravel_ios",
		@"grant_type": @"magic_link",
		@"token": objectOrNull(magicLink),
		@"device_code": [TKSessionManager sharedManager].uniqueID,
		@"device_platform": @"ios",
	};

	NSData *data = [post asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary * __unused response, NSError *__unused error) {

		TKSession *session = [[TKSession alloc] initFromDictionary:response];

		if (session && success) success(session);
		if (!session && failure) failure([TKAPIError errorWithCode:-20934 userInfo:nil]);

	}];
}

- (void)performUserRegisterWithToken:(NSString *)accessToken fullName:(NSString *)fullName email:(NSString *)email
	password:(NSString *)password success:(void (^)(void))success failure:(TKAPIFailureBlock)failure
{
	NSString *path = @"/user/register";

	NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];

	NSDictionary *post = @{
		@"client_id": tkAPIClientID,
		@"device_code": [TKSessionManager sharedManager].uniqueID,
		@"device_platform": tkPlatform,
		@"username" : objectOrNull(email),
		@"password" : objectOrNull(password),
		@"email" : objectOrNull(email),
		@"name" : objectOrNull(fullName),
	};

	NSData *data = [post asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[request setValue:authHeader forHTTPHeaderField:@"Authorization"];

	[self performRequest:request completion:
	 ^(NSInteger status, NSDictionary * __unused response, NSError *error) {

		if (status == 200) { if (success) success(); }
		else if (failure) failure([TKAPIError errorWithCode:-20939 userInfo:error.userInfo]);

	}];
}

- (void)performUserResetPasswordWithToken:(NSString *)accessToken email:(NSString *)email
	success:(void (^)(void))success failure:(TKAPIFailureBlock)failure
{
	NSString *path = @"/user/reset-password";

	NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];

	NSData *data = [@{ @"email" : objectOrNull(email) } asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[request setValue:authHeader forHTTPHeaderField:@"Authorization"];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary * __unused response, NSError *error) {

		if (error) {
			if (failure) failure([TKAPIError errorWithCode:error.code userInfo:error.userInfo]);
			return;
		}

		if (success) success();

	}];
}

- (void)performMagicLinkFetchWithToken:(NSString *)accessToken
	success:(void (^)(NSString *magicLink))success failure:(TKAPIFailureBlock)failure
{
	NSString *path = @"/user/magic-link";

	NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];

	NSData *data = [@{ @"destination" : @"travel_app", @"send_mail": @NO } asJSONData];

	NSString *urlString = [[self domain] stringByAppendingString:path];
	NSURL *URL = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [self.class standardRequestWithURL:URL data:data];

	[request setValue:authHeader forHTTPHeaderField:@"Authorization"];

	[self performRequest:request completion:
	 ^(NSInteger __unused status, NSDictionary *response, NSError *error) {

		if (error) {
			if (failure) failure([TKAPIError errorWithCode:error.code userInfo:error.userInfo]);
			return;
		}

		NSString *link = [response[@"magic_link"] parsedString];

		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[a-z0-9]{32,}" options:NSRegularExpressionCaseInsensitive error:nil];
		NSTextCheckingResult *result = [regex matchesInString:link options:0 range:NSMakeRange(0, link.length)].firstObject;

		@try {
			link = (result) ? [link substringWithRange:result.range] : nil;
		} @catch (NSException *e) { link = nil; }

		if (success && link) success(link);
		if (failure && !link) failure([TKAPIError errorWithCode:23409 userInfo:nil]);
	}];
}

@end
