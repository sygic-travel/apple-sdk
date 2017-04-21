//
//  APIConnection+Private.h
//  Tripomatic
//
//  Created by Michal Zelinka on 27/09/13.
//  Copyright (c) 2013 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const TKAPIResponseErrorDomain;


@interface TKAPIResponse: NSObject

@property (assign) NSInteger code;
@property (nonatomic, copy, readonly) NSString *status;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, copy, readonly) NSDictionary *metadata;
@property (nonatomic, strong, readonly) id data;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end


@interface TKAPIError : NSError

@property (nonatomic, strong, readonly) NSString *ID;
@property (nonatomic, strong, readonly) TKAPIResponse *response;

@end


typedef void(^TKAPIConnectionSuccessBlock)(TKAPIResponse *);
typedef void(^TKAPIConnectionFailureBlock)(TKAPIError *);


@class TKAPIConnection;
@protocol TKAPIConnectionDelegate <NSObject>

@required
- (void)connectionDidFinish:(TKAPIConnection *)connection;

@end


@interface TKAPIConnection : NSObject <NSURLConnectionDelegate>

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, weak) id<TKAPIConnectionDelegate> delegate;

@property (readonly) NSInteger responseStatus;
@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, strong, readonly) NSMutableData *receivedData;
@property (nonatomic, strong, readonly) NSURLConnection *connection;
@property (nonatomic, strong, readonly) NSMutableURLRequest *request;

@property (atomic) BOOL silent;

// Initializers
- (instancetype)initWithURLRequest:(NSMutableURLRequest *)request
	success:(TKAPIConnectionSuccessBlock)success failure:(TKAPIConnectionFailureBlock)failure;

// Connection control
- (BOOL)start;
- (BOOL)cancel;

@end
