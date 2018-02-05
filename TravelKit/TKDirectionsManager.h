//
//  TKDirectionsManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/01/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TravelKit/TKDirectionDefinitions.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark Directions manager

///---------------------------------------------------------------------------------------
/// @name Directions manager
///---------------------------------------------------------------------------------------

/**
 A working manager used to handle direction requests.
 */
@interface TKDirectionsManager : NSObject

/// Shared Directions providing instance.
@property (class, readonly, strong) TKDirectionsManager *sharedManager;

+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

#pragma mark Directions stuff

///---------------------------------------------------------------------------------------
/// @name Directions stuff
///---------------------------------------------------------------------------------------

/**
 The query method for getting exact Directions set. Falls back to estimated on failure.

 @param query Directions query.
 @param completion Completion block with given Set of Directions to use.

 @note When a failure occurs, the completion block is provided with estimated or no set returned.
 */
- (void)directionsSetForQuery:(TKDirectionsQuery *)query completion:(nullable void (^)(TKDirectionsSet *_Nullable))completion;

/**
 The query method for getting cached or estimated Directions set.

 @param query Directions query.
 @return Set of Directions to use.
 */
- (nullable TKDirectionsSet *)estimatedDirectionsSetForQuery:(TKDirectionsQuery *)query;

@end

NS_ASSUME_NONNULL_END
