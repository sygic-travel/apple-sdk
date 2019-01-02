//
//  TKSession.h
//  TravelKit
//
//  Created by Michal Zelinka on 04/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKSession : NSObject

@property (nonatomic, copy, readonly) NSString *accessToken;
@property (nonatomic, copy, readonly) NSString *refreshToken;
@property (nonatomic, strong, readonly) NSDate *expirationDate;

@property (atomic, readonly) BOOL isExpiring;

- (nullable instancetype)initFromDictionary:(NSDictionary *)dictionary;
- (NSDictionary<NSString *, id> *)asDictionary;

@end

NS_ASSUME_NONNULL_END
