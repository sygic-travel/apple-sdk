//
//  TKEventsManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 23/01/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TravelKit/TKSynchronizationManager.h>
#import <TravelKit/TKSession.h>
#import <TravelKit/TKTrip.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKEventsManager : NSObject

///---------------------------------------------------------------------------------------
/// @name Shared interface
///---------------------------------------------------------------------------------------

/// Shared Events managing instance.
@property (class, readonly, strong) TKEventsManager *sharedManager;

+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

///---------------------------------------------------------------------------------------
/// @name Event handlers
///---------------------------------------------------------------------------------------

/// A handling block called when a session update occurs.
///
/// @note `nil` is returned after signing out.
@property (nonatomic, copy, nullable) void (^sessionUpdateHandler)(TKSession *_Nullable session);

/// A handling block called when a Trip ID change occurs.
///
/// In such case, you should throw away any existing `TKTrip` instances with the old ID and query them again.
@property (nonatomic, copy, nullable) void (^tripIDChangeHandler)(NSString *originalTripID, NSString *newTripID);

/// A handling block called when a conflict between the local and server `TKTrip` instance occurs.
///
/// In case you get any Trip conflicts, you may present this conflict to a user so the proper version to be kept
/// can be selected. To determine, use the `-forceLocalTrip` property on a `TKTripConflict` object. When all conflicts
/// are resolved by user, you need to call the provided completion block so the sync loop may continue.
///
/// @note In case you don't handle this event, local Trip instance will be replaced by the one provided by the server.
@property (nonatomic, copy, nullable) void (^tripConflictsHandler)(NSArray<TKTripConflict *> *conflicts, void (^completion)(void));

/// A handling block called whenever a synchronization loop completes (either successfully or not).
@property (nonatomic, copy, nullable) void (^syncCompletionHandler)(TKSynchronizationResult *result);

@end

NS_ASSUME_NONNULL_END
