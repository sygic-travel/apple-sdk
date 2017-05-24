//
//  TKReachability+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 23/05/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TKNetworkStatus) {
	TKNetworkStatusNotReachable = 0,
	TKNetworkStatusReachableViaWiFi,
	TKNetworkStatusReachableViaWWAN,
};

typedef NS_ENUM(NSUInteger, TKConnectionCellularType) {
	TKConnectionCellularTypeUnknown = 0,
	TKConnectionCellularType2G,
	TKConnectionCellularType3G,
	TKConnectionCellularTypeLTE,
};

@interface TKReachability : NSObject

+ (BOOL)isConnected;
+ (BOOL)isCellular;
+ (BOOL)isWifi;

#if TARGET_OS_IOS
+ (TKConnectionCellularType)cellularType;
#endif

@end
