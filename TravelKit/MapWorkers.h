//
//  MapWorkers.h
//  Tripomatic
//
//  Created by Michal Zelinka on 03/02/16.
//  Copyright © 2016 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#pragma mark - Quadkeys stuff

struct MapPoint {
	double x;
	double y;
};
typedef struct MapPoint MapPoint;

NS_INLINE MapPoint
MapPointMake(double x, double y)
{
	MapPoint p; p.x = x; p.y = y; return p;
}

// Tiles & Quadkeys

int MapSize(int levelOfDetail);
MapPoint pixelXYToTileXY(double pixelX, double pixelY);
MapPoint latLongToPixelXY(CLLocationDegrees lat, CLLocationDegrees lon, int levelOfDetail);
NSString *tileXYToQuadKey(int tileX, int tileY, int levelOfDetail);
NSString *toQuadKey(CLLocationDegrees lat, CLLocationDegrees lon, int levelOfDetail);

// Regions

double approximateZoomLevelForLatitudeSpan(CLLocationDegrees latitudeSpan);

// Polylines

NSArray *decodePolyLineFromString(NSString *polylineString);
NSString *encodePolyLineFromPoints(NSArray *points);
