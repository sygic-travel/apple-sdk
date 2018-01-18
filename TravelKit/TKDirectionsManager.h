//
//  TKDirectionsManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/01/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <TravelKit/TKDirectionDefinitions.h>

NS_ASSUME_NONNULL_BEGIN

///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Type Definitions
///-----------------------------------------------------------------------------


@class TKDirectionsSet, TKDirection, TKDirectionsQuery;


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Directions manager
///-----------------------------------------------------------------------------


@interface TKDirectionsManager : NSObject

+ (TKDirectionsManager *)sharedManager;
- (instancetype)init __attribute__((unavailable("Use [TKDirectionsManager sharedManager].")));

#pragma mark Directions stuff

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


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Directions query
///-----------------------------------------------------------------------------


@interface TKDirectionsQuery : NSObject

@property (nonatomic, strong, readonly) CLLocation *sourceLocation;
@property (nonatomic, strong, readonly) CLLocation *destinationLocation;

@property (atomic) TKTransportAvoidOption avoidOption;
@property (nonatomic, copy) NSString *waypointsPolyline;

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)queryFromLocation:(CLLocation *)sourceLocation toLocation:(CLLocation *)destinationLocation;

@end


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Directions set
///-----------------------------------------------------------------------------


@interface TKDirectionsSet : NSObject

@property (nonatomic, strong) CLLocation *startLocation;
@property (nonatomic, strong) CLLocation *endLocation;
@property (atomic) CLLocationDistance airDistance;

@property (nonatomic, copy) NSArray<TKDirection *> *pedestrianDirections;
@property (nonatomic, copy) NSArray<TKDirection *> *carDirections;
@property (nonatomic, copy) NSArray<TKDirection *> *planeDirections;

@end


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Direction record
///-----------------------------------------------------------------------------


@interface TKDirection : NSObject

@property (nonatomic, strong) CLLocation *startLocation;
@property (nonatomic, strong) CLLocation *endLocation;
@property (atomic) TKDirectionTransportMode mode;
@property (atomic) BOOL estimated;

@property (atomic) NSTimeInterval duration;
@property (atomic) CLLocationDistance distance;
@property (nonatomic, copy) NSString *polyline;

@property (atomic) TKTransportAvoidOption avoidOption;
@property (nonatomic, copy) NSString *waypointsPolyline;

@end

NS_ASSUME_NONNULL_END
