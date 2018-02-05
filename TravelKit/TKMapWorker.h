//
//  TKMapWorker.h
//  TravelKit
//
//  Created by Michal Zelinka on 03/02/16.
//  Copyright © 2016 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import <TravelKit/TKPlace.h>
#import <TravelKit/TKMapRegion.h>
#import <TravelKit/TKMapPlaceAnnotation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKMapWorker : NSObject


///---------------------------------------------------------------------------------------
/// @name Quad keys
///---------------------------------------------------------------------------------------

/**
 Naive method for fetching standardised quad keys for the given region.

 @param region Region to calculate quad keys for.
 @return Array of quad key strings.
 */
+ (NSArray<NSString *> *)quadKeysForRegion:(MKCoordinateRegion)region;

+ (NSString *)quadKeyForCoordinate:(CLLocationCoordinate2D)coorinate detailLevel:(UInt8)level;

+ (UInt8)detailLevelForRegion:(MKCoordinateRegion)region;


///---------------------------------------------------------------------------------------
/// @name Regions
///---------------------------------------------------------------------------------------

/**
 A helper method used to receive an approximated zoom level value for a given latitude span.

 @param latitudeSpan A latitude span to calculate the approximate zoom level for.
 @return Approximate zoom level value.
 */
+ (double)approximateZoomLevelForLatitudeSpan:(CLLocationDegrees)latitudeSpan;


///---------------------------------------------------------------------------------------
/// @name Polylines
///---------------------------------------------------------------------------------------

/**
 A function used to convert a polyline into `CLLocation` points.

 @param polyline Given polyline string.
 @return Calculated array of `CLLocation` points.
 */
+ (NSArray<CLLocation *> *)pointsFromPolyline:(NSString *)polyline;

/**
 A function used to convert `CLLocation` points into a polyline.

 @param points Given array of `CLLocation` points.
 @return Calculated polyline string.
 */
+ (NSString *)polylineFromPoints:(NSArray<CLLocation *> *)points;


///---------------------------------------------------------------------------------------
/// @name Spreading
///---------------------------------------------------------------------------------------

/**
 Spreading method calculating optimally spread `TKMapPlaceAnnotation` objects in 3 basic sizes.

 @param places Places to spread and create `TKMapPlaceAnnotation` objects for.
 @param region Region where to spread the annotations.
 @param size Standard size of the Map view. May be taken from either `-frame` or `-bounds`.
 @return Array of spread annotations.
 */
+ (NSArray<TKMapPlaceAnnotation *> *)spreadAnnotationsForPlaces:(NSArray<TKPlace *> *)places
            mapRegion:(MKCoordinateRegion)region mapViewSize:(CGSize)size;

/**
 Interpolating method for sorting Map annotations.

 @param newAnnotations Array of annotations you'd like to display.
 @param oldAnnotations Array of annotations currently displayed.
 @param toAdd Out array of annotations to add to the map.
 @param toKeep Out array of annotations to keep on the map.
 @param toRemove Out array of annotations to remove from the map.

 @note `toAdd`, `toKeep` and `toRemove` are regular given mutable arrays this method will fill.
       Annotations in `toAdd` array are meant to be used with `-addAnnotations:` or equivalent
       method of your Map view, `toRemove` accordingly with `-removeAnnotations:` method.
 */
+ (void)interpolateNewAnnotations:(NSArray<TKMapPlaceAnnotation *> *)newAnnotations
                   oldAnnotations:(NSArray<TKMapPlaceAnnotation *> *)oldAnnotations
                            toAdd:(NSMutableArray<TKMapPlaceAnnotation *> *)toAdd
                           toKeep:(NSMutableArray<TKMapPlaceAnnotation *> *)toKeep
                         toRemove:(NSMutableArray<TKMapPlaceAnnotation *> *)toRemove;

@end

NS_ASSUME_NONNULL_END
