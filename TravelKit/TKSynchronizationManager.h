//
//  TKSynchronizationManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 31/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TKSynchronizationManager : NSObject

#pragma mark - Shared instance

///---------------------------------------------------------------------------------------
/// @name Shared interface
///---------------------------------------------------------------------------------------

/// Shared Synchronization managing instance.
@property (class, readonly, strong) TKSynchronizationManager *sharedManager;

+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

///---------------------------------------------------------------------------------------
/// @name Variables
///---------------------------------------------------------------------------------------

@property (nonatomic, assign) BOOL blockSynchronization;
@property (nonatomic, assign) BOOL periodicSyncEnabled;

@property (readonly) BOOL syncInProgress;

- (void)synchronize;
- (void)cancelSynchronization;

@end
