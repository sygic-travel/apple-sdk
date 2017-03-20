//
//  TKPlace.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "TKReference.h"
#import "TKMedium.h"

typedef NS_ENUM(NSUInteger, TKPlaceLevel) {
	TKPlaceLevelUnknown = 0,
	TKPlaceLevelPOI,
	TKPlaceLevelNeighbourhood,
	TKPlaceLevelLocality,
	TKPlaceLevelSettlement,
	TKPlaceLevelVillage,
	TKPlaceLevelTown,
	TKPlaceLevelCity,
	TKPlaceLevelCounty,
	TKPlaceLevelRegion,
	TKPlaceLevelIsland,
	TKPlaceLevelArchipelago,
	TKPlaceLevelState,
	TKPlaceLevelCountry,
	TKPlaceLevelContinent,
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
@property (nonatomic, strong, nullable) NSNumber *price;
@property (nonatomic, strong, nullable) NSNumber *rating;
@property (nonatomic, strong, nullable) NSNumber *duration;
@property (nonatomic, copy, nullable) NSString *marker;
@property (nonatomic, copy, nullable) NSArray<NSString *> *categories;
@property (nonatomic, copy, nullable) NSArray<NSString *> *parents;
@property (nonatomic, copy, nullable) NSArray<NSString *> *flags;

@property (nonatomic, strong, nullable) TKPlaceDetail *detail;

@property (nonatomic, copy, nullable, readonly) NSArray<NSString *> *displayableCategories;

@end


@interface TKPlaceTag : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy, nullable) NSString *name;

@end


@interface TKPlaceDetail : NSObject

@property (nonatomic, copy, nullable) NSString *fullDescription;
@property (nonatomic, copy, nullable) NSArray<TKPlaceTag *> *tags;
@property (nonatomic, copy, nullable) NSArray<TKReference *> *references;
@property (nonatomic, copy, nullable) NSArray<TKMedium *> *mainMedia; // TODO
@property (nonatomic, copy, nullable) NSString *address;
@property (nonatomic, copy, nullable) NSString *phone;
@property (nonatomic, copy, nullable) NSString *email;
@property (nonatomic, strong, nullable) NSNumber *duration;
@property (nonatomic, copy, nullable) NSString *openingHours;
@property (nonatomic, copy, nullable) NSString *admission;

@end

NS_ASSUME_NONNULL_END
