//
//  TKMapWorker.m
//  TravelKit
//
//  Created by Michal Zelinka on 03/02/16.
//  Copyright © 2016 Tripomatic. All rights reserved.
//

#import "Foundation+TravelKit.h"
#import "TKMapWorker.h"

#define MINMAX(a, x, b) MIN(MAX(a, x), b)


typedef struct {
	double x;
	double y;
} TKMapPoint;

typedef struct {
	int64_t x;
	int64_t y;
} TKTilePoint;


@implementation TKMapWorker


#pragma mark -
#pragma mark Quadkeys


+ (double)tileMapSizeForDetailLevel:(UInt8)level
{
	if (level == 23)
		return INT_MAX;

	return 256 << level;
}

+ (TKMapPoint)pixelPointForCoordinate:(CLLocationCoordinate2D)coordinate detailLevel:(UInt8)level
{
	CLLocationDegrees lat = coordinate.latitude;
	CLLocationDegrees lng = coordinate.longitude;

	CLLocationDegrees fLat = MINMAX(-85.05112878, lat, 85.05112878);
	CLLocationDegrees fLng = MINMAX(-180, lng, 180);

	double x = (fLng + 180) / 360.0;
	double sinLatitude = sin(fLat * M_PI / 180);
	double y = 0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * M_PI);

	double mapSize = [self tileMapSizeForDetailLevel:level];
	double pixelX = MINMAX(0, x * mapSize + 0.5, mapSize - 1);
	double pixelY = MINMAX(0, y * mapSize + 0.5, mapSize - 1);

	return (TKMapPoint){ pixelX, pixelY };
}

+ (TKTilePoint)tilePointForPixelPoint:(TKMapPoint)pixelPoint
{
	return (TKTilePoint){ ((int64_t)pixelPoint.x) / 256, ((int64_t)pixelPoint.y) / 256 };
}

+ (NSString *)quadKeyForTilePoint:(TKTilePoint)tilePoint detailLevel:(UInt8)level
{
	NSMutableString *quadKey = [NSMutableString string];

	for (int i = level; i > 0; i--)
	{
		int digit = 0;
		int mask = 1 << (i - 1);
		if ((tilePoint.x & mask) != 0)
			digit++;
		if ((tilePoint.y & mask) != 0)
			digit += 2;
		[quadKey appendString:[@(digit) stringValue]];
	}

	return quadKey;
}

+ (NSString *)quadKeyForCoordinate:(CLLocationCoordinate2D)coorinate detailLevel:(UInt8)level
{
//	if (levelOfDetail < 1 || levelOfDetail > 23)
//		throw "levelOfDetail needs to be between 1 and 23";

	TKMapPoint pixelPoint = [self pixelPointForCoordinate:coorinate detailLevel:level];
	TKTilePoint tilePoint = [self tilePointForPixelPoint:pixelPoint];

	return [self quadKeyForTilePoint:tilePoint detailLevel:level];
}

+ (UInt8)detailLevelForRegion:(MKCoordinateRegion)region
{
	double zoomLevel = [self approximateZoomLevelForLatitudeSpan:region.span.latitudeDelta];
	return (UInt8)round(MINMAX(1, zoomLevel, 18));
}

+ (NSArray<NSString *> *)quadKeysForRegion:(MKCoordinateRegion)region
{
	UInt8 zoomLevel = [self detailLevelForRegion:region];

	NSMutableArray<CLLocation *> *checkPoints = [NSMutableArray array];

	CLLocationDegrees latSpan = region.span.latitudeDelta;
	CLLocationDegrees lngSpan = region.span.longitudeDelta;

	for (uint i = 0; i <= 10; i++)
		for (uint j = 0; j <= 10; j++)
		{
			CLLocationDegrees locLat = (region.center.latitude-latSpan/2) + i*(latSpan/10);
			CLLocationDegrees locLng = (region.center.longitude-lngSpan/2) + j*(lngSpan/10);
			[checkPoints addObject:[[CLLocation alloc] initWithLatitude:locLat longitude:locLng]];
		}

	NSMutableOrderedSet<NSString *> *quadKeys = [NSMutableOrderedSet orderedSetWithCapacity:10];

	for (CLLocation *location in checkPoints) {
		NSString *quadKey = [self quadKeyForCoordinate:location.coordinate detailLevel:zoomLevel];
		if (quadKey) [quadKeys addObject:quadKey];
	}

	return [quadKeys array];
}


#pragma mark -
#pragma mark Regions


+ (double)approximateZoomLevelForLatitudeSpan:(CLLocationDegrees)latitudeSpan
{
	return 8.257237*pow(latitudeSpan, -0.1497541);
}


#pragma mark -
#pragma mark Polylines


+ (NSArray<CLLocation *> *)pointsFromPolyline:(NSString *)polyline
{
	@try
	{
		NSMutableString *encoded = [polyline mutableCopy];
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
		return @[ ];
	}
}

+ (NSString *)polylineFromPoints:(NSArray<CLLocation *> *)points
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


#pragma mark -
#pragma mark Spreading


+ (NSArray<TKMapPlaceAnnotation *> *)spreadAnnotationsForPlaces:(NSArray<TKPlace *> *)places
	mapRegion:(MKCoordinateRegion)region mapViewSize:(CGSize)size
{
	NSMutableArray<TKPlace *> *workingPlaces = [places mutableCopy];

	// Minimal distance between annotations with basic size of 64 pixels
	CLLocationDistance minDistance = region.span.latitudeDelta / (size.height / 76) * 111000;

	NSMutableArray<TKMapPlaceAnnotation *> *annotations = [NSMutableArray arrayWithCapacity:workingPlaces.count];

	NSMutableArray<TKPlace *> *firstClass   = [NSMutableArray arrayWithCapacity:workingPlaces.count / 4];
	NSMutableArray<TKPlace *> *secondClass  = [NSMutableArray arrayWithCapacity:workingPlaces.count / 2];
	NSMutableArray<TKPlace *> *thirdClass   = [NSMutableArray arrayWithCapacity:workingPlaces.count / 2];

	for (TKPlace *p in workingPlaces)
	{
		if (p.rating.floatValue < 6.0 || !p.thumbnailURL) continue;

		BOOL conflict = NO;
		for (TKPlace *i in firstClass)
			if ([i.location distanceFromLocation:p.location] < minDistance)
			{ conflict = YES; break; }
		if (!conflict) [firstClass addObject:p];
	}

	[workingPlaces removeObjectsInArray:firstClass];

	for (TKPlace *p in workingPlaces)
	{
		if (!p.thumbnailURL) continue;

		BOOL conflict = NO;
		for (TKPlace *i in firstClass)
			if ([i.location distanceFromLocation:p.location] < 0.95*minDistance)
			{ conflict = YES; break; }
		for (TKPlace *i in secondClass)
			if ([i.location distanceFromLocation:p.location] < 0.85*minDistance)
			{ conflict = YES; break; }
		if (!conflict) [secondClass addObject:p];
	}

	[workingPlaces removeObjectsInArray:secondClass];

	for (TKPlace *p in workingPlaces)
	{
		BOOL conflict = NO;
		for (TKPlace *i in firstClass)
			if ([i.location distanceFromLocation:p.location] < 0.7*minDistance)
			{ conflict = YES; break; }
		for (TKPlace *i in secondClass)
			if ([i.location distanceFromLocation:p.location] < 0.6*minDistance)
			{ conflict = YES; break; }
		for (TKPlace *i in thirdClass)
			if ([i.location distanceFromLocation:p.location] < 0.5*minDistance)
			{ conflict = YES; break; }
		if (!conflict) [thirdClass addObject:p];
	}

	NSArray<TKMapPlaceAnnotation *> *classAnnotations = [firstClass
	  mappedArrayUsingBlock:^id _Nullable(TKPlace * _Nonnull place) {
		TKMapPlaceAnnotation *anno = [[TKMapPlaceAnnotation alloc] initWithPlace:place];
		anno.pixelSize = 64;
		return anno;
	}];

	[annotations addObjectsFromArray:classAnnotations];

	classAnnotations = [secondClass
	  mappedArrayUsingBlock:^id _Nullable(TKPlace * _Nonnull place) {
		TKMapPlaceAnnotation *anno = [[TKMapPlaceAnnotation alloc] initWithPlace:place];
		anno.pixelSize = 42;
		return anno;
	}];

	[annotations addObjectsFromArray:classAnnotations];

	classAnnotations = [thirdClass
	  mappedArrayUsingBlock:^id _Nullable(TKPlace * _Nonnull place) {
		TKMapPlaceAnnotation *anno = [[TKMapPlaceAnnotation alloc] initWithPlace:place];
		anno.pixelSize = 14;
		return anno;
	}];

	[annotations addObjectsFromArray:classAnnotations];

	return annotations;
}

+ (void)interpolateNewAnnotations:(NSArray<TKMapPlaceAnnotation *> *)newAnnotations
                   oldAnnotations:(NSArray<TKMapPlaceAnnotation *> *)oldAnnotations
                            toAdd:(NSMutableArray<TKMapPlaceAnnotation *> *)toAdd
                           toKeep:(NSMutableArray<TKMapPlaceAnnotation *> *)toKeep
                         toRemove:(NSMutableArray<TKMapPlaceAnnotation *> *)toRemove
{
	NSArray<NSString *> *displayedIDs = [newAnnotations
	  mappedArrayUsingBlock:^id _Nullable(TKMapPlaceAnnotation *p) {
		return p.place.ID;
	}];

	for (TKMapPlaceAnnotation *p in oldAnnotations)
	{
		if (![p isKindOfClass:[TKMapPlaceAnnotation class]]) continue;

		if ([displayedIDs containsObject:p.place.ID])
			[toKeep addObject:p];
		else [toRemove addObject:p];
	}

	for (TKMapPlaceAnnotation *p in newAnnotations)
	{
		if (![p isKindOfClass:[TKMapPlaceAnnotation class]]) continue;

		BOOL displayed = NO;
		for (TKMapPlaceAnnotation *k in toKeep)
			if ([k.place.ID isEqual:p.place.ID])
				displayed = YES;
		if (!displayed)
			[toAdd addObject:p];
	}
}

@end
