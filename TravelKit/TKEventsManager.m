//
//  TKEventsManager.m
//  TravelKit
//
//  Created by Michal Zelinka on 23/01/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import "TKEventsManager.h"

@implementation TKEventsManager


#pragma mark -
#pragma mark Initialization


+ (TKEventsManager *)sharedManager
{
	static TKEventsManager *shared = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[self alloc] init];
	});

	return shared;
}

- (instancetype)init
{
	if (self = [super init]) { }

	return self;
}

@end
