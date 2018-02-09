//
//  TKDirectionDefinitions.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/01/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#ifndef TKDirectionDefinitions_h
#define TKDirectionDefinitions_h

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Directions-related definitions
///-----------------------------------------------------------------------------

/**
 The mode of transport used to indicate the mean of transportation between places.
 */
typedef NS_OPTIONS(NSUInteger, TKDirectionTransportMode) {
	TKDirectionTransportModeUnknown    = (0), /// Unknown mode.
	TKDirectionTransportModePedestrian = (1 << 0), /// Pedestrian mode.
	TKDirectionTransportModeCar        = (1 << 1), /// Car mode.
	TKDirectionTransportModePlane      = (1 << 2), /// Plane mode.
	TKDirectionTransportModeBike       = (1 << 3), /// Bike mode.
	TKDirectionTransportModeBus        = (1 << 4), /// Bus mode.
	TKDirectionTransportModeTrain      = (1 << 5), /// Train mode.
	TKDirectionTransportModeBoat       = (1 << 6), /// Boat mode.
}; // ABI-EXPORTED

/**
 An enum indicating options to fine-tune transport options. Only useful with Car mode.
 */
typedef NS_OPTIONS(NSUInteger, TKTransportAvoidOption) {
	TKTransportAvoidOptionNone        = (0), /// No Avoid options. Default.
	TKTransportAvoidOptionTolls       = (1 << 0), /// A bit indicating an option to avoid Tolls.
	TKTransportAvoidOptionHighways    = (1 << 1), /// A bit indicating an option to avoid Highways.
	TKTransportAvoidOptionFerries     = (1 << 2), /// A bit indicating an option to avoid Ferries.
	TKTransportAvoidOptionUnpaved     = (1 << 3), /// A bit indicating an option to avoid Unpaved paths.
}; // ABI-EXPORTED


// Basic values which might come handy to work with
#define kTKDistanceIdealWalkLimit     5000.0  //     5 kilometers
#define kTKDistanceMaxWalkLimit      50000.0  //    50 kilometers
#define kTKDistanceIdealCarLimit   1000000.0  //  1000 kilometers
#define kTKDistanceMaxCarLimit     2000000.0  //  2000 kilometers
#define kTKDistanceMinFlightLimit    50000.0  //    50 kilometers

@class TKDirectionsSet, TKDirection, TKDirectionsQuery;

///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Directions query
///-----------------------------------------------------------------------------

/**
 A query object used for fetching direction data.
 */
@interface TKDirectionsQuery : NSObject

@property (nonatomic, strong, readonly) CLLocation *startLocation;
@property (nonatomic, strong, readonly) CLLocation *endLocation;

@property (atomic) TKTransportAvoidOption avoidOption;
@property (nonatomic, copy) NSArray<CLLocation *> *waypoints;

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)queryFromLocation:(CLLocation *)startLocation toLocation:(CLLocation *)endLocation;

@end


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Directions set
///-----------------------------------------------------------------------------

/**
 A set of directions usable for display.
 */
@interface TKDirectionsSet : NSObject

@property (nonatomic, strong) CLLocation *startLocation;
@property (nonatomic, strong) CLLocation *endLocation;
@property (atomic) CLLocationDistance airDistance;

@property (nonatomic, copy) NSArray<TKDirection *> *pedestrianDirections;
@property (nonatomic, copy) NSArray<TKDirection *> *carDirections;
@property (nonatomic, copy) NSArray<TKDirection *> *planeDirections;
@property (nonatomic, copy) NSArray<TKDirection *> *bikeDirections;

@end


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Direction record
///-----------------------------------------------------------------------------

/**
 A particular direction carrying information about a route, its distance and duration.
 */
@interface TKDirection : NSObject

@property (nonatomic, strong) CLLocation *startLocation;
@property (nonatomic, strong) CLLocation *endLocation;
@property (atomic) TKDirectionTransportMode mode;
@property (atomic) BOOL estimated;

@property (atomic) NSTimeInterval duration;
@property (atomic) CLLocationDistance distance;
@property (nonatomic, copy) NSString *polyline;

@property (atomic) TKTransportAvoidOption avoidOption;
@property (nonatomic, copy) NSArray<CLLocation *> *waypoints;

@end

NS_ASSUME_NONNULL_END

#endif /* TKDirectionDefinitions_h */
