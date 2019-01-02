//
//  TKMapRegion.h
//  TravelKit
//
//  Created by Michal Zelinka on 18/02/2016.
//  Copyright (c) 2016- Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>


#pragma mark - Map Region wrapper


NS_ASSUME_NONNULL_BEGIN


/**
 Object entity carrying information about a coordinate region.
 
 This is a simple object whose main purpose is to wrap up the `MKCoordinateRegion` structure.
 */
@interface TKMapRegion : NSObject

///---------------------------------------------------------------------------------------
/// @name Properties
///---------------------------------------------------------------------------------------

/// MapKit-compatible coordinate region structure.
@property (nonatomic, assign) MKCoordinateRegion coordinateRegion;

/// Center location object.
@property (readonly) CLLocation *centerPoint;
/// South-west location object.
@property (readonly) CLLocation *southWestPoint;
/// North-east location object.
@property (readonly) CLLocation *northEastPoint;
/// States information about the region validity.
@property (readonly) BOOL hasValidCoordinate;

///---------------------------------------------------------------------------------------
/// @name Methods
///---------------------------------------------------------------------------------------

/**
 Initializes the map region object using `MKCoordinateRegion`.

 @param region MapKit-compatible coordinate region to use.
 @return Objectified map region.
 */
- (instancetype)initWithCoordinateRegion:(MKCoordinateRegion)region;

/**
 Initializes the map region object using a couple of bounding `CLLocation` points.

 @param southWest South-west bounding `CLLocation` point.
 @param northEast North-east bounding `CLLocation` point.
 @return Objectified map region.
 */
- (instancetype)initWithSouthWestPoint:(CLLocation *)southWest northEastPoint:(CLLocation *)northEast;

/**
 States whether the given location lies inside the map region.

 @param location `CLLocation` point to check.
 @return Boolean value indicating whether the given location lies inside the map region.
 */
- (BOOL)containsLocation:(CLLocation *)location;

@end

NS_ASSUME_NONNULL_END
