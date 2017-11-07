//
//  TKSynchronizationManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 31/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSynchronizationTimerPeriod  15
#define kSynchronizationMinPeriod    60

typedef NS_ENUM(NSUInteger, SyncState) {
	kSyncStateStandby = 0,
	kSyncStateInitializing,
//	kSyncStateCustomPlaces,
//	kSyncStateLeavedTrips,
	kSyncStateFavourites,
	kSyncStateChanges,
//	kSyncStateUpdatedTrips,
//	kSyncStateMissingItems,
	kSyncStateClearing,
};

typedef NS_ENUM(NSUInteger, SyncNotificationType) {
	kSyncNotificationBegin = 0,
	kSyncNotificationSignificantUpdate,
	kSyncNotificationCancel,
	kSyncNotificationDone,
};


@interface TKSynchronizationManager : NSObject

#pragma mark - Shared instance

///---------------------------------------------------------------------------------------
/// @name Shared interface
///---------------------------------------------------------------------------------------

/// Shared Trips managing instance.
@property (class, readonly, strong) TKSynchronizationManager *sharedManager;

+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

///---------------------------------------------------------------------------------------
/// @name Variables
///---------------------------------------------------------------------------------------

@property (nonatomic, readonly) SyncState state;
@property (nonatomic, assign) BOOL blockSynchronization;

- (void)synchronize;
- (void)cancelSynchronization;

- (BOOL)syncInProgress;

@end
