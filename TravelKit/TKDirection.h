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
	/// Unknown mode fallback.
	TKDirectionModeNone             = (0),
	/// Walking mode.
	TKDirectionModeWalk             = (1 << 0),
	/// Car mode.
	TKDirectionModeCar              = (1 << 1),
	/// Public transport mode.
	TKDirectionModePublicTransport  = (1 << 2),
	/// Default mode setting.
	TKDirectionModeDefault          = (TKDirectionModeWalk | TKDirectionModeCar | TKDirectionModePublicTransport),
}; // ABI-EXPORTED

/**
 An enum indicating options to fine-tune transport options. Only useful with Car mode.
 */
typedef NS_OPTIONS(NSUInteger, TKDirectionAvoidOption) {
	/// No avoid options. Default.
	TKDirectionAvoidOptionNone        = (0),
	/// A bit indicating an option to avoid Tolls.
	TKDirectionAvoidOptionTolls       = (1 << 0),
	/// A bit indicating an option to avoid Highways.
	TKDirectionAvoidOptionHighways    = (1 << 1),
	/// A bit indicating an option to avoid Ferries.
	TKDirectionAvoidOptionFerries     = (1 << 2),
	/// A bit indicating an option to avoid Unpaved paths.
	TKDirectionAvoidOptionUnpaved     = (1 << 3),
}; // ABI-EXPORTED

/**
 The mode of a specific step within a calculated direction.
 */
typedef NS_ENUM(NSUInteger, TKDirectionStepMode) {
	/// Unknown mode. Used as a fallback.
	TKDirectionStepModeUnknown = 0,
	/// Pedestrian step.
	TKDirectionStepModePedestrian,
	/// Car step.
	TKDirectionStepModeCar,
	/// Plane flight step.
	TKDirectionStepModePlane,
	/// Bike ride step.
	TKDirectionStepModeBike,
	/// Boat step.
	TKDirectionStepModeBoat,
	/// Bus ride step.
	TKDirectionStepModeBus,
	/// Funicular ride step.
	TKDirectionStepModeFunicular,
	/// Subway ride step.
	TKDirectionStepModeSubway,
	/// Taxi step.
	TKDirectionStepModeTaxi,
	/// Train step.
	TKDirectionStepModeTrain,
	/// Tram step.
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

/// Mode of transport.
@property (atomic) TKDirectionMode mode;

/// Source location where to calculate the directions from.
@property (nonatomic, strong, readonly) CLLocation *sourceLocation;

/// Destination location where to calculate the directions to.
@property (nonatomic, strong, readonly) CLLocation *destinationLocation;

/// Waypoints along the calculated route.
@property (nonatomic, copy, nullable) NSArray<CLLocation *> *waypoints;

/// Optional cases of the route to avoid.
@property (atomic) TKDirectionAvoidOption avoidOption;

/// Departure date to use for calculation.
///
/// @note Timezone will be ignored; date and time values of the given time will be taken as local.
@property (nonatomic, strong, nullable) NSDate *relativeDepartureDate;

/// Arrival date to use for calculation.
///
/// @note Timezone will be ignored; date and time values of the given time will be taken as local.
@property (nonatomic, strong, nullable) NSDate *relativeArrivalDate;

/// Calculated string key for caching purposes.
@property (nonatomic, readonly, copy) NSString *cacheKey;

/// Default initializer.
+ (nullable instancetype)queryFromLocation:(CLLocation *)sourceLocation toLocation:(CLLocation *)destinationLocation;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

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

/// Source location of the calculated directions.
@property (nonatomic, strong, readonly) CLLocation *sourceLocation;
/// Destination location of the calculated directions.
@property (nonatomic, strong, readonly) CLLocation *destinationLocation;
/// Air distance between the source and the destination location.
@property (atomic, readonly) CLLocationDistance airDistance;

/// Calculated cases of the route to avoid.
@property (atomic, readonly) TKDirectionAvoidOption avoidOption;
/// Waypoints along the calculated route.
@property (nonatomic, copy, nullable, readonly) NSArray<CLLocation *> *waypoints;

/// Array of the calculated directions.
@property (nonatomic, copy, readonly) NSArray<TKDirection *> *directions;

// Optional ideal direction quick accessor.
@property (nonatomic, strong, nullable, readonly) TKDirection *idealDirection;
// Optional ideal walk direction quick accessor.
@property (nonatomic, strong, nullable, readonly) TKDirection *idealWalkDirection;
// Optional ideal car direction quick accessor.
@property (nonatomic, strong, nullable, readonly) TKDirection *idealCarDirection;
// Optional ideal public transport direction quick accessor.
@property (nonatomic, strong, nullable, readonly) TKDirection *idealPublicTransportDirection;

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

/// Calculated duration of the direction.
@property (atomic, readonly) NSTimeInterval duration;
/// Calculated distance of the direction.
@property (atomic, readonly) CLLocationDistance distance;

/// Mode of the direction.
@property (atomic, readonly) TKDirectionMode mode;
/// Particular steps of the direction.
@property (nonatomic, copy, readonly) NSArray<TKDirectionStep *> *steps;

/// Calculated polyline.
@property (nonatomic, readonly) NSString *calculatedPolyline;
/// Source attribution.
@property (nonatomic, copy, nullable, readonly) NSString *source;

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

/// Calculated duration of the step.
@property (atomic) NSTimeInterval duration;
/// Calculated distance of the step.
@property (atomic) CLLocationDistance distance;

/// Mode of the step.
@property (atomic) TKDirectionStepMode mode;
/// Polyline of the step.
@property (nonatomic, copy, nullable) NSString *polyline;

/// Optional name of the origin location.
@property (nonatomic, copy, nullable) NSString *originName;
/// Optional coordinate of the origin location.
@property (nonatomic, strong, nullable) CLLocation *originLocation;

/// Optional name of the destination location.
@property (nonatomic, copy, nullable) NSString *destinationName;
/// Optional coordinate of the destination location.
@property (nonatomic, strong, nullable) CLLocation *destinationLocation;

/// Optional stops along the step.
@property (nonatomic, copy) NSArray<TKDirectionIntermediateStop *> *intermediateStops;

/// Optional short name of the public transport line. Examples: _6_, _X12_, _B_, _Bakerloo Line_, …
@property (nonatomic, copy, nullable) NSString *shortName;
/// Optional long name of the public transport line, usually describing the route. Example: _Brooklyn - Manhattan - Staten Island_
@property (nonatomic, copy, nullable) NSString *longName;
/// Optional headsign. Mainly used for public transport. Examples: _Moorgate, _Chesham_, _Aldgate_, …
@property (nonatomic, copy, nullable) NSString *headsign;
/// Optional public transport line color. Provided in RGB HEX.
@property (nonatomic, strong, nullable) NSNumber *lineColor;
/// Attribution string.
@property (nonatomic, copy, nullable) NSString *attribution;

// Departure date of the step.
@property (nonatomic, strong, nullable) NSDate *departureDate;
/// Departure date string. ISO-8601 format without the timezone.
@property (nonatomic, copy, nullable) NSString *departureLocalString;
// Arrival date of the step.
@property (nonatomic, strong, nullable) NSDate *arrivalDate;
/// Arrival date string. ISO-8601 format without the timezone.
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

/// Optional stop name.
@property (nonatomic, copy, nullable) NSString *name;

/// Location of the stop.
@property (nonatomic, strong) CLLocation *location;

/// Calculated arrival date.
@property (nonatomic, strong, nullable) NSDate *arrivalDate;

/// Calculated arrival date string. ISO-8601 format without the timezone.
@property (nonatomic, copy, nullable) NSString *arrivalLocalString;

/// Calculated departure date.
@property (nonatomic, strong, nullable) NSDate *departureDate;

/// Calculated departure date string. ISO-8601 format without the timezone.
@property (nonatomic, copy, nullable) NSString *departureLocalString;

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

/// Source location of the calculated directions.
@property (nonatomic, strong, readonly) CLLocation *sourceLocation;
/// Destination location of the calculated directions.
@property (nonatomic, strong, readonly) CLLocation *destinationLocation;
/// Air distance between the source and the destination location.
@property (atomic, readonly) CLLocationDistance airDistance;

/// Calculated cases of the route to avoid.
@property (atomic, readonly) TKDirectionAvoidOption avoidOption;
/// Waypoints along the calculated route.
@property (nonatomic, copy, nullable, readonly) NSArray<CLLocation *> *waypoints;

/// Estimated walk distance.
@property (atomic, readonly) CLLocationDistance walkDistance;
/// Estimated bike distance.
@property (atomic, readonly) CLLocationDistance bikeDistance;
/// Estimated car distance.
@property (atomic, readonly) CLLocationDistance carDistance;
/// Estimated fly distance.
@property (atomic, readonly) CLLocationDistance flyDistance;

/// Estimated walk duration.
@property (atomic, readonly) NSTimeInterval walkDuration;
/// Estimated bike duration.
@property (atomic, readonly) NSTimeInterval bikeDuration;
/// Estimated car duration.
@property (atomic, readonly) NSTimeInterval carDuration;
/// Estimated fly duration.
@property (atomic, readonly) NSTimeInterval flyDuration;

+ (nullable instancetype)infoFromLocation:(CLLocation *)sourceLocation toLocation:(CLLocation *)destinationLocation;
+ (nullable instancetype)infoForQuery:(TKDirectionsQuery *)query;

@end

NS_ASSUME_NONNULL_END
