//
//  TravelKit.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TravelKit.h"
#import "TKAPI+Private.h"
#import "TKSSOAPI+Private.h"
#import "TKMapWorker.h"
#import "Foundation+TravelKit.h"


@interface TravelKit ()
{
	NSString *_Nullable _languageID;
}
@end


@implementation TravelKit

+ (TravelKit *)sharedKit
{
	static TravelKit *shared = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{

#ifdef DEBUG
		NSLog(@"Running TravelKit in DEBUG mode.");
#endif

		shared = [self new];
	});

	return shared;
}

+ (NSArray<NSString *> *)supportedLanguageIDs
{
	static NSArray *langs = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		langs = @[ @"en", @"fr", @"de", @"es", @"nl",
		           @"pt", @"it", @"ru", @"cs", @"sk",
		           @"pl", @"tr", @"zh", @"ko", @"ar",
		           @"da", @"el", @"fi", @"he", @"hu",
		           @"no", @"ro", @"sv", @"th", @"uk",
		];
	});

	return langs;
}


#pragma mark -
#pragma mark Configuration


- (void)setAPIKey:(NSString *)APIKey
{
	[TKAPI sharedAPI].APIKey = _APIKey = [APIKey copy];
}

- (void)setClientID:(NSString *)clientID
{
	[TKSSOAPI sharedAPI].clientID = _clientID = [clientID copy];
}

- (NSString *)languageID
{
	return _languageID ?: @"en";
}

- (void)setLanguageID:(NSString *)languageID
{
	if      ([languageID hasPrefix:@"zh"]) languageID = @"zh";
	else if ([languageID hasPrefix:@"en"]) languageID = @"en";

	NSArray<NSString *> *supported = [[self class] supportedLanguageIDs];
	NSString *newLanguageID = (languageID &&
	  [supported containsObject:languageID]) ?
		[languageID copy] : nil;

	_languageID = newLanguageID;

	[TKAPI sharedAPI].languageID = newLanguageID;
}


#pragma mark -
#pragma mark Generic methods


- (instancetype)init
{
	if (self = [super init])
	{
		_places = [TKPlacesManager sharedManager];
		_tours = [TKToursManager sharedManager];
//		_trips = [TKTripsManager sharedManager];
//		_session = [TKSessionManager sharedManager];
//		_favorites = [TKFavoritesManager sharedManager];
//		_sync = [TKSynchronizationManager sharedManager];
		__directions = [TKDirectionsManager sharedManager];
		_events = [TKEventsManager sharedManager];
	}

	return self;
}


#pragma mark -
#pragma mark Lazyfied modules


- (TKTripsManager *)trips
{
	return [TKTripsManager sharedManager];
}

- (TKSessionManager *)session
{
	return [TKSessionManager sharedManager];
}

- (TKFavoritesManager *)favorites
{
	return [TKFavoritesManager sharedManager];
}

- (TKSynchronizationManager *)sync
{
	return [TKSynchronizationManager sharedManager];
}

@end
