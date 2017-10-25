//
//  TKUserSettings.m
//  TravelKit
//
//  Created by Michal Zelinka on 14/02/2014.
//  Copyright (c) 2014 Tripomatic. All rights reserved.
//

#import "TKUserSettings+Private.h"
#import "NSObject+Parsing.h"


// Session stuff
NSString * const TKSettingsKeyUniqueID = @"UniqueID";
NSString * const TKSettingsKeyUserCredentials = @"UserCredentials";
NSString * const TKSettingsKeyChangesTimestamp = @"ChangesTimestamp";

// App-wide flags
NSString * const TKSettingsKeyLaunchNumber = @"LaunchNumber";
NSString * const TKSettingsKeyIntallationDate = @"InstallationDate";


#pragma mark - Persistent User Settings


@interface TKUserSettings ()

@property (nonatomic,readonly) NSUserDefaults *defaults;

@end


@implementation TKUserSettings

+ (TKUserSettings *)sharedSettings
{
    static dispatch_once_t pred = 0;
    static TKUserSettings *shared = nil;
    dispatch_once(&pred, ^{ shared = [[self alloc] init]; });
    return shared;
}

+ (NSUserDefaults *)sharedDefaults
{
	return [[self sharedSettings] defaults];
}

- (instancetype)init
{
	if (self = [super init])
	{
		// TODO: Check the resulting path on different platforms
		_defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.tripomatic.travelkit"];

		[self load];
	}

	return self;
}

- (void)load
{
	_changesTimestamp = [_defaults doubleForKey:TKSettingsKeyChangesTimestamp];
	_launchNumber = [_defaults integerForKey:TKSettingsKeyLaunchNumber] + 1;
	_installationDate = [_defaults objectForKey:TKSettingsKeyIntallationDate];
	_uniqueID = [_defaults stringForKey:TKSettingsKeyUniqueID];

	// Installation date

	if (!_installationDate)
		_installationDate = [NSDate new];

	// Unique ID

	if (!_uniqueID)
		_uniqueID = [[NSUUID UUID] UUIDString];

	// Loading User info

	_userCredentials = [_defaults objectForKey:TKSettingsKeyUserCredentials];
}

- (void)commit
{
	[_defaults setObject:_uniqueID forKey:TKSettingsKeyUniqueID];
	[_defaults setObject:_userCredentials forKey:TKSettingsKeyUserCredentials];

	[_defaults setDouble:_changesTimestamp forKey:TKSettingsKeyChangesTimestamp];
	[_defaults setInteger:_launchNumber forKey:TKSettingsKeyLaunchNumber];
	[_defaults setObject:_installationDate forKey:TKSettingsKeyIntallationDate];

	[_defaults synchronize];
}

- (void)reset
{
	// TODO: Check/fix me?
	[_defaults removePersistentDomainForName:@"com.tripomatic.travelkit"];
//	[_defaults removeSuiteNamed:@"com.tripomatic.travelkit"];
	[_defaults synchronize];

	[self load];
}

@end
