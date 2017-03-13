//
//  TKPlace+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKPlace.h"

@interface TKPlace (Private)
- (instancetype)initFromResponse:(NSDictionary *)response;
@end

@interface TKPlaceDetail (Private)
- (instancetype)initFromResponse:(NSDictionary *)response;
@end

@interface TKPlaceTag (Private)
- (instancetype)initFromResponse:(NSDictionary *)response;
@end
