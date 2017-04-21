//
//  TKMapWorkers+Private.h
//  Tripomatic
//
//  Created by Michal Zelinka on 03/02/16.
//  Copyright © 2016 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#pragma mark - Quadkeys stuff

typedef struct {
	double x;
	double y;
} TKMapPoint;

NS_INLINE TKMapPoint
TKMapPointMake(double x, double y)
{
	return (TKMapPoint){ x, y };
}

// Tiles & Quadkeys

int TK_mapSize(int levelOfDetail);
TKMapPoint TK_pixelXYToTileXY(double pixelX, double pixelY);
TKMapPoint TK_latLongToPixelXY(CLLocationDegrees lat, CLLocationDegrees lon, int levelOfDetail);
NSString *TK_tileXYToQuadKey(int tileX, int tileY, int levelOfDetail);
NSString *TK_toQuadKey(CLLocationDegrees lat, CLLocationDegrees lon, int levelOfDetail);

// Regions

double TK_approximateZoomLevelForLatitudeSpan(CLLocationDegrees latitudeSpan);

// Polylines

NSArray *TK_decodePolyLineFromString(NSString *polylineString);
NSString *TK_encodePolyLineFromPoints(NSArray *points);
