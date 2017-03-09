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

NS_ASSUME_NONNULL_BEGIN

@class TKPlaceDetail;
@interface TKPlace : NSObject

@property (nonatomic, copy) NSString *ID NS_SWIFT_NAME(ID);
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSString *suffix;
@property (nonatomic, copy, nullable) NSString *perex;
@property (nonatomic, strong, nullable) CLLocation *location;
@property (nonatomic, copy, nullable) NSString *quadKey;
@property (nonatomic, strong, nullable) NSNumber *tier;
@property (nonatomic, strong, nullable) NSNumber *price;
@property (nonatomic, strong, nullable) NSNumber *rating;
@property (nonatomic, strong, nullable) NSNumber *duration;
@property (nonatomic, copy, nullable) NSString *marker;
@property (nonatomic, copy, nullable) NSArray<NSString *> *categories;
@property (nonatomic, copy, nullable) NSArray<NSString *> *tags;
@property (nonatomic, copy, nullable) NSArray<NSString *> *parents;
@property (nonatomic, copy, nullable) NSArray<NSString *> *flags;

@property (nonatomic, strong, nullable) TKPlaceDetail *detail;
@property (nonatomic, strong, nullable) NSArray<TKReference *> *references;

- (instancetype)initFromResponse:(NSDictionary *)response;

@end


@interface TKPlaceDetail : NSObject

@property (nonatomic, copy, nullable) NSString *address;
@property (nonatomic, copy, nullable) NSString *phone;
@property (nonatomic, copy, nullable) NSString *email;
@property (nonatomic, strong, nullable) NSNumber *duration;
@property (nonatomic, copy, nullable) NSString *openingHours;
@property (nonatomic, copy, nullable) NSString *admission;

@end

NS_ASSUME_NONNULL_END
