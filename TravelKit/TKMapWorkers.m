//
//  TKMapWorkers.m
//  Tripomatic
//
//  Created by Michal Zelinka on 03/02/16.
//  Copyright © 2016 Tripomatic. All rights reserved.
//

#import "TKMapWorkers+Private.h"

#define MINMAX(a, x, b) MIN(MAX(a, x), b)

#pragma mark - Quadkeys stuff


int TK_mapSize(int levelOfDetail)
{
	if (levelOfDetail == 23)
		return INT_MAX;

	return 256 << levelOfDetail;
}

TKMapPoint TK_latLongToPixelXY(CLLocationDegrees lat, CLLocationDegrees lng, int levelOfDetail)
{
	CLLocationDegrees fLat = MINMAX(-85.05112878, lat, 85.05112878);
	CLLocationDegrees fLng = MINMAX(-180, lng, 180);

	double x = (fLng + 180) / 360.0;
	double sinLatitude = sin(fLat * M_PI / 180);
	double y = 0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * M_PI);

	int mapSize = TK_mapSize(levelOfDetail);
	double pixelX = MINMAX(0, x * mapSize + 0.5, mapSize - 1);
	double pixelY = MINMAX(0, y * mapSize + 0.5, mapSize - 1);

	return TKMapPointMake(pixelX, pixelY);
}

TKMapPoint TK_pixelXYToTileXY(double pixelX, double pixelY)
{
	return TKMapPointMake(pixelX / 256, pixelY / 256);
}

NSString *TK_tileXYToQuadKey(int tileX, int tileY, int levelOfDetail)
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

NSString *TK_toQuadKey(CLLocationDegrees lat, CLLocationDegrees lon, int levelOfDetail)
{
//	if (levelOfDetail < 1 || levelOfDetail > 23)
//		throw "levelOfDetail needs to be between 1 and 23";

	TKMapPoint pixelXY = TK_latLongToPixelXY(lat, lon, levelOfDetail);
	TKMapPoint tileXY = TK_pixelXYToTileXY(pixelXY.x, pixelXY.y);
	return TK_tileXYToQuadKey((int)tileXY.x, (int)tileXY.y, levelOfDetail);
}

double TK_approximateZoomLevelForLatitudeSpan(CLLocationDegrees latitudeSpan)
{
	return 8.257237*pow(latitudeSpan, -0.1497541);
}

NSArray *TK_decodePolyLineFromString(NSString *polylineString)
{
	@try
	{
		NSMutableString *encoded = [polylineString mutableCopy];
		[encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\"
									options:NSLiteralSearch
									  range:NSMakeRange(0, [encoded length])];

		NSUInteger len = [encoded length], index = 0;
		NSInteger lat = 0, lng = 0;
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

NSString *TK_encodePolyLineFromPoints(NSArray *points)
{
	NSMutableString *encodedString = [NSMutableString string];
	int val = 0;
	int value = 0;
	CLLocationCoordinate2D prevCoordinate = CLLocationCoordinate2DMake(0, 0);

	for (CLLocation *location in points)
	{
		CLLocationCoordinate2D coordinate = location.coordinate;

		// Encode latitude
		val = (int)round((coordinate.latitude - prevCoordinate.latitude) * 1e5);
		val = (val < 0) ? ~(val<<1) : (val <<1);
		while (val >= 0x20) {
			value = (0x20|(val & 31)) + 63;
			[encodedString appendFormat:@"%c", value];
			val >>= 5;
		}
		[encodedString appendFormat:@"%c", val + 63];

		// Encode longitude
		val = (int)round((coordinate.longitude - prevCoordinate.longitude) * 1e5);
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
