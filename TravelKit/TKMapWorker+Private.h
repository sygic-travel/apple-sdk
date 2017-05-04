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

@end

NS_ASSUME_NONNULL_END
