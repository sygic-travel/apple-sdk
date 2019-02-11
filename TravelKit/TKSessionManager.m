//
//  TKSessionManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 29/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <pthread/pthread.h>

#import "TKSessionManager+Private.h"
#import "TKDatabaseManager+Private.h"
#import "TKEventsManager+Private.h"
#import "TKAPI+Private.h"
#import "TKSSOAPI+Private.h"

#import "TKReachability+Private.h"

#import "Foundation+TravelKit.h"
#import "NSObject+Parsing.h"


// Session stuff
NSString * const TKSettingsKeyUniqueID = @"UniqueID";
NSString * const TKSettingsKeySession = @"Session";
NSString * const TKSettingsKeyChangesTimestamp = @"ChangesTimestamp";


@interface TKSessionManager ()

@property (nonatomic, strong) TKDatabaseManager *database;
@property (nonatomic, strong) TKEventsManager *events;
@property (nonatomic, strong) NSUserDefaults *defaults;

@end


@implementation TKSessionManager

+ (TKSessionManager *)sharedManager
{
    static dispatch_once_t once = 0;
    static TKSessionManager *shared = nil;
    dispatch_once(&once, ^{ shared = [[self alloc] init]; });
    return shared;
}

- (instancetype)init
{
	if (self = [super init])
	{
		__weak typeof(self) weakSelf = self;

		_database = [TKDatabaseManager sharedManager];
		_events = [TKEventsManager sharedManager];

		_events.sessionExpirationHandler = ^{
			[weakSelf refreshSession];
		};

		NSString *suiteName = @"com.tripomatic.travelkit";

		NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];

		// Handle Playground runtime a bit nicer
		if ([bundleID containsString:@"com.apple.dt.Xcode"]) {
			NSString *path = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject];
			path = [path stringByAppendingPathComponent:@"TravelKit"];
			path = [path stringByAppendingPathComponent:suiteName];
			suiteName = path;
		}

		// TODO: Check the resulting path on different platforms
		_defaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];

		[self loadState];

		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[self checkSession];
		}];
	}

	return self;
}

- (void)dealloc
{
	[self saveState];
}


#pragma mark -
#pragma mark Generic methods


- (void)loadState
{
	_changesTimestamp = [_defaults doubleForKey:TKSettingsKeyChangesTimestamp];
	_uniqueID = [_defaults stringForKey:TKSettingsKeyUniqueID];

	// Unique ID

	if (!_uniqueID)
		_uniqueID = [[NSUUID UUID] UUIDString];

	// Session

	NSDictionary *session = [_defaults objectForKey:TKSettingsKeySession];
	_session = [[TKSession alloc] initFromDictionary:session];

	[TKAPI sharedAPI].accessToken = _session.accessToken;
}

- (void)saveState
{
	[_defaults setObject:_uniqueID forKey:TKSettingsKeyUniqueID];
	[_defaults setObject:[_session asDictionary] forKey:TKSettingsKeySession];
	[_defaults setDouble:_changesTimestamp forKey:TKSettingsKeyChangesTimestamp];

	[_defaults synchronize];
}

- (void)clearAllData
{
	// Clear database data
	[_database runQuery:@"DELETE FROM %@;" tableName:kTKDatabaseTableFavorites];
	[_database runQuery:@"DELETE FROM %@;" tableName:kTKDatabaseTableTrips];
	[_database runQuery:@"DELETE FROM %@;" tableName:kTKDatabaseTableTripDays];
	[_database runQuery:@"DELETE FROM %@;" tableName:kTKDatabaseTableTripDayItems];

	// Reset User settings
	// TODO: Check/fix me?
	[_defaults removePersistentDomainForName:@"com.tripomatic.travelkit"];
//	[_defaults removeSuiteNamed:@"com.tripomatic.travelkit"];
	[_defaults synchronize];

	// Reload Session state
	[self loadState];

	// Re-save new Session state
	[self saveState];
}


#pragma mark -
#pragma mark User Session


- (void)setSession:(TKSession *)session
{
	_session = session;

	[TKAPI sharedAPI].accessToken = session.accessToken;

	[self saveState];

	if (_events.sessionUpdateHandler)
		_events.sessionUpdateHandler(session);
}

- (void)setChangesTimestamp:(NSTimeInterval)changesTimestamp
{
	_changesTimestamp = changesTimestamp;

	[self saveState];
}

- (void)checkSession
{
	if (![TKReachability isConnected])
		return;

	if (!_session)
		return;

//	// Fetch if User credentials missing
//
//	if (!_credentials)
//		[self fetchCredentials];

	// Refresh if token is about to expire

	else if (_session.isExpiring)
		[self refreshSession];
}

- (void)refreshSession
{
	static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

	if (pthread_mutex_trylock(&lock) != EXIT_SUCCESS)
		return;

	NSString *token = _session.refreshToken;

	if (!token) return;

	[[TKSSOAPI sharedAPI] performSessionRefreshWithToken:token success:^(TKSession *session) {

		self.session = session;
		pthread_mutex_unlock(&lock);

	} failure:^(TKAPIError *error) {

		// TODO: More sophisticated solution?
		if (error.code / 100 == 4)
			self.session = nil;

		pthread_mutex_unlock(&lock);

	}];
}


#pragma mark -
#pragma mark Authentication


- (void)performDeviceAuthWithSuccess:(void (^)(TKSession *))success
    failure:(void (^)(NSError *))failure
{
	[[TKSSOAPI sharedAPI] performDeviceAuthWithSuccess:^(TKSession *session) {

		self.session = session;

		if (success) success(session);

	} failure:failure];
}

- (void)performUserCredentialsAuthWithEmail:(NSString *)email password:(NSString *)password
    success:(void (^)(TKSession *))success failure:(void (^)(NSError *))failure
{
	[[TKSSOAPI sharedAPI] performUserCredentialsAuthWithUsername:email
	password:password success:^(TKSession *session) {

		self.session = session;

		if (success) success(session);

	} failure:failure];
}

- (void)performUserSocialAuthWithFacebookAccessToken:(NSString *)facebookAccessToken
	success:(void (^)(TKSession * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure
{
	[[TKSSOAPI sharedAPI] performUserSocialAuthWithFacebookAccessToken:facebookAccessToken
	googleIDToken:nil success:^(TKSession *session) {

		self.session = session;

		if (success) success(session);

	} failure:failure];
}

- (void)performUserSocialAuthWithGoogleIDToken:(NSString *)googleIDToken
	success:(void (^)(TKSession * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure
{
	[[TKSSOAPI sharedAPI] performUserSocialAuthWithFacebookAccessToken:nil
	googleIDToken:googleIDToken success:^(TKSession *session) {

		self.session = session;

		if (success) success(session);

	} failure:failure];
}

- (void)performJWTAuthWithToken:(NSString *)jwtToken
	success:(void (^)(TKSession * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure
{
	[[TKSSOAPI sharedAPI] performJWTAuthWithToken:jwtToken success:^(TKSession *session) {

		self.session = session;

		if (success) success(session);

	} failure:failure];
}

- (void)performMagicLinkAuthWithToken:(NSString *)magicToken
    success:(void (^)(TKSession *))success failure:(void (^)(NSError *))failure
{
	[[TKSSOAPI sharedAPI] performMagicAuthWithMagicLink:magicToken success:^(TKSession *session) {

		self.session = session;

		if (success) success(session);

	} failure:failure];
}

- (void)performUserRegisterWithToken:(NSString *)accessToken
  fullName:(NSString *)fullName email:(NSString *)email password:(NSString *)password
    success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
	[[TKSSOAPI sharedAPI] performUserRegisterWithToken:accessToken
		fullName:fullName email:email password:password success:success failure:failure];
}

- (void)performUserResetPasswordWithToken:(NSString *)accessToken email:(NSString *)email
	success:(void (^)(void))success failure:(void (^)(NSError * _Nonnull))failure
{
	[[TKSSOAPI sharedAPI] performUserResetPasswordWithToken:accessToken
		email:email success:success failure:failure];
}

- (void)performMagicLinkFetchWithToken:(NSString *)accessToken
	success:(void (^)(NSString *magicLinkToken))success failure:(void (^)(NSError *))failure
{
	[[TKSSOAPI sharedAPI] performMagicLinkFetchWithToken:accessToken success:^(NSString *magicLink) {
		if (success && magicLink) success(magicLink);
		if (failure && !magicLink) failure([TKAPIError errorWithCode:87234 userInfo:nil]);
	} failure:^(TKAPIError *err) {
		if (failure) failure(err);
	}];
}

- (void)performSignOutWithCompletion:(void (^)(void))completion
{
	[self clearAllData];

	if (completion) completion();
}

@end
