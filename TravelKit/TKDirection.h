//
//  TKDirection.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/01/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Directions-related definitions
///-----------------------------------------------------------------------------

/**
 The mode of transport used to query for when fetching calculated directions.
 */
typedef NS_OPTIONS(NSUInteger, TKDirectionMode) {
	TKDirectionModeNone             = (0),
	TKDirectionModeWalk             = (1 << 0),
	TKDirectionModeCar              = (1 << 1),
	TKDirectionModePublicTransport  = (1 << 2),
	TKDirectionModeDefault          = (TKDirectionModeWalk | TKDirectionModeCar | TKDirectionModePublicTransport),
}; // ABI-EXPORTED

/**
 An enum indicating options to fine-tune transport options. Only useful with Car mode.
 */
typedef NS_OPTIONS(NSUInteger, TKDirectionAvoidOption) {
	TKDirectionAvoidOptionNone        = (0), /// No Avoid options. Default.
	TKDirectionAvoidOptionTolls       = (1 << 0), /// A bit indicating an option to avoid Tolls.
	TKDirectionAvoidOptionHighways    = (1 << 1), /// A bit indicating an option to avoid Highways.
	TKDirectionAvoidOptionFerries     = (1 << 2), /// A bit indicating an option to avoid Ferries.
	TKDirectionAvoidOptionUnpaved     = (1 << 3), /// A bit indicating an option to avoid Unpaved paths.
}; // ABI-EXPORTED

/**
 The mode of a specific step within a calculated direction.
 */
typedef NS_ENUM(NSUInteger, TKDirectionStepMode) {
	TKDirectionStepModeUnknown = 0,
	TKDirectionStepModePedestrian,
	TKDirectionStepModeCar,
	TKDirectionStepModePlane,
	TKDirectionStepModeBike,
	TKDirectionStepModeBoat,
	TKDirectionStepModeBus,
	TKDirectionStepModeFunicular,
	TKDirectionStepModeSubway,
	TKDirectionStepModeTaxi,
	TKDirectionStepModeTrain,
	TKDirectionStepModeTram,
}; // ABI-EXPORTED


// Basic values which might come handy to work with
#define kTKDistanceIdealWalkLimit     2000.0  //     2 kilometres
#define kTKDistanceMaxWalkLimit       5000.0  //     5 kilometres
#define kTKDistanceIdealCarLimit   1000000.0  //  1000 kilometres
#define kTKDistanceMaxCarLimit     2000000.0  //  2000 kilometres
#define kTKDistanceMinFlightLimit   100000.0  //   100 kilometres

@class TKDirectionsQuery, TKDirectionsRecord, TKEstimateDirectionRecord;
@class TKDirection, TKDirectionStep, TKDirectionIntermediateStop;

///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Directions query
///-----------------------------------------------------------------------------

/**
 A query object used for fetching direction data.
 */
@interface TKDirectionsQuery : NSObject

///----------------------
/// @name Properties
///----------------------

@property (atomic) TKDirectionMode mode;
@property (nonatomic, strong, readonly) CLLocation *sourceLocation;
@property (nonatomic, strong, readonly) CLLocation *destinationLocation;

@property (nonatomic, copy, nullable) NSArray<CLLocation *> *waypoints;
@property (atomic) TKDirectionAvoidOption avoidOption;
@property (nonatomic, strong, nullable) NSDate *relativeDepartureDate;
@property (nonatomic, strong, nullable) NSDate *relativeArrivalDate;

@property (nonatomic, readonly, copy) NSString *cacheKey;

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)queryFromLocation:(CLLocation *)sourceLocation toLocation:(CLLocation *)destinationLocation;

@end

///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Directions set
///-----------------------------------------------------------------------------

/**
 A set of directions usable for display.
 */
@interface TKDirectionsSet : NSObject

///----------------------
/// @name Properties
///----------------------

@property (nonatomic, strong) CLLocation *startLocation;
@property (nonatomic, strong) CLLocation *endLocation;

@property (atomic) CLLocationDistance airDistance;

@property (atomic) TKDirectionAvoidOption avoidOption;
@property (nonatomic, copy, nullable) NSString *waypointsPolyline;

@property (nonatomic, copy) NSArray<TKDirection *> *directions;

@property (nonatomic, strong, nullable) TKDirection *idealDirection;
@property (nonatomic, strong, nullable) TKDirection *idealWalkDirection;
@property (nonatomic, strong, nullable) TKDirection *idealCarDirection;
@property (nonatomic, strong, nullable) TKDirection *idealPublicTransportDirection;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end

///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Direction object
///-----------------------------------------------------------------------------

/**
 A particular direction variant carrying information about a route, its distance and duration.
 */
@interface TKDirection : NSObject

///----------------------
/// @name Properties
///----------------------

@property (atomic) BOOL estimated;
@property (atomic) NSTimeInterval duration;
@property (atomic) CLLocationDistance distance;

@property (atomic) TKDirectionMode mode;
@property (nonatomic, copy, nullable) NSString *source;
@property (nonatomic, copy) NSArray<TKDirectionStep *> *steps;

@property (nonatomic, copy, nullable) NSString *routeID;

@property (nonatomic, readonly) NSString *calculatedPolyline;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end

///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Direction step
///-----------------------------------------------------------------------------

/**
 A particular direction step containing an information about a specific route segment.
 */
@interface TKDirectionStep : NSObject

///----------------------
/// @name Properties
///----------------------

@property (atomic) NSTimeInterval duration;
@property (atomic) CLLocationDistance distance;

@property (atomic) TKDirectionStepMode mode;
@property (nonatomic, copy, nullable) NSString *polyline;

@property (nonatomic, copy, nullable) NSString *originName;
@property (nonatomic, strong, nullable) CLLocation *originLocation;

@property (nonatomic, copy, nullable) NSString *destinationName;
@property (nonatomic, strong, nullable) CLLocation *destinationLocation;

@property (nonatomic, copy) NSArray<TKDirectionIntermediateStop *> *intermediateStops;

@property (nonatomic, copy, nullable) NSString *headsign;
@property (nonatomic, copy, nullable) NSString *shortName;
@property (nonatomic, copy, nullable) NSString *longName;
@property (nonatomic, strong, nullable) NSNumber *lineColor; // unsigned RGB HEX
@property (nonatomic, copy, nullable) NSString *displayMode;
@property (nonatomic, copy, nullable) NSString *attribution;

@property (nonatomic, strong, nullable) NSDate *departureDate;
@property (nonatomic, strong, nullable) NSDate *arrivalDate;
@property (nonatomic, copy, nullable) NSString *departureLocalString;
@property (nonatomic, copy, nullable) NSString *arrivalLocalString;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end

///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Direction intermediate stop
///-----------------------------------------------------------------------------

/**
 A significant, intermediate stop on the route.
 */
@interface TKDirectionIntermediateStop : NSObject

///----------------------
/// @name Properties
///----------------------

@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong, nullable) NSDate *departureDate;
@property (nonatomic, strong, nullable) NSDate *arrivalDate;
@property (nonatomic, copy, nullable) NSString *departureLocalString;
@property (nonatomic, copy, nullable) NSString *arrivalLocalString;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end

///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Estimate Directions set
///-----------------------------------------------------------------------------

/**
 An object containing estimate directions info usable for display.
 */
@interface TKEstimateDirectionsInfo : NSObject

///----------------------
/// @name Properties
///----------------------

@property (nonatomic, strong) CLLocation *startLocation;
@property (nonatomic, strong) CLLocation *endLocation;
@property (atomic) TKDirectionAvoidOption avoidOption;
@property (nonatomic, copy, nullable) NSString *waypointsPolyline;

@property (atomic) CLLocationDistance airDistance;

@property (atomic) CLLocationDistance walkDistance;
@property (atomic) CLLocationDistance bikeDistance;
@property (atomic) CLLocationDistance carDistance;
@property (atomic) CLLocationDistance flyDistance;

@property (atomic) NSTimeInterval walkTime;
@property (atomic) NSTimeInterval bikeTime;
@property (atomic) NSTimeInterval carTime;
@property (atomic) NSTimeInterval flyTime;

@end

NS_ASSUME_NONNULL_END
