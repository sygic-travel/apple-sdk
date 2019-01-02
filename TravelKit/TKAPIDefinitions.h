//
//  TKAPIDefinitions.h
//  TravelKit
//
//  Created by Michal Zelinka on 14/11/17.
//  Copyright (c) 2017 Tripomatic. All rights reserved.
//

#ifndef APIDefinitions_h
#define APIDefinitions_h


#pragma mark - Definitions -


@class TKAPIResponse, TKAPIError;

typedef void(^TKAPISuccessBlock)(TKAPIResponse *);
typedef void(^TKAPIFailureBlock)(TKAPIError *);


#pragma mark - API response -


@interface TKAPIResponse: NSObject

@property (atomic, assign) NSInteger code;
@property (nonatomic, copy, readonly) NSDictionary *metadata;
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, strong, readonly) id data;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end


#pragma mark - API error -


@interface TKAPIError : NSError

@property (nonatomic, strong, readonly) NSString *ID;
@property (nonatomic, strong, readonly) NSArray<NSString *> *args;
@property (nonatomic, strong, readonly) TKAPIResponse *response;

+ (instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary<NSErrorUserInfoKey,id> *)dict;

@end

#endif /* APIDefinitions_h */
