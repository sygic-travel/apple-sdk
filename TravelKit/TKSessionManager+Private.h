//
//  TKSessionManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 29/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKSessionManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface TKSessionManager ()

// App settings
@property (nonatomic, assign) NSTimeInterval changesTimestamp;
@property (nonatomic, copy) NSString *uniqueID;

@end

NS_ASSUME_NONNULL_END
