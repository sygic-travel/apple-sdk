//
//  API+Private.h
//  Tripomatic
//
//  Created by Michal Zelinka on 27/09/13.
//  Copyright (c) 2013 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKAPIConnection+Private.h"

#import "TKPlace.h"
#import "TKMedium.h"
#import "TKPlacesQuery.h"

#define API_PROTOCOL   "https" // Mandatory
#define API_SUBDOMAIN  "api"
#define API_BASE_URL   "sygictravelapi.com"
#define API_VERSION    "0.1"

typedef NS_ENUM(NSInteger, TKAPIRequestType)
{
	TKAPIRequestTypeUnknown = 0,
	TKAPIRequestTypePlacesGET,
	TKAPIRequestTypePlaceGET,
	TKAPIRequestTypeMediaGET,
	TKAPIRequestTypeExchangeRatesGET,
	TKAPIRequestTypeCustomGET,
	TKAPIRequestTypeCustomPOST,
	TKAPIRequestTypeCustomPUT,
	TKAPIRequestTypeCustomDELETE,
};

typedef NS_ENUM(NSUInteger, TKAPIRequestState)
{
	TKAPIRequestStateInit = 0,
	TKAPIRequestStatePending,
	TKAPIRequestStateFinished,
};

//
//   Will handle API URLs, connection IDs, ...
//

@interface TKAPI : NSObject

@property (nonatomic, copy) NSString *APIKey;
@property (nonatomic, copy, readonly) NSString *defaultAPIKey;
@property (nonatomic, copy, readonly) NSString *hostname;
@property (nonatomic, readonly) BOOL isAlphaEnvironment; // Private

/** Shared sigleton */
+ (TKAPI *)sharedAPI;
- (instancetype)init OBJC_UNAVAILABLE("Use [TKAPI sharedAPI].");

// Standard supported + custom API calls
- (NSString *)pathForRequestType:(TKAPIRequestType)type;
- (NSString *)pathForRequestType:(TKAPIRequestType)type ID:(NSString *)ID;
- (NSString *)URLStringForPath:(NSString *)path;

@end


@interface TKAPIRequest : NSObject

@property (nonatomic, copy) NSString *APIKey; // Customizable
@property (atomic) TKAPIRequestType type;
@property (atomic) TKAPIRequestState state;
@property (nonatomic) BOOL silent;

@property (nonatomic, readonly) NSString *typeString;


////////////////////
// Predefined requests
////////////////////


////////////////////
// Places

- (instancetype)initAsPlacesRequestForQuery:(TKPlacesQuery *)query
	success:(void (^)(NSArray<TKPlace *> *places))success failure:(void (^)())failure;

////////////////////
// Place

- (instancetype)initAsPlaceRequestForItemWithID:(NSString *)itemID
	success:(void (^)(TKPlace *place, NSArray<TKMedium *> *media))success failure:(void (^)())failure;

////////////////////
// Media

- (instancetype)initAsMediaRequestForPlaceWithID:(NSString *)placeID
	success:(void (^)(NSArray<TKMedium *> *media))success failure:(void (^)())failure;

////////////////////
// Exchange rates

- (instancetype)initAsExchangeRatesRequestWithSuccess:(void (^)(NSDictionary<NSString *, NSNumber *> *))success
	failure:(void (^)())failure;

////////////////////
// Custom requests

/**
 * Method for easier sending of GET requests by appending just a path
 *
 * @param path     URL path of a request, f.e. '/activity/poi:530' when asking for Activity detail
 * @param success  Success block receiving parsed JSON data in NSDictionary-subclass object
 * @param failure  Failure block
 * @return         API Request instance
 */
- (instancetype)initAsCustomGETRequestWithPath:(NSString *)path
    success:(void (^)(id))success failure:(TKAPIConnectionFailureBlock)failure;

/**
 * Method for easier sending of POST requests by appending just a path
 *
 * @param path     URL path of a request, f.e. '/activity/' when submitting new Custom Place
 * @param json     JSON string with data to be included in POST request
 * @param success  Success block receiving parsed JSON response in NSDictionary-subclass object
 * @param failure  Failure block
 * @return         API Request instance
 */
- (instancetype)initAsCustomPOSTRequestWithPath:(NSString *)path
    json:(NSString *)json success:(void (^)(id))success failure:(TKAPIConnectionFailureBlock)failure;

/**
 * Method for easier sending of PUT requests by appending just a path
 *
 * @param path     URL path of a request, f.e. '/activity/c:12903' when submitting Custom Place udpate
 * @param json     JSON string with data to be included in PUT request
 * @param success  Success block receiving parsed JSON response in NSDictionary-subclass object
 * @param failure  Failure block
 * @return         API Request instance
 */
- (instancetype)initAsCustomPUTRequestWithPath:(NSString *)path
    json:(NSString *)json success:(void (^)(id))success failure:(TKAPIConnectionFailureBlock)failure;

/**
 * Method for easier sending of DELETE requests by appending just a path
 *
 * @param path     URL path of a request, f.e. '/activity/c:12903' when submitting Custom Place udpate
 * @param success  Success block receiving parsed JSON response in NSDictionary-subclass object
 * @param failure  Failure block
 * @return         API Request instance
 */
- (instancetype)initAsCustomDELETERequestWithPath:(NSString *)path
    json:(NSString *)json success:(void (^)(id))success failure:(TKAPIConnectionFailureBlock)failure;

// Actions

- (void)start;
- (void)silentStart;
- (void)cancel;

@end
