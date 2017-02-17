//
//  TKPlacesQuery.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TKMapRegion.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TKPlaceType) {
	TKPlaceTypeUnknown = 0,
	TKPlaceTypePOI,
	TKPlaceTypeCity,
	TKPlaceTypeCountry,
};

@interface TKPlacesQuery : NSObject

@property (nonatomic, copy, nullable) NSString *searchTerm;
@property (nonatomic, strong, nullable) TKMapRegion *region;
@property (nonatomic, copy, nullable) NSArray<NSString *> *categories;
@property (nonatomic, copy, nullable) NSArray<NSString *> *tags;
@property (nonatomic, copy, nullable) NSString *parentID;
@property (atomic) TKPlaceType type;
@property (atomic) NSUInteger limit;

//@property (nonatomic, copy, nullable) NSArray<NSString *> *quadKeys;

@end

NS_ASSUME_NONNULL_END
