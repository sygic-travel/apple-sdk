//
//  API.h
//  Tripomatic
//
//  Created by Michal Zelinka on 27/09/13.
//  Copyright (c) 2013 Tripomatic. All rights reserved.
//

#import "API.h"
#import "NSObject+Parsing.h"

// Default API key definition
NSString *const _defaultAPIKey = @"**REDACTED**";

#pragma mark API

@interface API ()

@property (nonatomic, copy) NSString *apiURL;

@end

@implementation API

#pragma mark -
#pragma mark Shared instance

+ (API *)sharedAPI
{
	static API *shared = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{ shared = [[self alloc] init]; });
	return shared;
}

#pragma mark -
#pragma mark Instance implementation

- (void)refreshServerProperties
{
	NSString *subdomain = [@API_SUBDOMAIN copy];
//	NSString *lang = [[UserSettings sharedSettings].appLanguage ?: @"en" lowercaseString];
	NSString *lang = @"en";

	_apiURL = [NSString stringWithFormat:@"%@://%@.%@/%@/%@",
	//          http[s]:// [*-]api.   sygictraveldata.com  /  v2.x  /   en
	//             |         |                 |                |       |
	    @API_PROTOCOL, subdomain,     @API_BASE_URL,   @API_VERSION,   lang];

	_APIKey = [self defaultAPIKey];
//	_isAlphaEnvironment = [_apiURL containsSubstring:@"alpha"];
}

- (instancetype)init
{
	if (self = [super init])
	{
		if (![self isMemberOfClass:[API class]])
			@throw @"API class cannot be inherited";

		[self refreshServerProperties];
	}

	return self;
}

- (NSString *)defaultAPIKey
{
	static NSString *defaultAPIKey = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		defaultAPIKey = _defaultAPIKey;
	});
	return defaultAPIKey;
}

- (void)setAPIKey:(NSString *)APIKey
{
	_APIKey = APIKey ?: [self defaultAPIKey];
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

- (NSString *)URLStringForRequestType:(APIRequestType)type path:(NSString *)path
{
	return [self URLStringForRequestType:type path:path APIKey:nil];
}

- (NSString *)URLStringForRequestType:(APIRequestType)type path:(NSString *)path APIKey:(NSString *)APIKey
{
	NSMutableString *ret = [_apiURL mutableCopy];

	// Switch to CDN URL if needed

	// Append API key if needed
	[ret appendFormat:@"/%@", APIKey ?: _APIKey];

	// Append path

	if (![path hasPrefix:@"/"])
		[ret appendString:@"/"];

	[ret appendString:path];

	// Return

	return [ret copy];
}

- (NSString *)pathForRequestType:(APIRequestType)type
{
	return [self pathForRequestType:type ID:nil];
}

- (NSString *)pathForRequestType:(APIRequestType)type ID:(NSString *)ID
{
	switch (type) {

	case APIRequestTypePlacesGET: // GET
//		return @"/places";
		return @"features";

	case APIRequestTypePlaceGET: // GET
//		return [NSString stringWithFormat:@"/places/%@", ID];
		return [NSString stringWithFormat:@"/items/%@", ID];

	case APIRequestTypeMediaGET: // GET
		return [NSString stringWithFormat:@"/media/%@", ID];

	default:
		@throw [NSException exceptionWithName:@"Unsupported request"
			reason:@"Unsupported request type given" userInfo:nil];

	}
}

- (NSString *)HTTPMethodForRequestType:(APIRequestType)type
{
	return @"GET";
}

@end

#pragma mark -
#pragma mark Trip API Request Wrapper
#pragma mark -

@interface APIRequest ()

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSDictionary *HTTPHeaders;
@property (nonatomic, copy) NSData *data;

@property (nonatomic, strong) APIConnection *connection;
@property (nonatomic, copy) APIConnectionSuccessBlock successBlock;
@property (nonatomic, copy) APIConnectionFailureBlock failureBlock;

@end

@implementation APIRequest

#pragma mark -
#pragma mark Lifecycle

- (instancetype)init
{
	if (self = [super init])
	{
		_connection = nil;
		_type = -1;
		_state = APIRequestStateInit;
	}

	return self;
}

- (void)start
{
	_state = APIRequestStatePending;

	API *api = [API sharedAPI];

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

	_connection = [[APIConnection alloc] initWithURLRequest:request success:_successBlock failure:_failureBlock];
	_connection.identifier = self.typeString;
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
	_state = APIRequestStateFinished;
	[_connection cancel];
}


////////////////////
#pragma mark - Places
////////////////////


- (instancetype)initAsPlacesRequestForQuery:(TKPlacesQuery *)query
	success:(void (^)(NSArray<TKPlace *> *place))success failure:(void (^)())failure
{
	if (self = [super init])
	{
		_type = APIRequestTypePlacesGET;

		NSMutableString *path = [[[API sharedAPI] pathForRequestType:_type] mutableCopy];

		NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithCapacity:10];

		if (query.searchTerm.length)
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"query" value:query.searchTerm]];

		// TODO: Map tile
		// TODO: Map spread

		if (query.type)
		{
			NSString *type = (query.type == TKPlaceTypePOI) ? @"poi" :
			(query.type == TKPlaceTypeCity) ? @"city" :
			(query.type == TKPlaceTypeCountry) ? @"country" : nil;

			if (type) [queryItems addObject:
				[NSURLQueryItem queryItemWithName:@"type" value:type]];
		}

		if (query.region)
			[queryItems addObject:[NSURLQueryItem queryItemWithName:@"bounds" value:
				[NSString stringWithFormat:@"%.6f,%.6f,%.6f,%.6f",
					query.region.southWestPoint.coordinate.latitude,
					query.region.southWestPoint.coordinate.longitude,
					query.region.northEastPoint.coordinate.latitude,
					query.region.northEastPoint.coordinate.longitude
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

		_successBlock = ^(APIResponse *response){

			NSMutableArray *stored = [NSMutableArray array];
			NSArray *items = [response.data[@"features"] parsedArray];

			for (NSDictionary *dict in items)
			{
				if (![dict parsedDictionary]) continue;
				NSString *guid = [dict[@"guid"] parsedString];
				if (!guid) continue;

				TKPlace *a = [[TKPlace alloc] initFromResponse:dict];
				if (a) a.detail = nil;
				if (a) [stored addObject:a];
			}

			_state = APIRequestStateFinished;

			if (success) success(stored);

		}; _failureBlock = ^(APIError *error){
			_state = APIRequestStateFinished;
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
		_type = APIRequestTypePlaceGET;
		_path = [[API sharedAPI] pathForRequestType:_type ID:itemID];

		_successBlock = ^(APIResponse *response){

			TKPlace *place = nil;
			NSDictionary *item = [response.data[@"item"] parsedDictionary];
			NSArray *itemMedia = [response.data[@"item"][@"main_media"][@"media"] parsedArray];

			if (item) place = [[TKPlace alloc] initFromResponse:item];

			NSMutableArray<TKMedium *> *media = [NSMutableArray arrayWithCapacity:4];
			for (NSDictionary *dict in itemMedia) {
				TKMedium *m = [[TKMedium alloc] initFromResponse:dict];
				if (m) [media addObject:m];
			}

			_state = APIRequestStateFinished;

			if (!place && failure) failure();
			if (place && success) success(place, media);

		}; _failureBlock = ^(APIError *error){
			_state = APIRequestStateFinished;
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
		_type = APIRequestTypeMediaGET;
		_path = [[API sharedAPI] pathForRequestType:_type ID:placeID];

		_successBlock = ^(APIResponse *response){

			NSArray *media = arrayOrNil(response.data);
			NSMutableArray *ret = [NSMutableArray arrayWithCapacity:media.count];

			for (NSDictionary *mediumDict in media)
			{
				if (![mediumDict isKindOfClass:[NSDictionary class]]) continue;

				TKMedium *m = [[TKMedium alloc] initFromResponse:mediumDict];
				if (m) [ret addObject:m];
			}

			_state = APIRequestStateFinished;

			if (success) success(ret);

		}; _failureBlock = ^(APIError *error){
			_state = APIRequestStateFinished;
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
		_type = APIRequestTypeExchangeRatesGET;
		_path = [[API sharedAPI] pathForRequestType:_type];

		_successBlock = ^(APIResponse *response){

			_state = APIRequestStateFinished;

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

		}; _failureBlock = ^(APIError *error){
			_state = APIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}


////////////////////
#pragma mark - Custom requests
////////////////////


- (instancetype)initAsCustomGETRequestWithPath:(NSString *)path
	success:(void (^)(id))success failure:(APIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = APIRequestTypeCustomGET;
		_path = path;

		_successBlock = ^(APIResponse *response){

			_state = APIRequestStateFinished;

			if (success)
				success(response.data);

		}; _failureBlock = ^(APIError *error){
			_state = APIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsCustomPOSTRequestWithPath:(NSString *)path
	json:(NSString *)json success:(void (^)(id))success failure:(APIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = APIRequestTypeCustomPOST;
		_path = path;
		_data = [json dataUsingEncoding:NSUTF8StringEncoding];

		_successBlock = ^(APIResponse *response){

			_state = APIRequestStateFinished;

			if (success)
				success(response.data);

		}; _failureBlock = ^(APIError *error){
			_state = APIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsCustomPUTRequestWithPath:(NSString *)path json:(NSString *)json
	success:(void (^)(id))success failure:(APIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = APIRequestTypeCustomPUT;
		_path = path;
		_data = [json dataUsingEncoding:NSUTF8StringEncoding];

		_successBlock = ^(APIResponse *response){

			_state = APIRequestStateFinished;

			if (success)
				success(response.data);

		}; _failureBlock = ^(APIError *error){
			_state = APIRequestStateFinished;
			if (failure) failure(error);
		};
	}

	return self;
}

- (instancetype)initAsCustomDELETERequestWithPath:(NSString *)path json:(NSString *)json
	success:(void (^)(id))success failure:(APIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_type = APIRequestTypeCustomDELETE;
		_path = path;
		_data = [json dataUsingEncoding:NSUTF8StringEncoding];

		_successBlock = ^(APIResponse *response){

			_state = APIRequestStateFinished;

			if (success)
				success(response.data);

		}; _failureBlock = ^(APIError *error){
			_state = APIRequestStateFinished;
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
			@(APIRequestTypePlacesGET): @"PLACES_GET",
			@(APIRequestTypePlaceGET): @"PLACE_GET",
			@(APIRequestTypeMediaGET): @"MEDIA_GET",
			@(APIRequestTypeExchangeRatesGET): @"EXCHANGE_RATES_GET",
			@(APIRequestTypeCustomGET): @"CUSTOM_GET",
			@(APIRequestTypeCustomPOST): @"CUSTOM_POST",
			@(APIRequestTypeCustomPUT): @"CUSTOM_PUT",
			@(APIRequestTypeCustomDELETE): @"CUSTOM_DELETE",
		};
	});

	return types[@(_type)] ?: @"UNKNOWN";
}

@end
