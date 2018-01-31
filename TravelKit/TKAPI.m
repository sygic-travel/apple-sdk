//
//  TKAPI.h
//  TravelKit
//
//  Created by Michal Zelinka on 27/09/13.
//  Copyright (c) 2013 Tripomatic. All rights reserved.
//

#import "TKAPI+Private.h"
#import "TKPlace+Private.h"
#import "TKTour+Private.h"
#import "TKTrip+Private.h"
#import "TKMedium+Private.h"
#import "NSObject+Parsing.h"

#import "NSDate+Tripomatic.h"
#import "Foundation+TravelKit.h"

#import "TKEventsManager+Private.h"

#import "TravelKit.h"


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

	NSString *lang = _language ?: @"en";

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

- (void)setLanguage:(NSString *)language
{
	_language = [language copy];

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

//	BOOL useCDN = [self useCDNForRequestType:type];
//
//	// Switch to CDN URL
//	if (useCDN)
//		[ret replaceOccurrencesOfString:@"api." withString:@"api-cdn."
//		    options:kNilOptions range:NSMakeRange(0, ret.length)];

	// Append path

	if (![path hasPrefix:@"/"])
		@throw [NSString stringWithFormat:@"Invalid path prefix for API request of type %zd", type];

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

- (NSString *)HTTPMethodForRequestType:(__unused TKAPIRequestType)type
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

@property (atomic, readonly) NSInteger responseStatus;
@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, strong, readonly) NSMutableData *receivedData;
@property (nonatomic, strong, readonly) NSURLConnection *connection;
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
		NSString *sep = [urlString containsSubstring:@"?"] ? @"&":@"?";
		query = [NSString stringWithFormat:@"%@%@", sep, query];

		urlString = [urlString stringByAppendingString:query];
	}

	NSURL *url = [NSURL URLWithString:urlString];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	request.HTTPMethod = [api HTTPMethodForRequestType:_type];

	request.timeoutInterval = 10;

	if (_data.length) {
		[request setHTTPBody:_data];
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[request setValue:[NSString stringWithFormat:@"%tu", _data.length] forHTTPHeaderField:@"Content-Length"];
	}

	for (NSString *header in _HTTPHeaders.allKeys)
		[request setValue:_HTTPHeaders[header] forHTTPHeaderField:header];

	NSString *apiKey = _APIKey ?: api.APIKey;
	NSString *accessToken = _accessToken ?: api.accessToken;

	if (apiKey.length)
		[request setValue:apiKey forHTTPHeaderField:@"X-API-Key"];

	if (accessToken.length)
		[request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken]
			forHTTPHeaderField:@"Authorization"];

	for (NSString *header in _HTTPHeaders.allKeys)
		[request setValue:_HTTPHeaders[header] forHTTPHeaderField:header];

	TKAPISuccessBlock success = ^(TKAPIResponse *response) {
		_state = TKAPIRequestStateFinished;
		if (_successBlock) _successBlock(response);
	};

	TKAPIFailureBlock failure = ^(TKAPIError *error) {
		_state = TKAPIRequestStateFinished;
		if (_failureBlock) _failureBlock(error);
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


- (instancetype)initAsChangesRequestSince:(NSDate *)sinceDate success:(void (^)(
	NSDictionary<NSString *, NSNumber *> *updatedTripsDict, NSArray<NSString *> *deletedTripIDs,
	NSArray<NSString *> *updatedFavouriteIDs, NSArray<NSString *> *deletedFavouriteIDs,
	BOOL updatedSettings, NSDate *timestamp))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeChangesGET;

		NSString *sinceString = (sinceDate) ? [[NSDateFormatter shared8601DateTimeFormatter] stringFromDate:sinceDate] : nil;

		if (sinceString) _query = @{ @"since": sinceString };

		_successBlock = ^(TKAPIResponse *response){

			// Prepare structures for response data
			NSMutableDictionary *updatedTripsDict = [NSMutableDictionary dictionaryWithCapacity:5];
			NSMutableArray *deletedTripIDs = [NSMutableArray arrayWithCapacity:5],
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

			if (success)
				success(updatedTripsDict, deletedTripIDs, updatedFavouriteItemIDs,
				        deletedFavouriteItemIDs, settingsUpdated, datestamp);

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
	success:(void (^)(TKTrip *, TKTripConflict *))success failure:(void (^)(TKAPIError *))failure
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
			if (trip && updatedTrip && [resolution containsSubstring:@"ignored"])
			{
				NSDictionary *conflictDict = [response.data[@"conflict_info"] parsedDictionary];
				NSString *editor = [conflictDict[@"last_user_name"] parsedString];
				NSString *dateStr = [conflictDict[@"last_updated_at"] parsedString];
				NSDate *updateDate = [NSDate dateFrom8601DateTimeString:dateStr];

				conflict = [[TKTripConflict alloc] initWithLocalTrip:trip remoteTrip:updatedTrip lastEditor:editor lastUpdate:updateDate];
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
			NSArray *tripIDs = [[data[@"deleted_trip_ids"] parsedArray]
			  mappedArrayUsingBlock:^id(id obj) {
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
			NSMutableArray *trips = [NSMutableArray array];

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

		NSMutableDictionary *queryDict = [NSMutableDictionary dictionaryWithCapacity:10];

		if (query.searchTerm.length)
			queryDict[@"query"] = query.searchTerm;

		if (query.levels)
		{
			NSMutableArray *levels = [NSMutableArray arrayWithCapacity:3];
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
			NSMutableArray *slugs = [NSMutableArray arrayWithCapacity:3];
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

		if (query.limit.intValue > 0)
			queryDict[@"limit"] = [query.limit stringValue];

		_query = queryDict;

		_successBlock = ^(TKAPIResponse *response){

			NSMutableArray *stored = [NSMutableArray array];
			NSArray *items = [response.data[@"places"] parsedArray];

			for (NSDictionary *dict in items)
			{
				if (![dict parsedDictionary]) continue;
				NSString *guid = [dict[@"id"] parsedString];
				if (!guid) continue;

				TKPlace *a = [[TKPlace alloc] initFromResponse:dict];
				if (a) a.detail = nil;
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
	success:(void (^)(NSArray<TKPlace *> *))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypePlacesBatchGET;
		_query = @{ @"ids": [placeIDs componentsJoinedByString:@"|"] ?: @"" };

		_successBlock = ^(TKAPIResponse *response){

			NSMutableArray *stored = [NSMutableArray array];
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
#pragma mark - Place
////////////////////


- (instancetype)initAsPlaceRequestForItemWithID:(NSString *)itemID
	success:(void (^)(TKPlace *))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypePlaceGET;
		_pathID = itemID;

		_successBlock = ^(TKAPIResponse *response){

			TKPlace *place = nil;
			NSDictionary *item = [response.data[@"place"] parsedDictionary];

			if (item) place = [[TKPlace alloc] initFromResponse:item];

			if (!place && failure) failure(nil);
			if (place && success) success(place);

		}; _failureBlock = ^(TKAPIError *error){
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Tours Query
////////////////////


- (instancetype)initAsToursRequestForQuery:(TKToursQuery *)query
	success:(void (^)(NSArray<TKTour *> *))success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeToursQueryGET;

		NSMutableString *path = [[[TKAPI sharedAPI] pathForRequestType:_type] mutableCopy];

		[path appendFormat:@"/%@",
			query.source == TKToursQuerySourceGetYourGuide ?
				@"get-your-guide" : @"viator"];

		_path = path;

		NSMutableDictionary *queryDict = [NSMutableDictionary dictionaryWithCapacity:5];

		if (query.parentID)
			queryDict[@"parent_place_id"] = query.parentID;

		if (query.sortingType)
		{
			NSString *type = @"rating";
			if (query.sortingType == TKToursQuerySortingPrice) type = @"price";
			else if (query.sortingType == TKToursQuerySortingTopSellers) type = @"top_sellers";
			queryDict[@"sort_by"] = type;
		}

		{
			NSString *direction = (query.descendingSortingOrder) ? @"desc" : @"asc";
			queryDict[@"sort_direction"] = direction;
		}

		if (query.pageNumber)
		{
			NSUInteger page = query.pageNumber.unsignedIntegerValue;
			if (page > 1) queryDict[@"page"] = [query.pageNumber stringValue];
		}

		_query = queryDict;

		_successBlock = ^(TKAPIResponse *response){

			NSMutableArray *stored = [NSMutableArray array];
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
			NSMutableArray *ret = [NSMutableArray arrayWithCapacity:media.count];

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

		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];

		dict[@"origin"] = (query.startLocation) ?
		@{
			@"lat": @(query.startLocation.coordinate.latitude),
			@"lng": @(query.startLocation.coordinate.longitude)
		} : [NSNull null];

		dict[@"destination"] = (query.endLocation) ?
		@{
			@"lat": @(query.endLocation.coordinate.latitude),
			@"lng": @(query.endLocation.coordinate.longitude)
		} : [NSNull null];

		if (query.waypointsPolyline) {
			NSArray<CLLocation *> *points = [TKMapWorker pointsFromPolyline:query.waypointsPolyline];
			NSMutableArray *pointDicts = [NSMutableArray arrayWithCapacity:points.count];

			for (CLLocation *pt in points)
				[pointDicts addObject:
					@{ @"location": @{
						@"lat": @(pt.coordinate.latitude), @"lng": @(pt.coordinate.longitude) }
				}];

			dict[@"waypoints"] = pointDicts;
		}
		else dict[@"waypoints"] = @[ ];

		if (query.avoidOption) {
			NSMutableArray *opts = [NSMutableArray arrayWithCapacity:4];
			if (query.avoidOption & TKTransportAvoidOptionTolls)
				[opts addObject:@"tolls"];
			if (query.avoidOption & TKTransportAvoidOptionHighways)
				[opts addObject:@"highways"];
			if (query.avoidOption & TKTransportAvoidOptionFerries)
				[opts addObject:@"ferries"];
			if (query.avoidOption & TKTransportAvoidOptionUnpaved)
				[opts addObject:@"unpaved"];
			dict[@"avoid"] = opts;
		}
		else dict[@"avoid"] = @[ ];

		_data = [dict asJSONData];

		_successBlock = ^(TKAPIResponse *response){

			TKDirectionsSet *set = [TKDirectionsSet new];

			set.startLocation = query.startLocation;
			set.endLocation = query.endLocation;
			set.airDistance = [query.endLocation distanceFromLocation:query.startLocation];

			NSMutableArray<TKDirection *> *pedestrianDirs = [NSMutableArray arrayWithCapacity:2];
			NSMutableArray<TKDirection *> *carDirs = [NSMutableArray arrayWithCapacity:2];
			NSMutableArray<TKDirection *> *planeDirs = [NSMutableArray arrayWithCapacity:2];

			NSArray<NSDictionary *> *directions = [response.data[@"directions"] parsedArray];

			TKDirection *d = nil;
			for (NSDictionary *dir in directions) {
				d = [TKDirection new];
				d.startLocation = query.startLocation;
				d.endLocation = query.endLocation;

				NSString *mode = [dir[@"mode"] parsedString];
				if ([mode isEqualToString:@"pedestrian"]) {
					d.mode = TKDirectionTransportModePedestrian;
					[pedestrianDirs addObject:d]; }
				else if ([mode isEqualToString:@"car"]) {
					d.mode = TKDirectionTransportModeCar;
					[carDirs addObject:d]; }
				else if ([mode isEqualToString:@"plane"]) {
					d.mode = TKDirectionTransportModePlane;
					[planeDirs addObject:d]; }
				else continue;

				d.duration = [[dir[@"duration"] parsedNumber] doubleValue];
				d.distance = [[dir[@"distance"] parsedNumber] doubleValue];
				d.polyline = [dir[@"polyline"] parsedString];
				d.avoidOption = query.avoidOption;
				d.waypointsPolyline = query.waypointsPolyline;
			}

			set.pedestrianDirections = pedestrianDirs;
			set.carDirections = carDirs;
			set.planeDirections = planeDirs;

			if (success) success(set);

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

				if (code && rate)
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

	NSArray *args = [[response.metadata[@"error"][@"args"] parsedArray]
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

		NSMutableArray *concat = [NSMutableArray arrayWithCapacity:2];

		NSString *appName = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleNameKey] parsedString];
		NSString *appVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleVersionKey] parsedString];

		appName = [appName stringByTrimmingCharactersInRegexString:@"[^0-9a-zA-Z]"];
		appVersion = [appVersion stringByTrimmingCharactersInRegexString:@"[^0-9a-zA-Z.]"];

		if (appName && appVersion)
			[concat addObject:[NSString stringWithFormat:@"%@/%@", appName, appVersion]];

		NSString *sdkName = @"TravelKit";
		NSString *sdkVersion = [@(TravelKitVersionNumber) stringValue];

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
		platformVersion = [NSString stringWithFormat:@"%zd.%zd.%zd",
		                   ver.majorVersion, ver.minorVersion, ver.patchVersion];

		if (platformName && platformVersion)
			[concat addObject:[NSString stringWithFormat:@"%@/%@", platformName, platformVersion]];

		agent = [concat componentsJoinedByString:@" "];
	});

	return agent;
}

- (instancetype)initWithURLRequest:(NSMutableURLRequest *)request
	success:(TKAPISuccessBlock)success failure:(TKAPIFailureBlock)failure
{
	if (self = [super init])
	{
		_successBlock = success;
		_failureBlock = failure;
		_URL = request.URL;

		request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

		[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
		[request setValue:[self.class userAgentString] forHTTPHeaderField:@"User-Agent"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

		_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];

#pragma clang diagnostic pop

#ifdef LOG_API
		if (!_connection)
			NSLog(@"[API REQUEST] Cannot initialize connection: %@", _URL);
#endif
	}

	return self;
}

- (void)dealloc
{
	_URL = nil;
	_receivedData = nil;
	_connection = nil;
	_successBlock = nil;
	_failureBlock = nil;
}


#pragma mark - Connection control


- (BOOL)start
{
#ifdef LOG_API
	NSString *loggedData = (_silent) ? @"(silenced)" : [[NSString alloc] initWithData:_connection.originalRequest.HTTPBody encoding:NSUTF8StringEncoding];

	if (_connection.originalRequest.HTTPBody.length > 0)
		NSLog(@"[API REQUEST] ID:%@ URL:%@  METHOD:%@  DATA:\n%@", _identifier, _URL, _connection.originalRequest.HTTPMethod, loggedData);
	else
		NSLog(@"[API REQUEST] ID:%@ URL:%@  METHOD:%@", _identifier, _URL, _connection.originalRequest.HTTPMethod);
#endif

	static NSOperationQueue *connectionsQueue;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		connectionsQueue = [NSOperationQueue new];
		if ([connectionsQueue respondsToSelector:@selector(setQualityOfService:)])
			connectionsQueue.qualityOfService = NSQualityOfServiceUtility;
	});

	if (_connection) {
		_receivedData = [NSMutableData data];
		_startTimestamp = [NSDate new];
		[_connection setDelegateQueue:connectionsQueue];
		[_connection start];
		return YES;
	}
	else
	{
#ifdef LOG_API
		NSLog(@"[API REQUEST] Cannot initialize connection ID:%@ (%@)", _identifier, _URL);
#endif

		if (_failureBlock)
			_failureBlock(nil);
		return NO;
	}
}

- (BOOL)cancel
{
	if (!_connection) return NO;
	[_connection cancel];
	return YES;
}


#pragma mark - NSURLConnection delegate


- (void)connection:(__unused NSURLConnection *)connection didReceiveData:(NSData *)data
{
	// Append newly received data
	[_receivedData appendData:data];
}

- (void)connection:(__unused NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// Server response start reading data
	// Needs to be cleared because request could have been forwarded
	[_receivedData setLength:0];

	// Process a response object
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
		_responseStatus = [(NSHTTPURLResponse *)response statusCode];
}

- (void)connectionDidFinishLoading:(__unused NSURLConnection *)connection
{
	// We've got all data from the server response
	// Now it's time to parse and process it

#ifdef LOG_API
	NSTimeInterval duration = [[NSDate new] timeIntervalSinceDate:_startTimestamp];
#endif

	NSError *error = nil;

	NSDictionary *jsonDictionary = [NSJSONSerialization
		JSONObjectWithData:_receivedData options:(NSJSONReadingOptions)kNilOptions error:&error];

	if (!jsonDictionary || error) {

		if (_responseStatus >= 400 || _responseStatus < 100)
			error = [TKAPIError errorWithCode:_responseStatus userInfo:nil];

#ifdef LOG_API
		NSDictionary *info = (error.userInfo.allKeys.count) ? error.userInfo : nil;
		NSLog(@"[API REQUEST] ID:%@ FAILED URL:%@  TIME:%f  ERROR:%@  INFO: %@",
		    _identifier, _connection.originalRequest.URL, duration, error.localizedDescription, info);
#endif

		if (_failureBlock) _failureBlock([TKAPIError errorWithError:error]);

		return;
	}

	TKAPIResponse *response = [[TKAPIResponse alloc] initWithDictionary:jsonDictionary];

#ifdef LOG_API
	NSString *responseString = [[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding];
	responseString = [responseString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	if (_silent) responseString = @"(silenced)";
	NSString *dataSeparator = (_silent) ? @"":@"\n";
	NSLog(@"[API RESPONSE] ID:%@ CODE:%zd DATA:%@%@", _identifier, response.code, dataSeparator, responseString);
#endif

	if (response.code != 200) {

		TKAPIError *e = [TKAPIError errorWithResponse:response];

		if (response.code == 401) {
			TKEventsManager *events = [TKEventsManager sharedManager];
			if (events.expiredSessionCredentialsHandler)
				events.expiredSessionCredentialsHandler();
		}

		if (_failureBlock) _failureBlock(e);

		return;
	}

	if (_successBlock)
		_successBlock(response);

	_successBlock = nil;
	_failureBlock = nil;

	if ([_delegate respondsToSelector:@selector(connectionDidFinish:)])
		[_delegate connectionDidFinish:self];
}

- (void)connection:(__unused NSURLConnection *)connection didFailWithError:(NSError *)error
{
#ifdef LOG_API
	NSLog(@"[API REQUEST] ID:%@ FAILED URL:%@  ERROR:%@  USERINFO: %@", _identifier,
		_connection.originalRequest.URL.path, error.localizedDescription, error.userInfo);
#endif

	if (_failureBlock) _failureBlock([TKAPIError errorWithError:error]);

	_successBlock = nil;
	_failureBlock = nil;

	if ([_delegate respondsToSelector:@selector(connectionDidFinish:)])
		[_delegate connectionDidFinish:self];
}

- (NSCachedURLResponse *)connection:(__unused NSURLConnection *)connection
	willCacheResponse:(__unused NSCachedURLResponse *)cachedResponse
{
	return nil;
}

@end
