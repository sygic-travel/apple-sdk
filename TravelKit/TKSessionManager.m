//
//  TKSessionManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 29/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKSessionManager+Private.h"
#import "TKDatabaseManager+Private.h"
#import "TKEventsManager+Private.h"
#import "TKUserSettings+Private.h"
#import "TKAPI+Private.h"
#import "TKSSOAPI+Private.h"

#import "TKReachability+Private.h"

#import "Foundation+TravelKit.h"
#import "NSObject+Parsing.h"


@interface TKSessionManager ()

@property (nonatomic, strong) TKDatabaseManager *database;
@property (nonatomic, strong) TKEventsManager *events;
@property (nonatomic, strong) TKUserSettings *settings;

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

		_events.expiredSessionCredentialsHandler = ^{
			[weakSelf refreshCredentials];
		};

		_database = [TKDatabaseManager sharedManager];
		_events = [TKEventsManager sharedManager];
		_settings = [TKUserSettings sharedSettings];

		[self loadState];

		[self checkCredentials];
	}

	return self;
}


#pragma mark -
#pragma mark Generic methods


- (void)loadState
{
	_credentials = [[TKUserCredentials alloc] initFromDictionary:_settings.userCredentials];

	[TKAPI sharedAPI].accessToken = _credentials.accessToken;
}

- (void)saveState
{
	_settings.userCredentials = [_credentials asDictionary];

	[_settings commit];
}

- (void)clearUserData
{
	// Clear Favorites
	[_database runQuery:@"DELETE FROM %@;" tableName:kTKDatabaseTableFavorites];

	// Reset User settings
	[[TKUserSettings sharedSettings] reset];

	// Reload Session state
	[self loadState];

	// Re-save new Session state
	[self saveState];
}


#pragma mark -
#pragma mark User Credentials


- (void)setCredentials:(TKUserCredentials *)credentials
{
	_credentials = credentials;

	[TKAPI sharedAPI].accessToken = credentials.accessToken;

	[self saveState];

	if (_events.sessionCredentialsUpdateHandler)
		_events.sessionCredentialsUpdateHandler(credentials);
}

- (void)checkCredentials
{
	if (![TKReachability isConnected])
		return;

	if (!_credentials)
		return;

//	// Fetch if User credentials missing
//
//	if (!_credentials)
//		[self fetchCredentials];

	// Refresh if token is about to expire

	else if (_credentials.isExpiring)
		[self refreshCredentials];
}

- (void)refreshCredentials
{
	NSString *token = _credentials.refreshToken;

	if (!token) return;

	[[TKSSOAPI sharedAPI] performCredentialsRefreshWithToken:token success:^(TKUserCredentials *credentials) {

		self.credentials = credentials;

	} failure:^(TKAPIError *error) {

		// TODO: More sophisticated solution?
		if (error.code / 100 == 4)
			self.credentials = nil;

	}];
}


#pragma mark -
#pragma mark Authentication


- (void)performDeviceCredentialsFetchWithSuccess:(void (^)(TKUserCredentials *))success
    failure:(void (^)(NSError *))failure
{
	[[TKSSOAPI sharedAPI] performDeviceCredentialsFetchWithSuccess:^(TKUserCredentials *credentials) {

		self.credentials = credentials;

		if (success) success(credentials);

	} failure:failure];
}

- (void)performUserCredentialsAuthWithUsername:(NSString *)username password:(NSString *)password
    success:(void (^)(TKUserCredentials *))success failure:(void (^)(NSError *))failure
{
	[[TKSSOAPI sharedAPI] performUserCredentialsAuthWithUsername:username
	password:password success:^(TKUserCredentials *credentials) {

		self.credentials = credentials;

		if (success) success(credentials);

	} failure:failure];
}

- (void)performUserSocialAuthWithFacebookToken:(NSString *)facebookToken
	success:(void (^)(TKUserCredentials * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure
{
	[[TKSSOAPI sharedAPI] performUserSocialAuthWithFacebookToken:facebookToken
	googleToken:nil success:^(TKUserCredentials *credentials) {

		self.credentials = credentials;

		if (success) success(credentials);

	} failure:failure];
}

- (void)performUserSocialAuthWithGoogleToken:(NSString *)googleToken
	success:(void (^)(TKUserCredentials * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure
{
	[[TKSSOAPI sharedAPI] performUserSocialAuthWithFacebookToken:nil
	googleToken:googleToken success:^(TKUserCredentials *credentials) {

		self.credentials = credentials;

		if (success) success(credentials);

	} failure:failure];
}

- (void)performJWTAuthWithToken:(NSString *)jwtToken
	success:(void (^)(TKUserCredentials * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure
{
	[[TKSSOAPI sharedAPI] performJWTAuthWithToken:jwtToken success:^(TKUserCredentials *credentials) {

		self.credentials = credentials;

		if (success) success(credentials);

	} failure:failure];
}

- (void)performMagicLinkAuthWithToken:(NSString *)magicToken
    success:(void (^)(TKUserCredentials *))success failure:(void (^)(NSError *))failure
{
	[[TKSSOAPI sharedAPI] performMagicAuthWithMagicLink:magicToken success:^(TKUserCredentials *credentials) {

		self.credentials = credentials;

		if (success) success(credentials);

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

- (void)performMagicLinkeFetchWithToken:(NSString *)accessToken
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
	[self clearUserData];

	if (completion) completion();
}


#pragma mark -
#pragma mark Favorites


- (NSArray<NSString *> *)favoritePlaceIDs
{
	NSArray *results = [_database runQuery:
		@"SELECT id FROM %@ WHERE state >= 0;" tableName:kTKDatabaseTableFavorites];

	return [results mappedArrayUsingBlock:^NSString *(NSDictionary *res) {
		return [res[@"id"] parsedString];
	}];
}

- (void)updateFavoritePlaceID:(NSString *)favoriteID setFavorite:(BOOL)favorite
{
	if (!favoriteID) return;

	if (favorite)
		[_database runQuery:@"INSERT OR IGNORE INTO %@ VALUES (?, 1);"
			tableName:kTKDatabaseTableFavorites data:@[ favoriteID ]];
	else
		[_database runQuery:@"UPDATE %@ SET state = -1 WHERE id = ?;"
			tableName:kTKDatabaseTableFavorites data:@[ favoriteID ]];
}

- (NSDictionary<NSString *,NSNumber *> *)favoritePlaceIDsToSynchronize
{
	NSArray<NSDictionary *> *results = [_database runQuery:
		@"SELECT * FROM %@ WHERE state != 0;" tableName:kTKDatabaseTableFavorites];

	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:results.count];

	for (NSDictionary *f in results)
	{
		NSString *ID = [f[@"id"] parsedString];
		NSNumber *state = [f[@"state"] parsedNumber];

		if (!ID || ABS(state.integerValue) != 1) continue;

		dict[ID] = state;
	}

	return dict;
}

- (void)storeServerFavoriteIDsAdded:(NSArray<NSString *> *)addedIDs removed:(NSArray<NSString *> *)removedIDs
{
	NSString *(^joinIDs)(NSArray<NSString *> *) = ^NSString *(NSArray<NSString *> *arr) {
		if (!arr.count) return nil;
		return [NSString stringWithFormat:@"'%@'", [arr componentsJoinedByString:@"','"]];
	};

	NSString *addString = joinIDs(addedIDs);
	NSString *remString = joinIDs(removedIDs);

	if (addString) [_database runQuery:[NSString stringWithFormat:
		@"UPDATE %@ SET state = 0 WHERE id IN (%@);", kTKDatabaseTableFavorites, addString]];

	for (NSString *ID in addedIDs)
		[_database runQuery:@"INSERT OR IGNORE INTO %@ (id) VALUES (?);"
			tableName:kTKDatabaseTableFavorites data:@[ ID ]];

	if (remString) [_database runQuery:[NSString stringWithFormat:
		@"DELETE FROM %@ WHERE id IN (%@);", kTKDatabaseTableFavorites, remString]];
}

@end
