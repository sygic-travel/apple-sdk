//
//  TKSynchronizationManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 31/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///---------------------------------------------------------------------------------------
/// @name Synchronization result object
///---------------------------------------------------------------------------------------

/**
 An object carrying the information about the synchronization loop result.
 */
@interface TKSynchronizationResult : NSObject

/// A success flag of the synchronization loop.
@property (atomic) BOOL success;
/// An array of Trip IDs affected by the synchronization.
@property (nonatomic, copy) NSArray<NSString *> *updatedTripIDs;
/// A flag indicating whether there's some change in Favorites.
@property (atomic) BOOL favoritesUpdated;

@end

///---------------------------------------------------------------------------------------
/// @name Synchronization manager
///---------------------------------------------------------------------------------------

/**
 A working manager used to handle synchronization.
 */
@interface TKSynchronizationManager : NSObject

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

/// :nodoc:

@property (nonatomic, assign) BOOL blockSynchronization;
@property (nonatomic, assign) BOOL periodicSyncEnabled;

@property (readonly) BOOL syncInProgress;

- (void)synchronize;
- (void)cancelSynchronization;

@end

NS_ASSUME_NONNULL_END
