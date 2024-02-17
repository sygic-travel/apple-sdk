//
//  TKReachability.m
//  TravelKit
//
//  Created by Michal Zelinka on 23/05/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import <pthread.h>

#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#if TARGET_OS_IOS
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif

#import "TKReachability+Private.h"


#define kShouldPrintReachabilityFlags 0


#pragma mark -
#pragma mark Reachability implementation


@implementation TKReachability
{
	SCNetworkReachabilityRef _reachabilityRef;
}


+ (void)printReachabilityFlags:(SCNetworkReachabilityFlags)flags comment:(const char *)comment
{
	NSLog(@"Reachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n",
#if	TARGET_OS_IPHONE
	      (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
#else
	                                                                        '-',
#endif
	      (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',

	      (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
	      (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
	      (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
	      (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
	      (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
	      (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
	      (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-',
	      comment
	      );
}


+ (instancetype)reachabilityWithHostName:(NSString *)hostName
{
	TKReachability* returnValue = NULL;
	const char *cHostName = [hostName UTF8String];
	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, cHostName);
	if (reachability != NULL)
	{
		returnValue= [[self alloc] init];
		if (returnValue != NULL)
		{
			returnValue->_reachabilityRef = reachability;
		}
		else CFRelease(reachability);
	}
	return returnValue;
}


+ (instancetype)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress
{
	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)hostAddress);

	TKReachability* returnValue = NULL;

	if (reachability != NULL)
	{
		returnValue = [[self alloc] init];
		if (returnValue != NULL)
		{
			returnValue->_reachabilityRef = reachability;
		}
		else CFRelease(reachability);
	}
	return returnValue;
}



+ (instancetype)reachabilityForInternetConnection
{
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;

	return [self reachabilityWithAddress:&zeroAddress];
}


- (void)dealloc
{
	if (_reachabilityRef != NULL)
	{
		CFRelease(_reachabilityRef);
	}
}


#pragma mark -
#pragma mark Network Flag Handling


- (TKNetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags
{
#if kShouldPrintReachabilityFlags
	[self.class printReachabilityFlags:flags comment:"networkStatusForFlags"];
#endif

	if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
	{
		// The target host is not reachable.
		return TKNetworkStatusNotReachable;
	}

	TKNetworkStatus returnValue = TKNetworkStatusNotReachable;

	if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
	{
		/*
		 If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
		 */
		returnValue = TKNetworkStatusReachableViaWiFi;
	}

	if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
	    (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
	{
		/*
		 ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
		 */

		if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
		{
			/*
			 ... and no [user] intervention is needed...
			 */
			returnValue = TKNetworkStatusReachableViaWiFi;
		}
	}

#if	TARGET_OS_IPHONE

	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
	{
		/*
		 ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
		 */
		returnValue = TKNetworkStatusReachableViaWWAN;
	}

#endif

	return returnValue;
}


- (BOOL)connectionRequired
{
	NSAssert(_reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");

	SCNetworkReachabilityFlags flags;

	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags))
		return (flags & kSCNetworkReachabilityFlagsConnectionRequired) > 0;

	return NO;
}


- (TKNetworkStatus)currentReachabilityStatus
{
	NSAssert(_reachabilityRef != NULL, @"currentNetworkStatus called with NULL SCNetworkReachabilityRef");

	TKNetworkStatus returnValue = TKNetworkStatusNotReachable;
	SCNetworkReachabilityFlags flags;

	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags))
		returnValue = [self networkStatusForFlags:flags];

	return returnValue;
}


#pragma mark -
#pragma mark Outer APIs


+ (TKNetworkStatus)priv_currentNetworkStatus
{
	static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
	static TKNetworkStatus status = TKNetworkStatusNotReachable;
	static NSDate *lastDate = nil;
	static TKReachability *reachability = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		reachability = [TKReachability reachabilityForInternetConnection];
	});

	pthread_mutex_lock(&lock);

	if (!lastDate || [lastDate timeIntervalSinceNow] < -M_PI) {
		lastDate = [NSDate new];
		status = [reachability currentReachabilityStatus];
	}

	pthread_mutex_unlock(&lock);

	return status;
}


+ (BOOL)isConnected
{
	TKNetworkStatus netStatus = [self priv_currentNetworkStatus];
	return (netStatus != TKNetworkStatusNotReachable);
}


+ (BOOL)isCellular
{
	TKNetworkStatus netStatus = [self priv_currentNetworkStatus];
	return (netStatus == TKNetworkStatusReachableViaWWAN);
}


+ (BOOL)isWifi
{
	TKNetworkStatus netStatus = [self priv_currentNetworkStatus];
	return (netStatus == TKNetworkStatusReachableViaWiFi);
}


#if TARGET_OS_IOS

+ (TKConnectionCellularType)cellularType
{
	if (![self isCellular]) return TKConnectionCellularTypeUnknown;

	CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    NSSet<NSString *> *technology = [NSSet setWithArray:netinfo.serviceCurrentRadioAccessTechnology.allValues ?: @[ ]];

	if (@available(iOS 14.1, *))
		if ([technology containsObject:CTRadioAccessTechnologyNR] ||
			[technology containsObject:CTRadioAccessTechnologyNRNSA])
			return TKConnectionCellularType5G;
	if ([technology containsObject:CTRadioAccessTechnologyLTE])
		return TKConnectionCellularTypeLTE;
	if ([technology containsObject:CTRadioAccessTechnologyGPRS] ||
		[technology containsObject:CTRadioAccessTechnologyEdge])
		return TKConnectionCellularType2G;
	if (technology) return TKConnectionCellularType3G;

	return TKConnectionCellularTypeUnknown;
}

#endif

@end
