//
//  TKPlace+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKPlace.h"

NS_ASSUME_NONNULL_BEGIN

@interface TKPlace (Private)
- (nullable instancetype)initFromResponse:(NSDictionary *)response;
@end

@interface TKPlaceDetail (Private)
- (nullable instancetype)initFromResponse:(NSDictionary *)response;
@end

@interface TKPlaceTag (Private)
- (nullable instancetype)initFromResponse:(NSDictionary *)response;
@end

NS_ASSUME_NONNULL_END
