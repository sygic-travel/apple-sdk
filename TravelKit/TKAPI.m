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
#import "TKMedium+Private.h"
#import "NSObject+Parsing.h"

#import "NSDate+Tripomatic.h"
#import "Foundation+TravelKit.h"


#pragma mark API

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

	case TKAPIRequestTypeFavoriteADD: // POST
	case TKAPIRequestTypeFavoriteDELETE: // DELETE
		return @"/favorites";

	case TKAPIRequestTypeChangesGET: // GET
		return @"/changes";

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
			return @"POST";

		case TKAPIRequestTypeFavoriteDELETE:
			return @"DELETE";

		default: return @"GET";
	}
}

@end

#pragma mark -
#pragma mark Trip API Request Wrapper
#pragma mark -

@interface TKAPIRequest () <TKAPIConnectionDelegate>

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSDictionary *HTTPHeaders;
@property (nonatomic, copy) NSData *data;

@property (nonatomic, strong) TKAPIConnection *connection;
@property (nonatomic, copy) TKAPIConnectionSuccessBlock successBlock;
@property (nonatomic, copy) TKAPIConnectionFailureBlock failureBlock;

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

	NSString *urlString = [api URLStringForPath:_path];
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

	_connection = [[TKAPIConnection alloc] initWithURLRequest:request success:_successBlock failure:_failureBlock];
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
#pragma mark - Places Query
////////////////////


- (instancetype)initAsPlacesRequestForQuery:(TKPlacesQuery *)query
	success:(void (^)(NSArray<TKPlace *> *))success failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypePlacesQueryGET;

		NSMutableString *path = [[[TKAPI sharedAPI] pathForRequestType:_type] mutableCopy];

		NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithCapacity:10];

		if (query.searchTerm.length)
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"query" value:query.searchTerm]];

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

			if (lstr.length) [queryItems addObject:
				[NSURLQueryItem queryItemWithName:@"levels" value:lstr]];
		}

		if (query.quadKeys.count)
		{
			NSString *joined = [query.quadKeys componentsJoinedByString:@"|"];
			[queryItems addObject:[NSURLQueryItem
				queryItemWithName:@"map_tiles" value:joined]];
		}

		if (query.mapSpread.intValue > 0)
			[queryItems addObject:[NSURLQueryItem
				queryItemWithName:@"map_spread" value:query.mapSpread.stringValue]];

		if (query.bounds)
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"bounds" value:
				[NSString stringWithFormat:@"%.6f,%.6f,%.6f,%.6f",
					query.bounds.southWestPoint.coordinate.latitude,
					query.bounds.southWestPoint.coordinate.longitude,
					query.bounds.northEastPoint.coordinate.latitude,
					query.bounds.northEastPoint.coordinate.longitude
				 ]]];

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
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"categories"
				value:[slugs componentsJoinedByString:operator]]];
		}

		if (query.tags.count)
		{
			NSString *operator = (query.tagsMatching == TKPlacesQueryMatchingAll) ? @"," : @"|";
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"tags"
				value:[query.tags componentsJoinedByString:operator]]];
		}

		if (query.parentIDs.count)
		{
			NSString *operator = (query.parentIDsMatching == TKPlacesQueryMatchingAll) ? @"," : @"|";
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"parents"
				value:[query.parentIDs componentsJoinedByString:operator]]];
		}

		if (query.limit.intValue > 0)
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"limit"
				value:[query.limit stringValue]]];

		if (queryItems.count)
		{
			[path appendString:@"?"];

			NSMutableArray<NSString *> *queryFields = [NSMutableArray arrayWithCapacity:queryItems.count];
			NSMutableCharacterSet *set = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
			[set removeCharactersInString:@"?&="];

			for (NSURLQueryItem *item in queryItems)
			{
				NSString *value = [item.value stringByAddingPercentEncodingWithAllowedCharacters:set];
				NSString *field = [NSString stringWithFormat:@"%@=%@", item.name, value];
				[queryFields addObject:field];
			}

			[path appendString:[queryFields componentsJoinedByString:@"&"]];
		}

		_path = path;

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

			_state = TKAPIRequestStateFinished;

			if (success) success(stored);

		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Places Batch
////////////////////


- (instancetype)initAsPlacesRequestForIDs:(NSArray<NSString *> *)placeIDs
	success:(void (^)(NSArray<TKPlace *> *))success failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypePlacesBatchGET;

		NSMutableString *path = [[[TKAPI sharedAPI] pathForRequestType:_type] mutableCopy];

		NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithCapacity:10];

		NSString *formattedIDs = [placeIDs componentsJoinedByString:@"|"] ?: @"";

		[queryItems addObject:[NSURLQueryItem queryItemWithName:@"ids" value:formattedIDs]];

		if (queryItems.count)
		{
			[path appendString:@"?"];

			NSMutableArray<NSString *> *queryFields = [NSMutableArray arrayWithCapacity:queryItems.count];
			NSMutableCharacterSet *set = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
			[set removeCharactersInString:@"?&="];

			for (NSURLQueryItem *item in queryItems)
			{
				NSString *value = [item.value stringByAddingPercentEncodingWithAllowedCharacters:set];
				NSString *field = [NSString stringWithFormat:@"%@=%@", item.name, value];
				[queryFields addObject:field];
			}

			[path appendString:[queryFields componentsJoinedByString:@"&"]];
		}

		_path = path;

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

			_state = TKAPIRequestStateFinished;

			if (success) success(stored);

		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Place
////////////////////


- (instancetype)initAsPlaceRequestForItemWithID:(NSString *)itemID
	success:(void (^)(TKPlace *))success failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypePlaceGET;
		_path = [[TKAPI sharedAPI] pathForRequestType:_type ID:itemID];

		_successBlock = ^(TKAPIResponse *response){

			TKPlace *place = nil;
			NSDictionary *item = [response.data[@"place"] parsedDictionary];

			if (item) place = [[TKPlace alloc] initFromResponse:item];

			_state = TKAPIRequestStateFinished;

			if (!place && failure) failure(nil);
			if (place && success) success(place);

		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Tours Query
////////////////////


- (instancetype)initAsToursRequestForQuery:(TKToursQuery *)query
	success:(void (^)(NSArray<TKTour *> *))success failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeToursQueryGET;

		NSMutableString *path = [[[TKAPI sharedAPI] pathForRequestType:_type] mutableCopy];

		[path appendFormat:@"/%@",
			query.source == TKToursQuerySourceGetYourGuide ?
				@"get-your-guide" : @"viator"];

		NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithCapacity:10];

		if (query.parentID)
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"parent_place_id" value:query.parentID]];

		if (query.sortingType)
		{
			NSString *type = @"rating";
			if (query.sortingType == TKToursQuerySortingPrice) type = @"price";
			else if (query.sortingType == TKToursQuerySortingTopSellers) type = @"top_sellers";
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"sort_by" value:type]];
		}

		{
			NSString *direction = (query.descendingSortingOrder) ? @"desc" : @"asc";
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"sort_direction" value:direction]];
		}

		if (query.pageNumber)
		{
			NSUInteger page = query.pageNumber.unsignedIntegerValue;
			if (page > 1) [queryItems addObject:
				[NSURLQueryItem queryItemWithName:@"page" value:[query.pageNumber stringValue]]];
		}

		if (queryItems.count)
		{
			[path appendString:@"?"];

			NSMutableArray<NSString *> *queryFields = [NSMutableArray arrayWithCapacity:queryItems.count];
			NSMutableCharacterSet *set = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
			[set removeCharactersInString:@"?&="];

			for (NSURLQueryItem *item in queryItems)
			{
				NSString *value = [item.value stringByAddingPercentEncodingWithAllowedCharacters:set];
				NSString *field = [NSString stringWithFormat:@"%@=%@", item.name, value];
				[queryFields addObject:field];
			}

			[path appendString:[queryFields componentsJoinedByString:@"&"]];
		}

		_path = path;

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

			_state = TKAPIRequestStateFinished;

			if (success) success(stored);

		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Media
////////////////////


- (instancetype)initAsMediaRequestForPlaceWithID:(NSString *)placeID
	success:(void (^)(NSArray<TKMedium *> *media))success failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeMediaGET;
		_path = [[TKAPI sharedAPI] pathForRequestType:_type ID:placeID];

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

			_state = TKAPIRequestStateFinished;

			if (success) success(ret);

		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Favorites
////////////////////


- (instancetype)initAsFavoriteItemAddRequestWithID:(NSString *)itemID
	success:(void (^)(void))success failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeFavoriteADD;
		_path = [[TKAPI sharedAPI] pathForRequestType:_type];
		_data = [@{ @"place_id": itemID ?: [NSNull null] } asJSONData];

		_successBlock = ^(TKAPIResponse *__unused response){
			_state = TKAPIRequestStateFinished;
			if (success) success();
		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsFavoriteItemDeleteRequestWithID:(NSString *)itemID
	success:(void (^)(void))success failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeFavoriteDELETE;
		_path = [[TKAPI sharedAPI] pathForRequestType:_type];
		_data = [@{ @"place_id": itemID ?: [NSNull null] } asJSONData];

		_successBlock = ^(TKAPIResponse *__unused response){
			_state = TKAPIRequestStateFinished;
			if (success) success();
		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Changes
////////////////////


- (instancetype)initAsChangesRequestSince:(NSDate *)sinceDate success:(void (^)(
	NSDictionary<NSString *, NSNumber *> *updatedTripsDict, NSArray<NSString *> *deletedTripIDs,
	NSArray<NSString *> *updatedFavouriteIDs, NSArray<NSString *> *deletedFavouriteIDs,
	BOOL updatedSettings, NSDate *timestamp))success failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeChangesGET;
		_path = [[TKAPI sharedAPI] pathForRequestType:_type];

		NSString *sinceString = (sinceDate) ? [[NSDateFormatter shared8601DateTimeFormatter] stringFromDate:sinceDate] : nil;
		sinceString = [sinceString stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];

		if (sinceString) _path = [_path stringByAppendingFormat:@"?since=%@", sinceString];

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

			_state = TKAPIRequestStateFinished;

			if (success)
				success(updatedTripsDict, deletedTripIDs, updatedFavouriteItemIDs,
				        deletedFavouriteItemIDs, settingsUpdated, datestamp);

		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Exchange rates
////////////////////


- (instancetype)initAsExchangeRatesRequestWithSuccess:(void (^)(NSDictionary<NSString *, NSNumber *> *))success
	failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeExchangeRatesGET;
		_path = [[TKAPI sharedAPI] pathForRequestType:_type];

		_successBlock = ^(TKAPIResponse *response){

			_state = TKAPIRequestStateFinished;

			NSMutableDictionary<NSString *, NSNumber *> *exchangeRates = [NSMutableDictionary dictionaryWithCapacity:10];

			for (NSDictionary *e in [response.data parsedArray])
			{
				if (![e parsedDictionary]) continue;

				NSString *code = [e[@"code"] parsedString];
				NSNumber *rate = [e[@"rate"] parsedNumber];

				if (code && rate)
					exchangeRates[code] = rate;
			}

			if (success) success(exchangeRates);

		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Custom requests
////////////////////


- (instancetype)initAsCustomGETRequestWithPath:(NSString *)path
	success:(void (^)(id))success failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeCustomGET;
		_path = path;

		_successBlock = ^(TKAPIResponse *response){

			_state = TKAPIRequestStateFinished;

			if (success)
				success(response.data);

		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsCustomPOSTRequestWithPath:(NSString *)path
	json:(NSString *)json success:(void (^)(id))success failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeCustomPOST;
		_path = path;
		_data = [json dataUsingEncoding:NSUTF8StringEncoding];

		_successBlock = ^(TKAPIResponse *response){

			_state = TKAPIRequestStateFinished;

			if (success)
				success(response.data);

		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsCustomPUTRequestWithPath:(NSString *)path json:(NSString *)json
	success:(void (^)(id))success failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeCustomPUT;
		_path = path;
		_data = [json dataUsingEncoding:NSUTF8StringEncoding];

		_successBlock = ^(TKAPIResponse *response){

			_state = TKAPIRequestStateFinished;

			if (success)
				success(response.data);

		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsCustomDELETERequestWithPath:(NSString *)path json:(NSString *)json
	success:(void (^)(id))success failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypeCustomDELETE;
		_path = path;
		_data = [json dataUsingEncoding:NSUTF8StringEncoding];

		_successBlock = ^(TKAPIResponse *response){

			_state = TKAPIRequestStateFinished;

			if (success)
				success(response.data);

		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
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
