//
//  TKMapPlaceAnnotation.h
//  TravelKit
//
//  Created by Michal Zelinka on 03/05/2017.
//  Copyright (c) 2017- Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <TravelKit/TKPlace.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Object entity carrying information about a map point.
 */
@interface TKMapPlaceAnnotation : NSObject <MKAnnotation>

///---------------------------------------------------------------------------------------
/// @name Properties
///---------------------------------------------------------------------------------------

/// Annotation title.
@property (nonatomic, copy, nullable) NSString *title;
/// Annotation subtitle.
@property (nonatomic, copy, nullable) NSString *subtitle;
/// Annotation coordinate.
@property (nonatomic) CLLocationCoordinate2D coordinate;
/// Annotation location.
@property (nonatomic, strong, nonnull) CLLocation *location;
/// Assigned `TKPlace` object of the annotation.
@property (nonatomic, strong, nonnull) TKPlace *place;
/// Pixel size of the annotation.
@property (atomic) double pixelSize;

///---------------------------------------------------------------------------------------
/// @name Methods
///---------------------------------------------------------------------------------------

/// :nodoc:
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/**
 Default initialiser.

 @param place `TKPlace` object to create an annotation for.
 @return Initialised object.
 */
- (instancetype)initWithPlace:(TKPlace *)place;

@end

NS_ASSUME_NONNULL_END
