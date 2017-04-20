//
//  API.h
//  Tripomatic
//
//  Created by Michal Zelinka on 27/09/13.
//  Copyright (c) 2013 Tripomatic. All rights reserved.
//

#import "TKAPI.h"
#import "TKPlace+Private.h"
#import "NSObject+Parsing.h"


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

//	NSString *lang = [[UserSettings sharedSettings].appLanguage ?: @"en" lowercaseString];
	NSString *lang = @"en";

	_apiURL = [NSString stringWithFormat:@"%@://%@%@/%@/%@",
	//          http[s]://  api.      sygictravelapi.com  /    0.x   /   en
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
	_APIKey = APIKey;
}

- (NSString *)hostname
{
	return [NSURL URLWithString:self.apiURL].host;
}

- (NSString *)URLStringForPath:(NSString *)path
{
	return [self URLStringForPath:path APIKey:nil];
}

- (NSString *)URLStringForPath:(NSString *)path APIKey:(NSString *)APIKey
{
	if (!APIKey) APIKey = _APIKey;

	if (![path hasPrefix:@"/"])
		path = [NSString stringWithFormat:@"/%@", path];

	return [NSString stringWithFormat:@"%@/%@%@", _apiURL, APIKey, path];
}

- (NSString *)URLStringForRequestType:(TKAPIRequestType)type path:(NSString *)path
{
	return [self URLStringForRequestType:type path:path APIKey:nil];
}

- (NSString *)URLStringForRequestType:(TKAPIRequestType)type path:(NSString *)path APIKey:(NSString *)APIKey
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

	case TKAPIRequestTypePlacesGET: // GET
		return @"/places";

	case TKAPIRequestTypePlaceGET: // GET
		return [NSString stringWithFormat:@"/place-details/%@", ID];

	case TKAPIRequestTypeMediaGET: // GET
		return [NSString stringWithFormat:@"/places/%@/media", ID];

	default:
		@throw [NSException exceptionWithName:@"Unsupported request"
			reason:@"Unsupported request type given" userInfo:nil];

	}
}

- (NSString *)HTTPMethodForRequestType:(TKAPIRequestType)type
{
	return @"GET";
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
		_type = -1;
		_state = TKAPIRequestStateInit;
	}

	return self;
}

- (void)start
{
	_state = TKAPIRequestStatePending;

	TKAPI *api = [TKAPI sharedAPI];

	NSString *urlString = [api URLStringForRequestType:_type path:_path APIKey:_APIKey];
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

	if (apiKey.length)
		[request setValue:apiKey forHTTPHeaderField:@"X-API-Key"];

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


- (void)connectionDidFinish:(TKAPIConnection *)connection
{
	_connection = nil;
	_successBlock = nil;
	_failureBlock = nil;
}


////////////////////
#pragma mark - Places
////////////////////


- (instancetype)initAsPlacesRequestForQuery:(TKPlacesQuery *)query
	success:(void (^)(NSArray<TKPlace *> *place))success failure:(void (^)())failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypePlacesGET;

		NSMutableString *path = [[[TKAPI sharedAPI] pathForRequestType:_type] mutableCopy];

		NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithCapacity:10];

		if (query.searchTerm.length)
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"query" value:query.searchTerm]];

		if (query.level)
		{
			NSString * (^levelToString)(TKPlaceLevel level) = ^NSString *(TKPlaceLevel level) {

				static NSDictionary *levels = nil;

				static dispatch_once_t onceToken;
				dispatch_once(&onceToken, ^{
					levels = @{
						@(TKPlaceLevelPOI): @"poi",
						@(TKPlaceLevelNeighbourhood): @"neighbourhood",
						@(TKPlaceLevelLocality): @"locality",
						@(TKPlaceLevelSettlement): @"settlement",
						@(TKPlaceLevelVillage): @"village",
						@(TKPlaceLevelTown): @"town",
						@(TKPlaceLevelCity): @"city",
						@(TKPlaceLevelCounty): @"county",
						@(TKPlaceLevelRegion): @"region",
						@(TKPlaceLevelIsland): @"island",
						@(TKPlaceLevelArchipelago): @"archipelago",
						@(TKPlaceLevelState): @"state",
						@(TKPlaceLevelCountry): @"country",
						@(TKPlaceLevelContinent): @"continent",
					};
				});

				return levels[@(level)];
			};

			NSString *level = levelToString(query.level);

			if (level) [queryItems addObject:
				[NSURLQueryItem queryItemWithName:@"level" value:level]];
		}

		// TODO: Multiple quadkeys support not yet implemeneted on API
		if (query.quadKeys.count)
			[queryItems addObject:[NSURLQueryItem
				queryItemWithName:@"map_tile" value:query.quadKeys.firstObject]];

		// TODO: Map spread
		[queryItems addObject:[NSURLQueryItem queryItemWithName:@"map_spread" value:@"2"]];

		if (query.bounds)
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"bounds" value:
				[NSString stringWithFormat:@"%.6f,%.6f,%.6f,%.6f",
					query.bounds.southWestPoint.coordinate.latitude,
					query.bounds.southWestPoint.coordinate.longitude,
					query.bounds.northEastPoint.coordinate.latitude,
					query.bounds.northEastPoint.coordinate.longitude
				 ]]];

		if (query.categories.count)
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"categories"
				value:[query.categories componentsJoinedByString:@"|"]]];

		if (query.tags.count)
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"tags"
				value:[query.tags componentsJoinedByString:@"|"]]];

		if (query.parentID)
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"parent"
				value:query.parentID]];

		if (query.limit)
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"limit"
				value:[@(query.limit) stringValue]]];

		if (queryItems.count)
		{
			[path appendString:@"?"];

			NSMutableArray<NSString *> *queryFields = [NSMutableArray arrayWithCapacity:queryItems.count];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

			for (NSURLQueryItem *item in queryItems)
			{
				NSString *value = [item.value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				NSString *field = [NSString stringWithFormat:@"%@=%@", item.name, value];
				[queryFields addObject:field];
			}

#pragma clang diagnostic pop

			[path appendString:[queryFields componentsJoinedByString:@"&"]];
		}

		_path = path;

		_successBlock = ^(TKAPIResponse *response){

			NSMutableArray *stored = [NSMutableArray array];
			NSArray *items = [response.data[@"places"] parsedArray];

			for (NSDictionary *dict in items)
			{
				if (![dict parsedDictionary]) continue;
				NSString *guid = [dict[@"guid"] parsedString];
				if (!guid) continue;

				TKPlace *a = [[TKPlace alloc] initFromResponse:dict];
				if (a) a.detail = nil;
				if (a) [stored addObject:a];
			}

			_state = TKAPIRequestStateFinished;

			if (success) success(stored);

		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure();
		};
	}

	return self;
}


////////////////////
#pragma mark - Place
////////////////////


- (instancetype)initAsPlaceRequestForItemWithID:(NSString *)itemID
	success:(void (^)(TKPlace *place, NSArray<TKMedium *> *media))success failure:(void (^)())failure
{
	if (self = [super init])
	{
		_type = TKAPIRequestTypePlaceGET;
		_path = [[TKAPI sharedAPI] pathForRequestType:_type ID:itemID];

		_successBlock = ^(TKAPIResponse *response){

			TKPlace *place = nil;
			NSDictionary *item = [response.data[@"place"] parsedDictionary];
			NSArray *itemMedia = [response.data[@"place"][@"main_media"][@"media"] parsedArray];

			if (item) place = [[TKPlace alloc] initFromResponse:item];

			NSMutableArray<TKMedium *> *media = [NSMutableArray arrayWithCapacity:4];
			for (NSDictionary *dict in itemMedia) {
				TKMedium *m = [[TKMedium alloc] initFromResponse:dict];
				if (m) [media addObject:m];
			}

			_state = TKAPIRequestStateFinished;

			if (!place && failure) failure();
			if (place && success) success(place, media);

		}; _failureBlock = ^(TKAPIError *error){
			_state = TKAPIRequestStateFinished;
			if (failure) failure();
		};
	}

	return self;
}


////////////////////
#pragma mark - Media
////////////////////


- (instancetype)initAsMediaRequestForPlaceWithID:(NSString *)placeID
	success:(void (^)(NSArray<TKMedium *> *media))success failure:(void (^)())failure
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
			if (failure) failure();
		};
	}

	return self;
}


////////////////////
#pragma mark - Exchange rates
////////////////////


- (instancetype)initAsExchangeRatesRequestWithSuccess:(void (^)(NSDictionary<NSString *, NSNumber *> *))success failure:(void (^)())failure
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
			@(TKAPIRequestTypePlacesGET): @"PLACES_GET",
			@(TKAPIRequestTypePlaceGET): @"PLACE_GET",
			@(TKAPIRequestTypeMediaGET): @"MEDIA_GET",
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
