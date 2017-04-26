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

/**
 Query object used for fetching specific collections of `TKPlace` objects.
 
 To perform regional queries, use either `-quadKeys` (preferred) or `-bounds` property to specify the area of your interest.
 */
@interface TKPlacesQuery : NSObject

/// Search term to use. Mainly usable for searching through English and localised names.
@property (nonatomic, copy, nullable) NSString *searchTerm;

/// Listed map quad keys to query.
/// ====
/// @warning Not fully working yet, only the first one is queried.
@property (nonatomic, copy, nullable) NSArray<NSString *> *quadKeys;

/// Desired area of the map.
@property (nonatomic, strong, nullable) TKMapRegion *bounds;

/// Array of the desired Category slugs.
@property (nonatomic, copy, nullable) NSArray<NSString *> *categories;

/// Plain-text array of the desired Tags.
@property (nonatomic, copy, nullable) NSArray<NSString *> *tags;

/// Idenfitier of the parent node of returned `TKPlace` objects.
@property (nonatomic, copy, nullable) NSString *parentID;

/// *Accepted values:* `1-3`.
/// ====
/// @warning `-limit` must be divisibile by 4^mapSpread.
@property (nonatomic, strong, nullable) NSNumber *mapSpread;

/// Desired levels of `TKPlace` objects.
/// ====
/// @see TKPlaceLevel
@property (atomic) TKPlaceLevel level;

/// Maximum number of results returned. If multiple quad keys specified, the limit applies to each one of them separately.
@property (atomic) NSUInteger limit;

@end

NS_ASSUME_NONNULL_END
