//
//  TKUserCredentials.h
//  TravelKit
//
//  Created by Michal Zelinka on 04/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKUserCredentials : NSObject

@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *refreshToken;
@property (nonatomic, strong) NSDate *expirationDate;

@property (atomic, readonly) BOOL isExpiring;

- (nullable instancetype)initFromDictionary:(NSDictionary *)dictionary;
- (NSDictionary<NSString *, id> *)asDictionary;

@end

NS_ASSUME_NONNULL_END
