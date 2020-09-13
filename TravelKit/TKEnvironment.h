//
//  TKEnvironment.h
//  TravelKit
//
//  Created by Michal Zelinka on 29/01/2020.
//  Copyright © 2020 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TKDevicePlatform) {
	TKDevicePlatformUnknown   = 0,
	TKDevicePlatformMacOS     = 1 << 0,
	TKDevicePlatformIOS       = 1 << 1,
	TKDevicePlatformTVOS      = 1 << 2,
	TKDevicePlatformWatchOS   = 1 << 3,
};

@interface TKEnvironment : NSObject

@property (class, readonly, strong) TKEnvironment *sharedEnvironment;

@property (atomic, readonly) TKDevicePlatform platform;
@property (atomic, readonly) BOOL isSimulator;

@property (atomic, readonly) BOOL isPlayground;
@property (nonatomic, copy, nullable) NSString *playgroundDataDirectory;

@end

NS_ASSUME_NONNULL_END
