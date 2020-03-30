//
//  TKEnvironment.m
//  TravelKit
//
//  Created by Michal Zelinka on 29/01/2020.
//  Copyright © 2020 Tripomatic. All rights reserved.
//
//  FILE-TODO: Check & fix in XCTest environment
//

#import "TKEnvironment+Private.h"


// SQLite database filename
NSString * const TKEnvDatabaseFilename = @"database.sqlite";

// NSUserDefaults suite name
NSString * const TKEnvSuiteName = @"com.tripomatic.travelkit";


@implementation TKEnvironment

+ (void)load
{
	[self sharedEnvironment];
}

+ (TKEnvironment *)sharedEnvironment
{
	static TKEnvironment *shared = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[self alloc] init];
	});

	return shared;
}

- (instancetype)init
{
	if (self = [super init])
	{
#if TARGET_OS_OSX == 1
		_platform = TKDevicePlatformMacOS;
#endif
#if TARGET_OS_IOS == 1
		_platform = TKDevicePlatformIOS;
#endif
#if TARGET_OS_TV == 1
		_platform = TKDevicePlatformTVOS;
#endif
#if TARGET_OS_WATCH == 1
		_platform = TKDevicePlatformWatchOS;
#endif

#if TARGET_OS_SIMULATOR == 1
		_isSimulator = YES;
#endif

#if TARGET_CPU_X86 == 1 || TARGET_CPU_X86_64 == 1

		NSProcessInfo *process = [NSProcessInfo processInfo];
		NSBundle *bundle = [NSBundle mainBundle];

		if (!bundle) @throw @"Running without NSBundle not supported";

		NSString *xcodeBundle = @"com.apple.dt.Xcode";

		BOOL isPlayground = [process.processName containsString:xcodeBundle] ||
		                    [bundle.bundleIdentifier containsString:xcodeBundle];

		_isPlayground = isPlayground;

#endif
	}

	return self;
}

- (NSString *)playgroundRootDirectory
{
	// Return customised path or '~/Desktop/TravelKit Playground'

	return _playgroundDataDirectory ?:
		[[NSSearchPathForDirectoriesInDomains(
			NSDesktopDirectory, NSUserDomainMask, YES) firstObject]
				 stringByAppendingPathComponent:@"TravelKit Playground"];
}

- (NSString *)databasePath
{
	// macOS:           ~/                Library/Caches/<APP BUNDLE ID>/TravelKit/database.sqlite
	// (i|tv|watch)OS:  <APP SANDBOX>/    Library/Caches/                TravelKit/database.sqlite
	// Playground:      <PLAYGROUND ROOT>/                                         database.sqlite

	static NSString *path = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{

		path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
#if TARGET_OS_OSX == 1
		NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
		path = [path stringByAppendingPathComponent:bundleID];
#endif
		path = [path stringByAppendingPathComponent:@"TravelKit"];

		if (_isPlayground)
			path = [self playgroundRootDirectory];

		path = [path stringByAppendingPathComponent:TKEnvDatabaseFilename];
	});

	return [path copy];
}

- (NSString *)defaultsSuiteName
{
	// macOS:           ~/                Library/Preferences/<APP BUNDLE ID>/com.tripomatic.travelkit.plist
	// (i|tv|watch)OS:  <APP SANDBOX>/    Library/Preferences/                com.tripomatic.travelkit.plist
	// Playground:      <PLAYGROUND ROOT>/                                    com.tripomatic.travelkit.plist

	static NSString *suite = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{

		suite = TKEnvSuiteName;

#if TARGET_OS_OSX == 1
		suite = [[NSBundle mainBundle].bundleIdentifier stringByAppendingPathComponent:suite];
#endif

		if (_isPlayground) {
			NSString *path = [self playgroundRootDirectory];
			suite = [path stringByAppendingPathComponent:TKEnvSuiteName];
		}

	});

	return [suite copy];
}

@end
