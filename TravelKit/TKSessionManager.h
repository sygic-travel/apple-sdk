//
//  TKSessionManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 29/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <TravelKit/TKUserCredentials.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKSessionManager : NSObject

/// Shared Session managing instance.
@property (class, readonly, strong) TKSessionManager *sharedManager;

+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

@property (nonatomic, strong, nullable, readonly) TKUserCredentials *credentials;

///---------------------------------------------------------------------------------------
/// @name Generic methods
///---------------------------------------------------------------------------------------

/**
 Clears all cached and persisting user data.
 */
- (void)clearUserData;

///---------------------------------------------------------------------------------------
/// @name Authentication
///---------------------------------------------------------------------------------------

- (void)performDeviceCredentialsFetchWithSuccess:(void (^)(TKUserCredentials *))success
    failure:(void (^)(NSError *))failure;

- (void)performUserCredentialsAuthWithUsername:(NSString *)username password:(NSString *)password
    success:(void (^)(TKUserCredentials *))success failure:(void (^)(NSError *))failure;

- (void)performUserSocialAuthWithFacebookToken:(NSString *)facebookToken
    success:(void (^)(TKUserCredentials *))success failure:(void (^)(NSError *))failure;

- (void)performUserSocialAuthWithGoogleToken:(NSString *)googleToken
    success:(void (^)(TKUserCredentials *))success failure:(void (^)(NSError *))failure;

- (void)performJWTAuthWithToken:(NSString *)jwtToken
    success:(void (^)(TKUserCredentials *))success failure:(void (^)(NSError *))failure;

- (void)performMagicLinkAuthWithToken:(NSString *)magicToken
    success:(void (^)(TKUserCredentials *))success failure:(void (^)(NSError *))failure;

- (void)performUserRegisterWithToken:(NSString *)accessToken
  fullName:(NSString *)fullName email:(NSString *)email password:(NSString *)password
    success:(void (^)(void))success failure:(void (^)(NSError *))failure;

- (void)performUserResetPasswordWithToken:(NSString *)accessToken email:(NSString *)email
    success:(void (^)(void))success failure:(void (^)(NSError *))failure;

- (void)performMagicLinkeFetchWithToken:(NSString *)accessToken
	success:(void (^)(NSString *magicLinkToken))success failure:(void (^)(NSError *))failure;

- (void)performSignOutWithCompletion:(void (^)(void))completion;

///---------------------------------------------------------------------------------------
/// @name Favorites
///---------------------------------------------------------------------------------------

/**
 Fetches an array of IDs of Places previously marked as favorite.

 @return Array of Place IDs.
 */
- (NSArray<NSString *> *)favoritePlaceIDs;

/**
 Updates a favorite state for a specific Place ID.

 @param favoriteID Place ID to update.
 @param favorite Desired Favorite state, either `YES` or `NO`.
 */
- (void)updateFavoritePlaceID:(NSString *)favoriteID setFavorite:(BOOL)favorite;

@end

NS_ASSUME_NONNULL_END
