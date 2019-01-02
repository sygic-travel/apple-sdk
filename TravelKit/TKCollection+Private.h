//
//  TKCollection+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 01/11/18.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <TravelKit/TKCollection.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKCollection ()

/// Initialiser
- (nullable instancetype)initFromResponse:(NSDictionary *)response;

@end

NS_ASSUME_NONNULL_END
