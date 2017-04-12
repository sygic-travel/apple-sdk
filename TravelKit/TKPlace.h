//
//  TKPlace.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "TKMapRegion.h"
#import "TKReference.h"
#import "TKMedium.h"

typedef NS_OPTIONS(NSUInteger, TKPlaceLevel) {
	TKPlaceLevelUnknown           = 0,
	TKPlaceLevelPOI               = 1 << 0,
	TKPlaceLevelNeighbourhood     = 1 << 1,
	TKPlaceLevelLocality          = 1 << 2,
	TKPlaceLevelSettlement        = 1 << 3,
	TKPlaceLevelVillage           = 1 << 4,
	TKPlaceLevelTown              = 1 << 5,
	TKPlaceLevelCity              = 1 << 6,
	TKPlaceLevelCounty            = 1 << 7,
	TKPlaceLevelRegion            = 1 << 8,
	TKPlaceLevelIsland            = 1 << 9,
	TKPlaceLevelArchipelago       = 1 << 10,
	TKPlaceLevelState             = 1 << 11,
	TKPlaceLevelCountry           = 1 << 12,
	TKPlaceLevelContinent         = 1 << 13,
};

NS_ASSUME_NONNULL_BEGIN

@class TKPlaceTag, TKPlaceDetail;
@interface TKPlace : NSObject

@property (nonatomic, copy) NSString *ID NS_SWIFT_NAME(ID);
@property (nonatomic, copy) NSString *name;
@property (atomic) TKPlaceLevel level;
@property (nonatomic, copy, nullable) NSString *suffix;
@property (nonatomic, copy, nullable) NSString *perex;
@property (nonatomic, strong, nullable) CLLocation *location;
@property (nonatomic, copy, nullable) NSString *quadKey;
@property (nonatomic, strong, nullable) TKMapRegion *boundingBox;
@property (nonatomic, strong, nullable) NSNumber *price;
@property (nonatomic, strong, nullable) NSNumber *rating;
@property (nonatomic, strong, nullable) NSNumber *duration;
@property (nonatomic, copy, nullable) NSString *marker;
@property (nonatomic, copy, nullable) NSArray<NSString *> *categories;
@property (nonatomic, copy, nullable) NSArray<NSString *> *parents;
@property (nonatomic, copy, nullable) NSArray<NSString *> *flags;

@property (nonatomic, strong, nullable) TKPlaceDetail *detail;

@property (nonatomic, copy, nullable, readonly) NSArray<NSString *> *displayableCategories;
@property (atomic, readonly) NSUInteger displayableHexColor;

@end


@interface TKPlaceTag : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy, nullable) NSString *name;

@end


@interface TKPlaceDetail : NSObject

@property (nonatomic, copy, nullable) NSString *fullDescription; // TODO: Other attrs
@property (nonatomic, copy, nullable) NSArray<TKPlaceTag *> *tags;
@property (nonatomic, copy, nullable) NSArray<TKReference *> *references;
@property (nonatomic, copy, nullable) NSArray<TKMedium *> *mainMedia;
@property (nonatomic, copy, nullable) NSString *address;
@property (nonatomic, copy, nullable) NSString *phone;
@property (nonatomic, copy, nullable) NSString *email;
@property (nonatomic, strong, nullable) NSNumber *duration;
@property (nonatomic, copy, nullable) NSString *openingHours;
@property (nonatomic, copy, nullable) NSString *admission;

@end

NS_ASSUME_NONNULL_END
