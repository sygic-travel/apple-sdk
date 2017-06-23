//
//  TKMapWorker+Private.h
//  Tripomatic
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


/// Quad keys

+ (NSArray<NSString *> *)quadKeysForRegion:(MKCoordinateRegion)region;
+ (NSString *)quadKeyForCoordinate:(CLLocationCoordinate2D)coorinate detailLevel:(UInt8)level;
+ (UInt8)detailLevelForRegion:(MKCoordinateRegion)region;


/// Regions

+ (double)approximateZoomLevelForLatitudeSpan:(CLLocationDegrees)latitudeSpan;


/// Polylines

+ (NSArray<CLLocation *> *)pointsFromPolyline:(NSString *)polyline;
+ (NSString *)polylineFromPoints:(NSArray<CLLocation *> *)points;


/// Spreading

+ (NSArray<TKMapPlaceAnnotation *> *)spreadAnnotationsForPlaces:(NSArray<TKPlace *> *)places
            mapRegion:(MKCoordinateRegion)region mapViewSize:(CGSize)size;

+ (void)interpolateNewAnnotations:(NSArray<TKMapPlaceAnnotation *> *)newAnnotations
                   oldAnnotations:(NSArray<TKMapPlaceAnnotation *> *)oldAnnotations
                            toAdd:(NSMutableArray<TKMapPlaceAnnotation *> *)toAdd
                           toKeep:(NSMutableArray<TKMapPlaceAnnotation *> *)toKeep
                         toRemove:(NSMutableArray<TKMapPlaceAnnotation *> *)toRemove;

@end

NS_ASSUME_NONNULL_END
