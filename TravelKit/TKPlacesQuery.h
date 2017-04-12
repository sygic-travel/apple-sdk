//
//  TKPlacesQuery.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TKPlace.h"
#import "TKMapRegion.h"

NS_ASSUME_NONNULL_BEGIN

@interface TKPlacesQuery : NSObject

@property (nonatomic, copy, nullable) NSString *searchTerm;
@property (nonatomic, copy, nullable) NSArray<NSString *> *quadKeys; // not fully working yet, only first one is queried
@property (nonatomic, strong, nullable) TKMapRegion *bounds;
@property (nonatomic, copy, nullable) NSArray<NSString *> *categories;
@property (nonatomic, copy, nullable) NSArray<NSString *> *tags;
@property (nonatomic, copy, nullable) NSString *parentID;
@property (atomic) TKPlaceLevel level;
@property (atomic) NSUInteger limit;

@end

NS_ASSUME_NONNULL_END
