//
//  APIConnection.m
//  Tripomatic
//
//  Created by Michal Zelinka on 27/09/13.
//  Copyright (c) 2013 Tripomatic. All rights reserved.
//

#import "TKAPIConnection+Private.h"
#import "NSObject+Parsing.h"

NSString * const TKAPIResponseErrorDomain = @"TKAPIResponseErrorDomain";


#pragma mark API Response


@implementation TKAPIResponse


- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
	if (self = [super init])
	{
		_code    = [[dictionary[@"status_code"] parsedNumber] integerValue] ?:
		           [[dictionary[@"status_code"] parsedString] integerValue];
		_status  =  [dictionary[@"status"] parsedString];
		_message =  [dictionary[@"status_message"] parsedString];
		_data = dictionary[@"data"];

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


#pragma mark -
#pragma mark API Error


@implementation TKAPIError

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
	if (self = [self initWithDomain:TKAPIResponseErrorDomain code:response.code userInfo:nil])
	{
		_ID = [response.metadata[@"error"][@"id"] parsedString];
		_response = response;
	}

	return self;
}

@end


#pragma mark -
#pragma mark API Connection


@interface TKAPIConnection ()

@property (nonatomic, strong) NSDate *startTimestamp;
@property (nonatomic, copy) TKAPIConnectionSuccessBlock successBlock;
@property (nonatomic, copy) TKAPIConnectionFailureBlock failureBlock;

@end


@implementation TKAPIConnection


- (instancetype)initWithURLRequest:(NSMutableURLRequest *)request
	success:(TKAPIConnectionSuccessBlock)success failure:(TKAPIConnectionFailureBlock)failure
{
	if (self = [super init])
	{
		_successBlock = success;
		_failureBlock = failure;
		_URL = request.URL;

		request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

		[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

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


- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data
{
	// Append newly received data
	[_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// Server response start reading data
	// Needs to be cleared because request could have been forwarded
	[_receivedData setLength:0];

	// Process a response object
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
		_responseStatus = [(NSHTTPURLResponse *)response statusCode];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// We've got all data from the server response
	// Now it's time to parse and process it

#ifdef LOG_API
	NSTimeInterval duration = [[NSDate new] timeIntervalSinceDate:_startTimestamp];
#endif

	NSError *error = nil;

	NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:_receivedData options:kNilOptions error:&error];

	if (error) {

		if (_responseStatus >= 400 || _responseStatus < 100)
			error = [TKAPIError errorWithDomain:TKAPIResponseErrorDomain code:_responseStatus userInfo:nil];

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
	NSLog(@"[API RESPONSE] ID:%@ STATUS:%@ CODE:%zd MESSAGE:%@ DATA:%@%@",
		_identifier, response.status, response.code, response.message, dataSeparator, responseString);
#endif

	if (![response.status isEqual:@"ok"]) {

		TKAPIError *error = [TKAPIError errorWithResponse:response];

		if (_failureBlock) _failureBlock(error);

		return;
	}

	if (_successBlock)
		_successBlock(response);

	_successBlock = nil;
	_failureBlock = nil;

	if ([_delegate respondsToSelector:@selector(connectionDidFinish:)])
		[_delegate connectionDidFinish:self];
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error
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

@end
