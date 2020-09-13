//
//  TKEnvironment.h
//  TravelKit
//
//  Created by Michal Zelinka on 29/01/2020.
//  Copyright © 2020 Tripomatic. All rights reserved.
//

#import "TKEnvironment.h"

NS_ASSUME_NONNULL_BEGIN

@interface TKEnvironment ()

@property (nonatomic, copy, readonly) NSString *databasePath;
@property (nonatomic, copy, readonly) NSString *defaultsSuiteName;

@end

NS_ASSUME_NONNULL_END
