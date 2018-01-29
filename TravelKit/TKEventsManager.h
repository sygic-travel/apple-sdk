//
//  TKEventsManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 23/01/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TravelKit/TKSynchronizationManager.h>
#import <TravelKit/TKUserCredentials.h>

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

@property (nonatomic, copy, nullable) void (^updatedSessionCredentialsHandler)(TKUserCredentials *_Nullable credentials);
@property (nonatomic, copy, nullable) void (^updatedTripIDHandler)(NSString *originalTripID, NSString *newTripID);
@property (nonatomic, copy, nullable) void (^syncCompletionHandler)(TKSynchronizationResult *result);

@end

NS_ASSUME_NONNULL_END
