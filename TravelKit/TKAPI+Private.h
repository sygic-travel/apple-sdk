//
//  TKAPI+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 27/09/13.
//  Copyright (c) 2013 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <TravelKit/TKAPIDefinitions.h>

#import <TravelKit/TKPlace.h>
#import <TravelKit/TKTour.h>
#import <TravelKit/TKTrip.h>
#import <TravelKit/TKMedium.h>
#import <TravelKit/TKPlacesQuery.h>
#import <TravelKit/TKToursQuery.h>
#import <TravelKit/TKDirectionsManager.h>


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark Definitions -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


#define API_PROTOCOL   "https"
#define API_SUBDOMAIN  "api"
#define API_BASE_URL   "sygictravelapi.com"
#define API_VERSION    "1.0"

#ifdef DEBUG
#undef  API_SUBDOMAIN
#define API_SUBDOMAIN  "alpha-api"
#endif

typedef NS_ENUM(NSInteger, TKAPIRequestType)
{
	TKAPIRequestTypeUnknown = 0,
	TKAPIRequestTypePlacesQueryGET,
	TKAPIRequestTypePlacesBatchGET,
	TKAPIRequestTypePlaceGET,
	TKAPIRequestTypeToursQueryGET,
	TKAPIRequestTypeMediaGET,
	TKAPIRequestTypeFavoriteADD,
	TKAPIRequestTypeFavoriteDELETE,
	TKAPIRequestTypeTripGET,
	TKAPIRequestTypeTripNEW,
	TKAPIRequestTypeTripUPDATE,
	TKAPIRequestTypeTrashEMPTY,
	TKAPIRequestTypeTripsBatchGET,
	TKAPIRequestTypeChangesGET,
	TKAPIRequestTypeDirectionsGET,
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

FOUNDATION_EXPORT NSString * const TKAPIErrorDomain;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark - API singleton -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@interface TKAPI : NSObject

@property (nonatomic, copy) NSString *APIKey;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, copy, readonly) NSString *hostname;
@property (nonatomic, readonly) BOOL isAlphaEnvironment; // Private

// Shared sigleton
@property (class, readonly, strong) TKAPI *sharedAPI;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

// Standard supported + custom API calls
- (NSString *)pathForRequestType:(TKAPIRequestType)type;
- (NSString *)pathForRequestType:(TKAPIRequestType)type ID:(NSString *)ID;

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark - API request -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@interface TKAPIRequest : NSObject

@property (nonatomic, copy) NSString *APIKey; // Customizable
@property (nonatomic, copy) NSString *accessToken; // Customizable
@property (atomic) TKAPIRequestType type;
@property (atomic) TKAPIRequestState state;
@property (nonatomic) BOOL silent;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;

@property (nonatomic, readonly) NSString *typeString;


////////////////////
#pragma mark - Predefined requests
////////////////////


////////////////////
// Changes

- (instancetype)initAsChangesRequestSince:(NSDate *)sinceDate success:(void (^)(
	NSDictionary<NSString *, NSNumber *> *updatedTripsDict, NSArray<NSString *> *deletedTripIDs,
	NSArray<NSString *> *updatedFavouriteIDs, NSArray<NSString *> *deletedFavouriteIDs,
	BOOL updatedSettings, NSDate *timestamp))success failure:(TKAPIFailureBlock)failure;

////////////////////
// Trips

- (instancetype)initAsTripRequestForTripWithID:(NSString *)tripID
	success:(void (^)(TKTrip *trip))success failure:(TKAPIFailureBlock)failure;

- (instancetype)initAsNewTripRequestForTrip:(TKTrip *)trip
	success:(void (^)(TKTrip *trip))success failure:(TKAPIFailureBlock)failure;

- (instancetype)initAsUpdateTripRequestForTrip:(TKTrip *)trip
	success:(void (^)(TKTrip *, TKTripConflict *))success failure:(void (^)(TKAPIError *))failure;

- (instancetype)initAsEmptyTrashRequestWithSuccess:(void (^)(NSArray<NSString *> *tripIDs))success
	failure:(TKAPIFailureBlock)failure;

- (instancetype)initAsBatchTripRequestForIDs:(NSArray<NSString *> *)tripIDs
	success:(void (^)(NSArray<TKTrip *> *))success failure:(TKAPIFailureBlock)failure;

////////////////////
// Places Query

- (instancetype)initAsPlacesRequestForQuery:(TKPlacesQuery *)query
	success:(void (^)(NSArray<TKPlace *> *places))success
		failure:(TKAPIFailureBlock)failure;

////////////////////
// Places Batch

- (instancetype)initAsPlacesRequestForIDs:(NSArray<NSString *> *)placeIDs
	success:(void (^)(NSArray<TKPlace *> *places))success
		failure:(TKAPIFailureBlock)failure;

////////////////////
// Place

- (instancetype)initAsPlaceRequestForItemWithID:(NSString *)itemID
	success:(void (^)(TKPlace *place))success
		failure:(TKAPIFailureBlock)failure;

////////////////////
// Tours Query

- (instancetype)initAsViatorToursRequestForQuery:(TKToursViatorQuery *)query
	success:(void (^)(NSArray<TKTour *> *tours))success
		failure:(TKAPIFailureBlock)failure;

- (instancetype)initAsGYGToursRequestForQuery:(TKToursGYGQuery *)query
	success:(void (^)(NSArray<TKTour *> *tours))success
		failure:(TKAPIFailureBlock)failure;

////////////////////
// Media

- (instancetype)initAsMediaRequestForPlaceWithID:(NSString *)placeID
	success:(void (^)(NSArray<TKMedium *> *media))success
		failure:(TKAPIFailureBlock)failure;

////////////////////
// Favorites

- (instancetype)initAsFavoriteItemAddRequestWithID:(NSString *)itemID
	success:(void (^)(void))success failure:(TKAPIFailureBlock)failure;

- (instancetype)initAsFavoriteItemDeleteRequestWithID:(NSString *)itemID
	success:(void (^)(void))success failure:(TKAPIFailureBlock)failure;

////////////////////
// Directions

- (instancetype)initAsDirectionsRequestForQuery:(TKDirectionsQuery *)query
	success:(void (^)(TKDirectionsSet *directionsSet))success
		failure:(TKAPIFailureBlock)failure;

////////////////////
// Exchange rates

- (instancetype)initAsExchangeRatesRequestWithSuccess:(void (^)(NSDictionary<NSString *, NSNumber *> *))success
	failure:(TKAPIFailureBlock)failure;

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
    success:(void (^)(id))success failure:(TKAPIFailureBlock)failure;

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
    json:(NSString *)json success:(void (^)(id))success failure:(TKAPIFailureBlock)failure;

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
    json:(NSString *)json success:(void (^)(id))success failure:(TKAPIFailureBlock)failure;

/**
 * Method for easier sending of DELETE requests by appending just a path
 *
 * @param path     URL path of a request, f.e. '/activity/c:12903' when submitting Custom Place udpate
 * @param success  Success block receiving parsed JSON response in NSDictionary-subclass object
 * @param failure  Failure block
 * @return         API Request instance
 */
- (instancetype)initAsCustomDELETERequestWithPath:(NSString *)path
    json:(NSString *)json success:(void (^)(id))success failure:(TKAPIFailureBlock)failure;

// Actions

- (void)start;
- (void)silentStart;
- (void)cancel;

@end
