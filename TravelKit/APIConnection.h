//
//  APIConnection.h
//  Tripomatic
//
//  Created by Michal Zelinka on 27/09/13.
//  Copyright (c) 2013 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const TKAPIResponseErrorDomain;

#define APIResponse TKAPIResponse
#define APIError TKAPIError
#define APIConnection TKAPIConnection


@interface APIResponse: NSObject

@property (assign) NSInteger code;
@property (nonatomic, copy, readonly) NSString *status;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, copy, readonly) NSDictionary *metadata;
@property (nonatomic, strong, readonly) id data;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end


@interface APIError : NSError

@property (nonatomic, strong, readonly) NSString *ID;
@property (nonatomic, strong, readonly) APIResponse *response;

@end


typedef void(^APIConnectionSuccessBlock)(APIResponse *);
typedef void(^APIConnectionFailureBlock)(APIError *);


@interface APIConnection : NSObject <NSURLConnectionDelegate>

@property (nonatomic, copy) NSString *identifier;

@property (readonly) NSInteger responseStatus;
@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, strong, readonly) NSMutableData *receivedData;
@property (nonatomic, strong, readonly) NSURLConnection *connection;
@property (nonatomic, strong, readonly) NSMutableURLRequest *request;

@property (atomic) BOOL silent;

// Initializers
- (instancetype)initWithURLRequest:(NSMutableURLRequest *)request
	success:(APIConnectionSuccessBlock)success failure:(APIConnectionFailureBlock)failure;

// Connection control
- (BOOL)start;
- (BOOL)cancel;

@end
