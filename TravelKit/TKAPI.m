//
//  TKAPI.h
//  TravelKit
//
//  Created by Michal Zelinka on 27/09/13.
//  Copyright (c) 2013 Tripomatic. All rights reserved.
//

#import <TravelKit/TravelKit.h>
#import <TravelKit/NSObject+Parsing.h>
#import <TravelKit/NSDate+Tripomatic.h>
#import <TravelKit/Foundation+TravelKit.h>

#import "TKAPI+Private.h"
#import "TKPlace+Private.h"
#import "TKCollection+Private.h"
#import "TKTour+Private.h"
#import "TKTrip+Private.h"
#import "TKDirection+Private.h"
#import "TKMedium+Private.h"
#import "TKEventsManager+Private.h"



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark - API singleton -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@interface TKAPI ()

@property (nonatomic, copy) NSString *apiURL;

@end

@implementation TKAPI

#pragma mark -
#pragma mark Shared instance

+ (TKAPI *)sharedAPI
{
	static TKAPI *shared = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{ shared = [[self alloc] init]; });
	return shared;
}

#pragma mark -
#pragma mark Instance implementation

- (void)refreshServerProperties
{
	NSString *subdomain = @API_SUBDOMAIN;

	subdomain = [subdomain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	if (![subdomain hasSuffix:@"."])
		subdomain = [subdomain stringByAppendingString:@"."];

	NSString *lang = _languageID ?: @"en";

	_apiURL = [NSString stringWithFormat:@"%@://%@%@/%@/%@",
	//          http[s]://  api.      sygictravelapi.com  /    xyz   /   en
	//             |         |              |                   |        |
	    @API_PROTOCOL,   subdomain,    @API_BASE_URL,    @API_VERSION,   lang];

//	_isAlphaEnvironment = [_apiURL containsSubstring:@"alpha"];
}

- (instancetype)init
{
	if (self = [super init])
	{
		if (![self isMemberOfClass:[TKAPI class]])
			@throw @"API class cannot be inherited";

		[self refreshServerProperties];
	}

	return self;
}

- (void)setAPIKey:(NSString *)APIKey
{
	_APIKey = [APIKey copy];
}

- (void)setLanguageID:(NSString *)languageID
{
	_languageID = languageID;

	[self refreshServerProperties];
}

- (NSString *)hostname
{
	return [NSURL URLWithString:self.apiURL].host;
}

- (NSString *)URLStringForPath:(NSString *)path
{
	NSMutableString *ret = [_apiURL mutableCopy];

	// Append path

	if (![path hasPrefix:@"/"])
		[ret appendString:@"/"];

	[ret appendString:path];

	// Return

	return [ret copy];
}

- (NSString *)URLStringForRequestType:(TKAPIRequestType)type path:(NSString *)path
{
	NSMutableString *ret = [_apiURL mutableCopy];

	// Append path

	if (![path hasPrefix:@"/"])
		@throw [NSString stringWithFormat:@"Invalid path prefix for API request of type %ld", (long)type];

	[ret appendString:path];

	// Return

	return [ret copy];
}

- (NSString *)pathForRequestType:(TKAPIRequestType)type
{
	return [self pathForRequestType:type ID:nil];
}

- (NSString *)pathForRequestType:(TKAPIRequestType)type ID:(NSString *)ID
{
	switch (type) {

	case TKAPIRequestTypePlacesQueryGET: // GET
		return @"/places/list";

	case TKAPIRequestTypePlacesBatchGET: // GET
		return @"/places";

	case TKAPIRequestTypePlaceGET: // GET
		return [NSString stringWithFormat:@"/places/%@", ID];

	case TKAPIRequestTypeCollectionsQueryGET: // GET
		return @"/collections";

	case TKAPIRequestTypeToursQueryGET: // GET
		return @"/tours";

	case TKAPIRequestTypeMediaGET: // GET
		return [NSString stringWithFormat:@"/places/%@/media", ID];

	case TKAPIRequestTypeTripGET: // GET
	case TKAPIRequestTypeTripUPDATE: // PUT
		return [NSString stringWithFormat:@"/trips/%@", ID];

	case TKAPIRequestTypeTripNEW: // POST
		return @"/trips";

	case TKAPIRequestTypeTrashEMPTY: // DELETE
		return @"/trips/trash";

	case TKAPIRequestTypeTripsBatchGET: // GET
		return @"/trips";

	case TKAPIRequestTypeFavoriteADD: // POST
	case TKAPIRequestTypeFavoriteDELETE: // DELETE
		return @"/favorites";

	case TKAPIRequestTypeChangesGET: // GET
		return @"/changes";

	case TKAPIRequestTypeDirectionsGET: // POST
		return @"/directions";

//	case TKAPIRequestTypeExchangeRatesGET: // GET
//		return @"/exchange-rates";

	default:
		@throw [NSException exceptionWithName:@"Unsupported request"
			reason:@"Unsupported request type given" userInfo:nil];

	}
}

- (NSString *)HTTPMethodForRequestType:(TKAPIRequestType)type
{
	switch (type)
	{
		case TKAPIRequestTypeFavoriteADD:
		case TKAPIRequestTypeTripNEW:
		case TKAPIRequestTypeDirectionsGET:
			return @"POST";

		case TKAPIRequestTypeTripUPDATE:
			return @"PUT";

		case TKAPIRequestTypeFavoriteDELETE:
		case TKAPIRequestTypeTrashEMPTY:
			return @"DELETE";

		default: return @"GET";
	}
}

- (BOOL)authorizationRequiredForRequestType:(TKAPIRequestType)type
{
	switch (type)
	{
		case TKAPIRequestTypeFavoriteADD:
		case TKAPIRequestTypeFavoriteDELETE:
		case TKAPIRequestTypeTripGET:
		case TKAPIRequestTypeTripNEW:
		case TKAPIRequestTypeTripUPDATE:
		case TKAPIRequestTypeTrashEMPTY:
		case TKAPIRequestTypeTripsBatchGET:
		case TKAPIRequestTypeChangesGET:
			return YES;

		default: return NO;
	}
}

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark - API connection -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@class TKAPIConnection;
@protocol TKAPIConnectionDelegate <NSObject>

@required
- (void)connectionDidFinish:(TKAPIConnection *)connection;

@end


@interface TKAPIConnection : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, weak) id<TKAPIConnectionDelegate> delegate;

@property (atomic) NSInteger responseStatus;
@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, strong, readonly) NSURLSessionTask *task;
@property (nonatomic, strong, readonly) NSMutableURLRequest *request;

@property (atomic) BOOL silent;

// Initializers
- (instancetype)initWithURLRequest:(NSMutableURLRequest *)request
	success:(TKAPISuccessBlock)success failure:(TKAPIFailureBlock)failure;

// Connection control
- (BOOL)start;
- (BOOL)cancel;

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark - API request -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@interface TKAPIRequest () <TKAPIConnectionDelegate>

@property (class, nonatomic, readonly) NSOperationQueue *responseQueue;

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *pathID;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *query;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *HTTPHeaders;
@property (nonatomic, copy) NSData *data;

@property (nonatomic, strong) TKAPIConnection *connection;
@property (nonatomic, copy) TKAPISuccessBlock successBlock;
@property (nonatomic, copy) TKAPIFailureBlock failureBlock;

@end

@implementation TKAPIRequest

#pragma mark -
#pragma mark Class stuff

+ (NSOperationQueue *)responseQueue
{
	static NSOperationQueue *queue = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		queue = [NSOperationQueue new];
		queue.name = @"API Request-Response queue";
		queue.qualityOfService = NSQualityOfServiceDefault;
	});

	return queue;
}

#pragma mark -
#pragma mark Lifecycle

- (instancetype)init
{
	if (self = [super init])
	{
		_connection = nil;
		_type = TKAPIRequestTypeUnknown;
		_state = TKAPIRequestStateInit;
	}

	return self;
}

- (void)start
{
	_state = TKAPIRequestStatePending;

	TKAPI *api = [TKAPI sharedAPI];

	if (!_path) _path = [api pathForRequestType:_type ID:_pathID];

	NSString *urlString = [api URLStringForRequestType:_type path:_path];

	if (_query.count) {

		NSMutableCharacterSet *set = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
		[set removeCharactersInString:@"+=?&"];

		NSMutableArray<NSString *> *items = [NSMutableArray arrayWithCapacity:4];

		[_query enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *val, BOOL *__unused stop) {
			val = [val stringByAddingPercentEncodingWithAllowedCharacters:set];
			[items addObject:[NSString stringWithFormat:@"%@=%@", key, val]];
		}];

		NSString *query = [items componentsJoinedByString:@"&"];
		NSString *sep = [urlString containsString:@"?"] ? @"&":@"?";
		query = [NSString stringWithFormat:@"%@%@", sep, query];

		urlString = [urlString stringByAppendingString:query];
	}

	NSURL *url = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	request.HTTPMethod = [api HTTPMethodForRequestType:_type];

	NSAssert(request != nil, @"[API] Failed to initiate API request: %@", urlString);

	NSTimeInterval timeout = API_CALL_TIMEOUT_DEFAULT;
	if (_type == TKAPIRequestTypePlacesQueryGET) timeout = API_CALL_TIMEOUT_QUICK;
	else if (_type == TKAPIRequestTypeTripsBatchGET || _type == TKAPIRequestTypePlacesBatchGET) timeout = API_CALL_TIMEOUT_BATCH;
	else if (_type == TKAPIRequestTypeChangesGET) timeout = API_CALL_TIMEOUT_CHANGES;

	request.timeoutInterval = timeout;

	if (_data.length) {
		[request setHTTPBody:_data];
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[request setValue:[NSString stringWithFormat:@"%tu", _data.length] forHTTPHeaderField:@"Content-Length"];
	}

	NSString *apiKey = _APIKey ?: api.APIKey;
	NSString *accessToken = _accessToken ?: api.accessToken;

	if (apiKey.length)
		[request setValue:apiKey forHTTPHeaderField:@"X-API-Key"];

	if (accessToken.length)
		if ([api authorizationRequiredForRequestType:_type])
			[request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken]
				forHTTPHeaderField:@"Authorization"];

	for (NSString *header in _HTTPHeaders.allKeys)
		[request setValue:_HTTPHeaders[header] forHTTPHeaderField:header];

	NSOperationQueue *queue = _completionQueue ?: [self.class responseQueue];

	TKAPISuccessBlock success = ^(TKAPIResponse *response) {
		self->_state = TKAPIRequestStateFinished;
		TKAPISuccessBlock successBlock = self->_successBlock;
		if (successBlock)
			[queue addOperationWithBlock:^{
				successBlock(response);
			}];
	};

	TKAPIFailureBlock failure = ^(TKAPIError *error) {
		self->_state = TKAPIRequestStateFinished;
		TKAPIFailureBlock failureBlock = self->_failureBlock;
		if (failureBlock)
			[queue addOperationWithBlock:^{
				failureBlock(error);
			}];
	};

	_connection = [[TKAPIConnection alloc] initWithURLRequest:request success:success failure:failure];
	_connection.identifier = self.typeString;
	_connection.delegate = self;
	_connection.silent = _silent;

	[_connection start];
}

- (void)silentStart
{
	_silent = YES;
	[self start];
}

- (void)cancel
{
	_state = TKAPIRequestStateFinished;
	[_connection cancel];
}


////////////////////
#pragma mark - Connection delegate
////////////////////


- (void)connectionDidFinish:(__unused TKAPIConnection *)connection
{
	_connection = nil;
	_successBlock = nil;
	_failureBlock = nil;
}


////////////////////
#pragma mark - Changes
////////////////////


- (instancetype)initAsChangesRequestSince:(NSDate *)sinceDate
	success:(void (^)(TKAPIChangesResult *))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeChangesGET;

		if (sinceDate)
		{
			NSString *timestamp = [[NSDateFormatter shared8601DateTimeFormatter] stringFromDate:sinceDate];
			if (timestamp) _query = @{ @"since": timestamp };
		}

		_successBlock = ^(TKAPIResponse *response){

			// Prepare structures for response data
			NSMutableDictionary<NSString *, NSNumber *>
			    *updatedTripsDict = [NSMutableDictionary dictionaryWithCapacity:5];
			NSMutableArray<NSString *>
			    *deletedTripIDs = [NSMutableArray arrayWithCapacity:5],
			    *updatedCustomPlaceIDs = [NSMutableArray arrayWithCapacity:5],
			    *deletedCustomPlaceIDs = [NSMutableArray arrayWithCapacity:5],
			    *updatedFavouriteItemIDs = [NSMutableArray arrayWithCapacity:5],
			    *deletedFavouriteItemIDs = [NSMutableArray arrayWithCapacity:5];
			BOOL settingsUpdated = NO;

			NSArray<NSDictionary *> *events = [response.data[@"changes"] parsedArray];

			// Loop through the events
			for (NSDictionary *event in events)
			{
				NSString *type = [event[@"type"] parsedString];
				NSString *change = [event[@"change"] parsedString];
				NSString *ID = [event[@"id"] parsedString];

				if (!type) continue;

				// Trip updates

				if ([type isEqualToString:@"trip"])
				{
					NSNumber *version = [event[@"version"] parsedNumber] ?: @0;
					if (!ID) continue;
					if ([change isEqualToString:@"updated"])
						updatedTripsDict[ID] = version;
					else if (sinceDate && [change isEqualToString:@"deleted"])
						[deletedTripIDs addObject:ID];
				}

				// Custom Places updates

				else if ([type isEqualToString:@"custom_place"])
				{
					if (!ID) continue;
					if ([change isEqualToString:@"updated"])
						[updatedCustomPlaceIDs addObject:ID];
					else if (sinceDate && [change isEqualToString:@"deleted"])
						[deletedCustomPlaceIDs addObject:ID];
				}

				// Favourites updates

				else if ([type isEqualToString:@"favorite"])
				{
					if (!ID) continue;
					if ([change isEqualToString:@"updated"])
						[updatedFavouriteItemIDs addObject:ID];
					else if (sinceDate && [change isEqualToString:@"deleted"])
						[deletedFavouriteItemIDs addObject:ID];
				}

				// Settings updates

				else if ([type isEqualToString:@"settings"])
					if ([change isEqualToString:@"updated"])
						settingsUpdated = YES;
			}

			// Get Changes timestamp
			NSDate *datestamp = response.timestamp ?: [[NSDate now] dateByAddingTimeInterval:-5];

			// Fill in the result object
			TKAPIChangesResult *result = [TKAPIChangesResult new];
			result.updatedTripsDict = updatedTripsDict;
			result.deletedTripIDs = deletedTripIDs;
			result.updatedCustomPlaceIDs = updatedCustomPlaceIDs;
			result.deletedCustomPlaceIDs = deletedCustomPlaceIDs;
			result.updatedFavouriteIDs = updatedFavouriteItemIDs;
			result.deletedFavouriteIDs = deletedFavouriteItemIDs;
			result.updatedSettings = settingsUpdated;
			result.timestamp = datestamp;

			if (success) success(result);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Trips
////////////////////

- (instancetype)initAsTripRequestForTripWithID:(NSString *)tripID
	success:(void (^)(TKTrip *trip))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeTripGET;
		_pathID = [tripID copy];

		_successBlock = ^(TKAPIResponse *response){

			NSDictionary *tripDict = [response.data[@"trip"] parsedDictionary];
			TKTrip *trip = nil;

			if (tripDict) trip = [[TKTrip alloc] initFromResponse:tripDict];

			if (trip && success) success(trip);
			if (!trip && failure) failure([TKAPIError errorWithCode:32478
				userInfo:@{ NSLocalizedDescriptionKey: @"Trip parsing failed" }]);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsNewTripRequestForTrip:(TKTrip *)trip
	success:(void (^)(TKTrip *trip))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeTripNEW;
		_data = [[trip asRequestDictionary] asJSONData];

		_successBlock = ^(TKAPIResponse *response){

			NSDictionary *tripDict = [response.data[@"trip"] parsedDictionary];
			TKTrip *newTrip = nil;

			if (tripDict) newTrip = [[TKTrip alloc] initFromResponse:tripDict];

			if (trip && success) success(newTrip);
			if (!trip && failure) failure([TKAPIError errorWithCode:32412
				userInfo:@{ NSLocalizedDescriptionKey: @"Trip parsing failed" }]);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsUpdateTripRequestForTrip:(TKTrip *)trip
	success:(void (^)(TKTrip *, TKTripConflict *))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeTripUPDATE;
		_pathID = [trip.ID copy];
		_data = [[trip asRequestDictionary] asJSONData];

		_successBlock = ^(TKAPIResponse *response){

			NSDictionary *tripDict = [response.data[@"trip"] parsedDictionary];
			TKTrip *updatedTrip = (tripDict) ? [[TKTrip alloc] initFromResponse:tripDict] : nil;

			TKTripConflict *conflict = nil;
			NSString *resolution = [response.data[@"conflict_resolution"] parsedString];

			// If pushed Trip update has been ignored,
			// add Trips pair to conflicts holding structure
			if (trip && updatedTrip && [resolution containsString:@"ignored"])
			{
				NSDictionary *conflictDict = [response.data[@"conflict_info"] parsedDictionary];
				NSString *editor = [conflictDict[@"last_user_name"] parsedString];
				NSString *dateStr = [conflictDict[@"last_updated_at"] parsedString];
				NSDate *updateDate = [NSDate dateFrom8601DateTimeString:dateStr];

				conflict = [[TKTripConflict alloc] initWithLocalTrip:trip
					remoteTrip:updatedTrip remoteTripEditor:editor remoteTripUpdateDate:updateDate];
			}

			if (updatedTrip && success) success(updatedTrip, conflict);
			if (!updatedTrip && failure) failure([TKAPIError errorWithCode:16568
				userInfo:@{ NSLocalizedDescriptionKey: @"Trip parsing failed" }]);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsEmptyTrashRequestWithSuccess:(void (^)(NSArray<NSString *> *tripIDs))success
	failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeTrashEMPTY;

		_successBlock = ^(TKAPIResponse *response) {

			NSDictionary *data = [response.data parsedDictionary];
			NSArray<NSString *> *tripIDs = [[data[@"deleted_trip_ids"] parsedArray]
			  mappedArrayUsingBlock:^NSString *(id obj) {
				return [obj parsedString];
			}];

			if (success) success(tripIDs);

		}; _failureBlock = ^(TKAPIError *error) {
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsBatchTripRequestForIDs:(NSArray<NSString *> *)tripIDs
	success:(void (^)(NSArray<TKTrip *> *))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeTripsBatchGET;
		_query = @{ @"ids": [tripIDs componentsJoinedByString:@"|"] ?: @"" };

		_successBlock = ^(TKAPIResponse *response){

			NSArray *tripsArray = [response.data[@"trips"] parsedArray];
			NSMutableArray<TKTrip *> *trips = [NSMutableArray array];

			for (NSDictionary *dict in tripsArray)
			{
				if (![dict parsedDictionary]) continue;

				TKTrip *t = [[TKTrip alloc] initFromResponse:dict];
				if (t) [trips addObject:t];
			}

			if (success)
				success(trips);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Places Query
////////////////////


- (instancetype)initAsPlacesRequestForQuery:(TKPlacesQuery *)query
	success:(void (^)(NSArray<TKPlace *> *))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypePlacesQueryGET;

		NSMutableDictionary<NSString *, NSString *> *queryDict = [NSMutableDictionary dictionaryWithCapacity:10];

		if (query.searchTerm.length)
			queryDict[@"query"] = query.searchTerm;

		if (query.levels)
		{
			NSMutableArray<NSString *> *levels = [NSMutableArray arrayWithCapacity:3];
			NSDictionary<NSNumber *, NSString *> *supportedLevels = [TKPlace levelStrings];

			for (NSNumber *sl in supportedLevels.allKeys)
			{
				TKPlaceLevel cl = sl.unsignedIntegerValue;
				if (!(query.levels & cl)) continue;
				NSString *lev = supportedLevels[sl];
				if (lev) [levels addObject:lev];
			}

			NSString *lstr = [levels componentsJoinedByString:@"|"];

			if (lstr.length) queryDict[@"levels"] = lstr;
		}

		if (query.preferredLocation)
			queryDict[@"preferred_location"] = [NSString stringWithFormat:@"%f,%f",
				query.preferredLocation.coordinate.latitude,
				query.preferredLocation.coordinate.longitude
			];

		if (query.quadKeys.count)
		{
			NSString *joined = [query.quadKeys componentsJoinedByString:@"|"];
			queryDict[@"map_tiles"] = joined;
		}

		if (query.mapSpread.intValue > 0)
			queryDict[@"map_spread"] = query.mapSpread.stringValue;

		if (query.bounds)
			queryDict[@"bounds"] = [NSString stringWithFormat:@"%.6f,%.6f,%.6f,%.6f",
					query.bounds.southWestPoint.coordinate.latitude,
					query.bounds.southWestPoint.coordinate.longitude,
					query.bounds.northEastPoint.coordinate.latitude,
					query.bounds.northEastPoint.coordinate.longitude
				 ];

		if (query.categories)
		{
			NSMutableArray<NSString *> *slugs = [NSMutableArray arrayWithCapacity:3];
			NSDictionary<NSNumber *, NSString *> *supportedSlugs = [TKPlace categorySlugs];

			for (NSNumber *sl in supportedSlugs.allKeys)
			{
				TKPlaceCategory cat = sl.unsignedIntegerValue;
				if (!(query.categories & cat)) continue;
				NSString *slug = supportedSlugs[sl];
				if (slug) [slugs addObject:slug];
			}

			NSString *operator = (query.categoriesMatching == TKPlacesQueryMatchingAll) ? @"," : @"|";
			queryDict[@"categories"] = [slugs componentsJoinedByString:operator];
		}

		if (query.tags.count)
		{
			NSString *operator = (query.tagsMatching == TKPlacesQueryMatchingAll) ? @"," : @"|";
			queryDict[@"tags"] = [query.tags componentsJoinedByString:operator];
		}

		if (query.parentIDs.count)
		{
			NSString *operator = (query.parentIDsMatching == TKPlacesQueryMatchingAll) ? @"," : @"|";
			queryDict[@"parents"] = [query.parentIDs componentsJoinedByString:operator];
		}

		if (query.minimumRating != nil || query.maximumRating != nil)
		{
			NSString *minString = (query.minimumRating != nil) ?
				[NSString stringWithFormat:@"%.5f", query.minimumRating.floatValue] : @"";
			NSString *maxString = (query.maximumRating != nil) ?
				[NSString stringWithFormat:@"%.5f", query.maximumRating.floatValue] : @"";
			queryDict[@"rating"] = [NSString stringWithFormat:@"%@:%@",
				minString, maxString];
		}

		if (query.limit.intValue > 0)
			queryDict[@"limit"] = [query.limit stringValue];

		if (query.offset.intValue > 0)
			queryDict[@"offset"] = [query.offset stringValue];

		_query = queryDict;

		_successBlock = ^(TKAPIResponse *response){

			NSMutableArray<TKPlace *> *stored = [NSMutableArray array];
			NSArray *items = [response.data[@"places"] parsedArray];

			for (NSDictionary *dict in items)
			{
				if (![dict parsedDictionary]) continue;
				NSString *guid = [dict[@"id"] parsedString];
				if (!guid) continue;

				TKPlace *a = [[TKPlace alloc] initFromResponse:dict];
				if (a) [stored addObject:a];
			}

			if (success) success(stored);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Places Batch
////////////////////


- (instancetype)initAsPlacesRequestForIDs:(NSArray<NSString *> *)placeIDs
	success:(void (^)(NSArray<TKDetailedPlace *> *))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypePlacesBatchGET;
		_query = @{ @"ids": [placeIDs componentsJoinedByString:@"|"] ?: @"" };

		_successBlock = ^(TKAPIResponse *response){

			NSMutableArray<TKDetailedPlace *> *stored = [NSMutableArray array];
			NSArray *items = [response.data[@"places"] parsedArray];

			for (NSDictionary *dict in items)
			{
				if (![dict parsedDictionary]) continue;
				NSString *guid = [dict[@"id"] parsedString];
				if (!guid) continue;

				TKDetailedPlace *a = [[TKDetailedPlace alloc] initFromResponse:dict];
				if (a) [stored addObject:a];
			}

			if (success) success(stored);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Place
////////////////////


- (instancetype)initAsPlaceRequestForItemWithID:(NSString *)itemID
	success:(void (^)(TKDetailedPlace *))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypePlaceGET;
		_pathID = itemID;

		_successBlock = ^(TKAPIResponse *response){

			TKDetailedPlace *place = nil;
			NSDictionary *item = [response.data[@"place"] parsedDictionary];

			if (item) place = [[TKDetailedPlace alloc] initFromResponse:item];

			if (!place && failure) failure(nil);
			if (place && success) success(place);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Collections Query
////////////////////


- (instancetype)initAsCollectionsRequestForQuery:(TKCollectionsQuery *)query
	success:(void (^)(NSArray<TKCollection *> *))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeCollectionsQueryGET;

		NSMutableDictionary<NSString *, NSString *> *queryDict = [NSMutableDictionary dictionaryWithCapacity:10];

		if (query.searchTerm.length)
			queryDict[@"query"] = query.searchTerm;

		if (query.parentPlaceID.length)
			queryDict[@"parent_place_id"] = query.parentPlaceID;

		if (query.placeIDs.count)
		{
			NSString *operator = (query.placeIDsMatching == TKCollectionsQueryMatchingAll) ? @"," : @"|";
			queryDict[@"place_ids"] = [query.placeIDs componentsJoinedByString:operator];
		}

		if (query.tags.count)
			queryDict[@"tags"] = [query.tags componentsJoinedByString:@","];

		if (query.tagsToOmit.count)
			queryDict[@"tags_not"] = [query.tagsToOmit componentsJoinedByString:@","];

		if (query.limit.intValue > 0)
			queryDict[@"limit"] = [query.limit stringValue];

		if (query.offset.intValue > 0)
			queryDict[@"offset"] = [query.offset stringValue];

		if (query.preferUnique)
			queryDict[@"prefer_unique"] = @"1";

		_query = queryDict;

		_successBlock = ^(TKAPIResponse *response){

			NSMutableArray<TKCollection *> *stored = [NSMutableArray array];
			NSArray *items = [response.data[@"collections"] parsedArray];

			for (NSDictionary *dict in items)
			{
				TKCollection *c = [[TKCollection alloc] initFromResponse:dict];
				if (c) [stored addObject:c];
			}

			if (success) success(stored);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Tours Queries
////////////////////


- (instancetype)initAsViatorToursRequestForQuery:(TKToursViatorQuery *)query
	success:(void (^)(NSArray<TKTour *> *))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeToursQueryGET;

		NSMutableString *path = [[[TKAPI sharedAPI] pathForRequestType:_type] mutableCopy];

		[path appendFormat:@"/viator"];

		_path = path;

		NSMutableDictionary<NSString *, NSString *> *queryDict = [NSMutableDictionary dictionaryWithCapacity:5];

		if (query.parentID)
			queryDict[@"parent_place_id"] = query.parentID;

		if (query.sortingType)
		{
			NSString *type = @"rating";
			if (query.sortingType == TKToursViatorQuerySortingPrice) type = @"price";
			else if (query.sortingType == TKToursViatorQuerySortingTopSellers) type = @"top_sellers";
			queryDict[@"sort_by"] = type;
		}

		{
			NSString *direction = (query.descendingSortingOrder) ? @"desc" : @"asc";
			queryDict[@"sort_direction"] = direction;
		}

		if (query.pageNumber != nil)
		{
			NSUInteger page = query.pageNumber.unsignedIntegerValue;
			if (page > 1) queryDict[@"page"] = [query.pageNumber stringValue];
		}

		_query = queryDict;

		_successBlock = ^(TKAPIResponse *response){

			NSMutableArray<TKTour *> *stored = [NSMutableArray array];
			NSArray *items = [response.data[@"tours"] parsedArray];

			for (NSDictionary *dict in items)
			{
				if (![dict parsedDictionary]) continue;
				NSString *guid = [dict[@"id"] parsedString];
				if (!guid) continue;

				TKTour *a = [[TKTour alloc] initFromResponse:dict];
				if (a) [stored addObject:a];
			}

			if (success) success(stored);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsGYGToursRequestForQuery:(TKToursGYGQuery *)query
	success:(void (^)(NSArray<TKTour *> *))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeToursQueryGET;

		NSMutableString *path = [[[TKAPI sharedAPI] pathForRequestType:_type] mutableCopy];

		[path appendFormat:@"/get-your-guide"];

		_path = path;

		NSMutableDictionary<NSString *, NSString *> *queryDict = [NSMutableDictionary dictionaryWithCapacity:10];

		if (query.parentID)
			queryDict[@"parent_place_id"] = query.parentID;

		if (query.sortingType)
		{
			NSString *type = @"popularity";
			if (query.sortingType == TKToursGYGQuerySortingPrice) type = @"price";
			else if (query.sortingType == TKToursGYGQuerySortingRating) type = @"rating";
			else if (query.sortingType == TKToursGYGQuerySortingDuration) type = @"duration";
			queryDict[@"sort_by"] = type;
		}

		{
			NSString *direction = (query.descendingSortingOrder) ? @"desc" : @"asc";
			queryDict[@"sort_direction"] = direction;
		}

		if (query.pageNumber.unsignedIntegerValue > 1)
			queryDict[@"page"] = [query.pageNumber stringValue];

		if (query.count != nil)
			queryDict[@"count"] = [query.count stringValue];

		if (query.searchTerm)
			queryDict[@"query"] = query.searchTerm;

		if (query.minimalDuration != nil || query.maximalDuration != nil)
			queryDict[@"duration"] = [NSString stringWithFormat:@"%@:%@",
				query.minimalDuration ?: @"", query.maximalDuration ?: @""];

		NSDate *date = nil;

		if ((date = query.startDate))
			queryDict[@"from"] = [[NSDateFormatter shared8601DateTimeFormatter] stringFromDate:date] ?: @"";

		if ((date = query.endDate))
			queryDict[@"to"] = [[NSDateFormatter shared8601DateTimeFormatter] stringFromDate:date] ?: @"";

		if (query.bounds)
			queryDict[@"bounds"] = [NSString stringWithFormat:@"%.5f,%.5f,%.5f,%.5f",
				query.bounds.southWestPoint.coordinate.latitude,
				query.bounds.southWestPoint.coordinate.longitude,
				query.bounds.northEastPoint.coordinate.latitude,
				query.bounds.northEastPoint.coordinate.longitude];

		_query = queryDict;

		_successBlock = ^(TKAPIResponse *response){

			NSMutableArray<TKTour *> *stored = [NSMutableArray array];
			NSArray *items = [response.data[@"tours"] parsedArray];

			for (NSDictionary *dict in items)
			{
				if (![dict parsedDictionary]) continue;
				NSString *guid = [dict[@"id"] parsedString];
				if (!guid) continue;

				TKTour *a = [[TKTour alloc] initFromResponse:dict];
				if (a) [stored addObject:a];
			}

			if (success) success(stored);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Media
////////////////////


- (instancetype)initAsMediaRequestForPlaceWithID:(NSString *)placeID
	success:(void (^)(NSArray<TKMedium *> *media))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeMediaGET;
		_pathID = [placeID copy];

		_successBlock = ^(TKAPIResponse *response){

			NSDictionary *data = [response.data parsedDictionary];

			NSArray *media = [data[@"media"] parsedArray];
			NSMutableArray<TKMedium *> *ret = [NSMutableArray arrayWithCapacity:media.count];

			for (NSDictionary *mediumDict in media)
			{
				if (![mediumDict isKindOfClass:[NSDictionary class]]) continue;

				TKMedium *m = [[TKMedium alloc] initFromResponse:mediumDict];
				if (m) [ret addObject:m];
			}

			if (success) success(ret);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Favorites
////////////////////


- (instancetype)initAsFavoriteItemAddRequestWithID:(NSString *)itemID
	success:(void (^)(void))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeFavoriteADD;
		_data = [@{ @"place_id": itemID ?: [NSNull null] } asJSONData];

		_successBlock = ^(TKAPIResponse *__unused response){
			if (success) success();
		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsFavoriteItemDeleteRequestWithID:(NSString *)itemID
	success:(void (^)(void))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeFavoriteDELETE;
		_data = [@{ @"place_id": itemID ?: [NSNull null] } asJSONData];

		_successBlock = ^(TKAPIResponse *__unused response){
			if (success) success();
		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Directions
////////////////////


- (instancetype)initAsDirectionsRequestForQuery:(TKDirectionsQuery *)query
	success:(void (^)(TKDirectionsSet *))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeDirectionsGET;

		TKDirectionMode modeFlag = query.mode;
		TKDirectionAvoidOption avoidFlag = query.avoidOption;

		NSArray<NSString *> *modeOpts = [@[ @"pedestrian", @"car", @"public_transit" ]
		mappedArrayUsingBlock:^NSString *(NSString *mode) {
			if      ([mode isEqual:@"pedestrian"]) return (modeFlag & TKDirectionModeWalk) ? mode : nil;
			else if ([mode isEqual:@"car"]) return (modeFlag & TKDirectionModeCar) ? mode : nil;
			else if ([mode isEqual:@"public_transit"]) return (modeFlag & TKDirectionModePublicTransport) ? mode : nil;
			return nil;
		}];

		NSArray<NSString *> *avoidOpts = [@[ @"tolls", @"highways", @"ferries", @"unpaved" ]
		mappedArrayUsingBlock:^NSString *(NSString *avoid) {
			if      ([avoid isEqual:@"tolls"]) return (avoidFlag & TKDirectionAvoidOptionTolls) ? avoid : nil;
			else if ([avoid isEqual:@"highways"]) return (avoidFlag & TKDirectionAvoidOptionHighways) ? avoid : nil;
			else if ([avoid isEqual:@"ferries"]) return (avoidFlag & TKDirectionAvoidOptionFerries) ? avoid : nil;
			else if ([avoid isEqual:@"unpaved"]) return (avoidFlag & TKDirectionAvoidOptionUnpaved) ? avoid : nil;
			return nil;
		}];

		NSArray<NSDictionary *> *waypointObjs = [query.waypoints mappedArrayUsingBlock:^NSDictionary *(CLLocation *obj) {
			return @{ @"location": @{ @"lat": @(obj.coordinate.latitude), @"lng": @(obj.coordinate.longitude) } };
		}];

		NSDateFormatter *df = [NSDateFormatter shared8601RelativeDateTimeFormatter];

		id departure = nil, arrival = nil;

		NSDate *date = nil;
		if ((date = query.relativeDepartureDate))
			departure = [df stringFromDate:date];
		if ((date = query.relativeArrivalDate))
			arrival = [df stringFromDate:date];

		NSDictionary *post = @{
			@"modes": modeOpts,
			@"origin": @{ @"lat": @(query.sourceLocation.coordinate.latitude), @"lng": @(query.sourceLocation.coordinate.longitude) },
			@"destination": @{ @"lat": @(query.destinationLocation.coordinate.latitude), @"lng": @(query.destinationLocation.coordinate.longitude) },
			@"waypoints": waypointObjs ?: @[ ], @"avoid": avoidOpts,
			@"depart_at": departure ?: [NSNull null], @"arrive_at": arrival ?: [NSNull null],
		};

		_data = [post asJSONData];

		_successBlock = ^(TKAPIResponse *response){

			NSDictionary *reponseDict = [response.data parsedDictionary];
			TKDirectionsSet *set = [[TKDirectionsSet alloc] initFromDictionary:reponseDict];

			if (set && success) success(set);
			if (!set && failure) failure(nil);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Exchange rates
////////////////////


- (instancetype)initAsExchangeRatesRequestWithSuccess:(void (^)(NSDictionary<NSString *, NSNumber *> *))success
	failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeExchangeRatesGET;

		_successBlock = ^(TKAPIResponse *response){

			NSMutableDictionary<NSString *, NSNumber *> *exchangeRates = [NSMutableDictionary dictionaryWithCapacity:10];

			for (NSDictionary *e in [response.data[@"exchange_rates"] parsedArray])
			{
				if (![e parsedDictionary]) continue;

				NSString *code = [e[@"code"] parsedString];
				NSNumber *rate = [e[@"rate"] parsedNumber];

				if (code != nil && rate != nil)
					exchangeRates[code] = rate;
			}

			if (success) success(exchangeRates);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Custom requests
////////////////////


- (instancetype)initAsCustomGETRequestWithPath:(NSString *)path
	success:(void (^)(id))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeCustomGET;
		_path = path;

		_successBlock = ^(TKAPIResponse *response){

			if (success)
				success(response.data);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsCustomPOSTRequestWithPath:(NSString *)path
	json:(NSString *)json success:(void (^)(id))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeCustomPOST;
		_path = path;
		_data = [json dataUsingEncoding:NSUTF8StringEncoding];

		_successBlock = ^(TKAPIResponse *response){

			if (success)
				success(response.data);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsCustomPUTRequestWithPath:(NSString *)path json:(NSString *)json
	success:(void (^)(id))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeCustomPUT;
		_path = path;
		_data = [json dataUsingEncoding:NSUTF8StringEncoding];

		_successBlock = ^(TKAPIResponse *response){

			if (success)
				success(response.data);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsCustomDELETERequestWithPath:(NSString *)path json:(NSString *)json
	success:(void (^)(id))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeCustomDELETE;
		_path = path;
		_data = [json dataUsingEncoding:NSUTF8StringEncoding];

		_successBlock = ^(TKAPIResponse *response){

			if (success)
				success(response.data);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}

#pragma mark -
#pragma mark Utility functions

- (NSString *)typeString
{
	static NSDictionary *types = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		types = @{
			@(TKAPIRequestTypePlacesQueryGET): @"PLACES_QUERY_GET",
			@(TKAPIRequestTypePlacesBatchGET): @"PLACES_BATCH_GET",
			@(TKAPIRequestTypePlaceGET): @"PLACE_GET",
			@(TKAPIRequestTypeToursQueryGET): @"TOURS_QUERY_GET",
			@(TKAPIRequestTypeMediaGET): @"MEDIA_GET",
			@(TKAPIRequestTypeFavoriteADD): @"FAVORITE_ADD",
			@(TKAPIRequestTypeFavoriteDELETE): @"FAVORITE_DELETE",
			@(TKAPIRequestTypeTripGET): @"TRIP_GET",
			@(TKAPIRequestTypeTripNEW): @"TRIP_NEW",
			@(TKAPIRequestTypeTripUPDATE): @"TRIP_UPDATE",
			@(TKAPIRequestTypeTrashEMPTY): @"TRASH_EMPTY",
			@(TKAPIRequestTypeTripsBatchGET): @"TRIPS_BATCH_GET",
			@(TKAPIRequestTypeChangesGET): @"CHANGES_GET",
			@(TKAPIRequestTypeExchangeRatesGET): @"EXCHANGE_RATES_GET",
			@(TKAPIRequestTypeCustomGET): @"CUSTOM_GET",
			@(TKAPIRequestTypeCustomPOST): @"CUSTOM_POST",
			@(TKAPIRequestTypeCustomPUT): @"CUSTOM_PUT",
			@(TKAPIRequestTypeCustomDELETE): @"CUSTOM_DELETE",
		};
	});

	return types[@(_type)] ?: @"UNKNOWN";
}

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark - Changes API result -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@implementation TKAPIChangesResult

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark - API response -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@implementation TKAPIResponse

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
	if (self = [super init])
	{
		_code = [[dictionary[@"status_code"] parsedNumber] integerValue];
		_data = dictionary[@"data"];

		NSString *timestamp = [dictionary[@"server_timestamp"] parsedString];
		if (timestamp) _timestamp =
			[[NSDateFormatter shared8601DateTimeFormatter] dateFromString:timestamp];

		// Give up invalid response
		if (!_code)
			return nil;

		NSMutableDictionary *meta = [NSMutableDictionary dictionary];
		for (NSString *key in dictionary.allKeys)
			if (![key isEqualToString:@"data"])
				meta[key] = dictionary[key];

		_metadata = meta;
	}

	return self;
}

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark - API error -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


NSString * const TKAPIErrorDomain = @"TKAPIErrorDomain";


@implementation TKAPIError

+ (instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary<NSErrorUserInfoKey,id> *)dict
{
	return [self errorWithDomain:TKAPIErrorDomain code:code userInfo:dict];
}

+ (instancetype)errorWithError:(NSError *)error
{
	if (!error) return nil;
	return [self errorWithDomain:error.domain code:error.code userInfo:error.userInfo];
}

+ (instancetype)errorWithResponse:(TKAPIResponse *)response
{
	return [[self alloc] initWithResponse:response];
}

- (instancetype)initWithResponse:(TKAPIResponse *)response
{
	NSString *ID = [response.metadata[@"error"][@"id"] parsedString] ?: @"error.unknown";

	NSArray<NSString *> *args = [[response.metadata[@"error"][@"args"] parsedArray]
	  filteredArrayUsingBlock:^BOOL(id obj) {
		return [obj isKindOfClass:[NSString class]];
	}];

	NSString *reason = [args componentsJoinedByString:@". "] ?: @"Unknown";

	NSDictionary *userInfo = @{
		NSLocalizedDescriptionKey: ID,
		NSLocalizedFailureReasonErrorKey: reason,
	};

	if (self = [self initWithDomain:TKAPIErrorDomain code:response.code userInfo:userInfo])
	{
		_ID = ID;
		_args = args;
		_response = response;
	}

	return self;
}

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark - API connection -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@interface TKAPIConnection ()

@property (nonatomic, strong) NSDate *startTimestamp;
@property (nonatomic, copy) TKAPISuccessBlock successBlock;
@property (nonatomic, copy) TKAPIFailureBlock failureBlock;

@end


@implementation TKAPIConnection

+ (NSString *)userAgentString
{
	static NSString *agent = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{

		NSMutableArray<NSString *> *concat = [NSMutableArray arrayWithCapacity:2];

		NSString *appName = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleNameKey] parsedString];
		NSString *appVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleVersionKey] parsedString];

		appName = [appName stringByTrimmingCharactersInRegexString:@"[^0-9a-zA-Z]"];
		appVersion = [appVersion stringByTrimmingCharactersInRegexString:@"[^0-9a-zA-Z.]"];

		if (appName && appVersion)
			[concat addObject:[NSString stringWithFormat:@"%@/%@", appName, appVersion]];

		NSString *sdkName = @"TravelKit";
		NSString *sdkVersion = [NSString stringWithFormat:@"%d", TRAVELKIT_BUILD];

		if (sdkName && sdkVersion)
			[concat addObject:[NSString stringWithFormat:@"%@/%@", sdkName, sdkVersion]];

		NSString *platformName = nil;
		NSString *platformVersion = nil;
#if TARGET_OS_IOS
		platformName = @"iOS";
#elif TARGET_OS_TV
		platformName = @"tvOS";
#elif TARGET_OS_OSX
		platformName = @"macOS";
#elif TARGET_OS_WATCH
		platformName = @"watchOS";
#endif

		NSOperatingSystemVersion ver = [NSProcessInfo processInfo].operatingSystemVersion;
		platformVersion = [NSString stringWithFormat:@"%ld.%ld.%ld",
		    (long)ver.majorVersion, (long)ver.minorVersion, (long)ver.patchVersion];

		if (platformName && platformVersion)
			[concat addObject:[NSString stringWithFormat:@"%@/%@", platformName, platformVersion]];

		agent = [concat componentsJoinedByString:@" "];
	});

	return agent;
}

+ (NSURLSession *)sharedURLSession
{
	static NSURLSession *session = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
		config.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
		config.timeoutIntervalForRequest = 4;
		session = [NSURLSession sessionWithConfiguration:config];
	});

	return session;
}

- (instancetype)initWithURLRequest:(NSMutableURLRequest *)request
	success:(TKAPISuccessBlock)success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_request = request;
		_URL = request.URL;
		_successBlock = success;
		_failureBlock = failure;

		request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

		[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
		[request setValue:[self.class userAgentString] forHTTPHeaderField:@"User-Agent"];
	}

	return self;
}

- (void)dealloc
{
	_URL = nil;
	_task = nil;
	_successBlock = nil;
	_failureBlock = nil;
}


#pragma mark - Connection control


- (BOOL)start
{
#ifdef LOG_API

	NSString *loggedStr = [NSString stringWithFormat:@"ID:%@ URL:%@  METHOD:%@",
		_identifier, _URL, _request.HTTPMethod];
	NSData *bodyData = _request.HTTPBody;

	if (bodyData.length)
	{
		NSString *sep = (_silent) ? @"" : @"\n";
		NSString *loggedData = (_silent) ?
			@"(...)" : [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
		loggedStr = [loggedStr stringByAppendingFormat:@"  DATA:%@%@", sep, loggedData];
	}

	NSLog(@"[API REQUEST] %@", loggedStr);

#endif

	if (_request)
	{
		_startTimestamp = [NSDate new];

		__auto_type __weak wself = self;

		_task = [[TKAPIConnection sharedURLSession] dataTaskWithRequest:_request
		  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

			// Retain API connection
			__auto_type sself = wself;

			// Process the response

			if ([response isKindOfClass:[NSHTTPURLResponse class]])
				sself.responseStatus = [(NSHTTPURLResponse *)response statusCode];

			if (error) [sself dataTaskDidFailWithError:error];
			else [sself dataTaskDidFinishWithResponse:response data:data];

		}];

		[_task resume];

		return YES;
	}
	else
	{
#ifdef LOG_API
		NSLog(@"[API REQUEST] Cannot initialize connection ID:%@ (%@)", _identifier, _URL);
#endif

		TKAPIError *error = [TKAPIError errorWithDomain:TKAPIErrorDomain code:-123 userInfo:
		  @{ NSDebugDescriptionErrorKey: @"Request initialisation failure" }];

		if (_failureBlock)
			_failureBlock(error);

		[self cleanupAndNotify];

		return NO;
	}
}

- (BOOL)cancel
{
	if (!_task) return NO;
	[_task cancel];
	return YES;
}

- (void)cleanupAndNotify
{
	if ([_delegate respondsToSelector:@selector(connectionDidFinish:)])
		[_delegate connectionDidFinish:self];

	_successBlock = nil;
	_failureBlock = nil;
}


#pragma mark - URL Session data task delegate


- (void)dataTaskDidFinishWithResponse:(__unused NSURLResponse *)response data:(NSData *)data
{
	// We've got all data from the server response
	// Now it's time to parse and process it

	NSError *error = nil;

	NSDictionary *dict = [[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error] parsedDictionary];

	if (!dict || error) {

		if (_responseStatus >= 400 || _responseStatus < 100)
			error = [TKAPIError errorWithDomain:TKAPIErrorDomain code:_responseStatus userInfo:nil];

#ifdef LOG_API
		NSTimeInterval duration = -[_startTimestamp timeIntervalSinceNow];
		NSURLRequest *failingRequest = _task.originalRequest ?: _request;
		NSDictionary *info = (error.userInfo.allKeys.count) ? error.userInfo : nil;
		NSLog(@"[API REQUEST] ID:%@ FAILED URL:%@  TIME:%f  ERROR:%@  INFO: %@",
		    _identifier, failingRequest.URL.absoluteString, duration, error.localizedDescription, info);
#endif

		if (_failureBlock) _failureBlock([TKAPIError errorWithError:error]);

		[self cleanupAndNotify];

		return;
	}

	TKAPIResponse *resp = [[TKAPIResponse alloc] initWithDictionary:dict];
	NSInteger code = resp.code;

#ifdef LOG_API
	NSString *responseString = [NSString stringWithFormat:@"[%luB]", (unsigned long)data.length];
	NSString *dataSeparator = @"";

	if (!_silent || code != 200) {
		responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		responseString = [responseString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
		dataSeparator = @"\n";
	}

	NSString *loggedStr = [NSString stringWithFormat:@"ID:%@ CODE:%ld", _identifier, (long)code];
	loggedStr = [loggedStr stringByAppendingFormat:@" DATA:%@%@", dataSeparator, responseString];

	NSLog(@"[API RESPONSE] %@", loggedStr);
#endif

	if (code != 200) {

		TKAPIError *e = [TKAPIError errorWithResponse:resp];

		if (code == 401) {
			TKEventsManager *events = [TKEventsManager sharedManager];
			if (events.sessionExpirationHandler)
				events.sessionExpirationHandler();
		}

		if (_failureBlock)
			_failureBlock(e);
	}

	else if (_successBlock)
		_successBlock(resp);

	[self cleanupAndNotify];
}

- (void)dataTaskDidFailWithError:(NSError *)error
{
#ifdef LOG_API
	NSTimeInterval duration = -[_startTimestamp timeIntervalSinceNow];
	NSURLRequest *failingRequest = _task.originalRequest ?: _request;
	NSLog(@"[API REQUEST] ID:%@ FAILED URL:%@  ERROR:%@  USERINFO: %@  TIME:%lf", _identifier,
		failingRequest.URL.absoluteString, error.localizedDescription, error.userInfo, duration);
#endif

	if (_failureBlock) _failureBlock([TKAPIError errorWithError:error]);

	[self cleanupAndNotify];
}

@end
