//
//  MapWorkers.m
//  Tripomatic
//
//  Created by Michal Zelinka on 03/02/16.
//  Copyright © 2016 Tripomatic. All rights reserved.
//

#import "MapWorkers.h"

#define MINMAX(a, x, b) MIN(MAX(a, x), b)

#pragma mark - Quadkeys stuff


int MapSize(int levelOfDetail)
{
	if (levelOfDetail == 23)
		return INT_MAX;

	return 256 << levelOfDetail;
}

MapPoint latLongToPixelXY(CLLocationDegrees lat, CLLocationDegrees lon, int levelOfDetail)
{
	lat = MINMAX(-85.05112878, lat, 85.05112878);
	lon = MINMAX(-180, lon, 180);

	double x = (lon + 180) / 360.0;
	double sinLatitude = sin(lat * M_PI / 180);
	double y = 0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * M_PI);

	int mapSize = MapSize(levelOfDetail);
	double pixelX = MINMAX(0, x * mapSize + 0.5, mapSize - 1);
	double pixelY = MINMAX(0, y * mapSize + 0.5, mapSize - 1);

	return MapPointMake(pixelX, pixelY);
}

MapPoint pixelXYToTileXY(double pixelX, double pixelY)
{
	return MapPointMake(pixelX / 256, pixelY / 256);
}

NSString *tileXYToQuadKey(int tileX, int tileY, int levelOfDetail)
{
	NSMutableString *quadKey = [NSMutableString string];

	for (int i = levelOfDetail; i > 0; i--)
	{
		int digit = 0;
		int mask = 1 << (i - 1);
		if ((tileX & mask) != 0)
			digit++;
		if ((tileY & mask) != 0)
			digit += 2;
		[quadKey appendString:[@(digit) stringValue]];
	}

	return quadKey;
}

NSString *toQuadKey(CLLocationDegrees lat, CLLocationDegrees lon, int levelOfDetail)
{
	//	if (levelOfDetail < 1 || levelOfDetail > 23)
	//		throw "levelOfDetail needs to be between 1 and 23";

	MapPoint pixelXY = latLongToPixelXY(lat, lon, levelOfDetail);
	MapPoint tileXY = pixelXYToTileXY(pixelXY.x, pixelXY.y);
	return tileXYToQuadKey(tileXY.x, tileXY.y, levelOfDetail);
}

double approximateZoomLevelForLatitudeSpan(CLLocationDegrees latitudeSpan)
{
	return 8.257237*pow(latitudeSpan, -0.1497541);
}

NSArray *decodePolyLineFromString(NSString *polylineString)
{
	@try
	{
		NSMutableString *encoded = [polylineString mutableCopy];
		[encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\"
									options:NSLiteralSearch
									  range:NSMakeRange(0, [encoded length])];

		NSInteger len = [encoded length];
		NSInteger index = 0, lat = 0, lng = 0;
		NSMutableArray *array = [[NSMutableArray alloc] init];

		while (index < len) {
			NSInteger b;
			NSInteger shift = 0;
			NSInteger result = 0;
			do {
				b = [encoded characterAtIndex:index++] - 63;
				result |= (b & 0x1f) << shift;
				shift += 5;
			} while (b >= 0x20);
			NSInteger dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
			lat += dlat;
			shift = 0;
			result = 0;
			do {
				b = [encoded characterAtIndex:index++] - 63;
				result |= (b & 0x1f) << shift;
				shift += 5;
			} while (b >= 0x20);
			NSInteger dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
			lng += dlng;
			NSNumber *latitude = @(lat * 1e-5);
			NSNumber *longitude = @(lng * 1e-5);

			CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitude floatValue] longitude:[longitude floatValue]];
			[array addObject:location];
		}

		return array;
	}
	@catch (NSException *exception)
	{
		return nil;
	}
}

NSString *encodePolyLineFromPoints(NSArray *points)
{
	NSMutableString *encodedString = [NSMutableString string];
	int val = 0;
	int value = 0;
	CLLocationCoordinate2D prevCoordinate = CLLocationCoordinate2DMake(0, 0);

	for (CLLocation *location in points)
	{
		CLLocationCoordinate2D coordinate = location.coordinate;

		// Encode latitude
		val = round((coordinate.latitude - prevCoordinate.latitude) * 1e5);
		val = (val < 0) ? ~(val<<1) : (val <<1);
		while (val >= 0x20) {
			value = (0x20|(val & 31)) + 63;
			[encodedString appendFormat:@"%c", value];
			val >>= 5;
		}
		[encodedString appendFormat:@"%c", val + 63];

		// Encode longitude
		val = round((coordinate.longitude - prevCoordinate.longitude) * 1e5);
		val = (val < 0) ? ~(val<<1) : (val <<1);
		while (val >= 0x20) {
			value = (0x20|(val & 31)) + 63;
			[encodedString appendFormat:@"%c", value];
			val >>= 5;
		}
		[encodedString appendFormat:@"%c", val + 63];

		prevCoordinate = coordinate;
	}
	
	return encodedString;
}
