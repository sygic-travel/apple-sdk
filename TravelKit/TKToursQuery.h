//
//  TKToursQuery.h
//  TravelKit
//
//  Created by Michal Zelinka on 16/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TKTour.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Query enum declaring the sorting option for the results returned.
 */
typedef NS_ENUM(NSUInteger, TKToursQuerySorting) {
	/// Get results sorted by rating. Descending by default.
	TKToursQuerySortingRating  = 0,
	/// Get results sorted by price. Ascending by default.
	TKToursQuerySortingPrice  = 1,
	/// Get results sorted by Top selling items. Descending by default.
	TKToursQuerySortingTopSellers = 2,
};


/**
 Query object used for fetching specific collections of `TKTour` objects.
 
 To perform regional queries, use either `quadKeys` (preferred) or `bounds` property to specify the area of your interest.
 */
@interface TKToursQuery : NSObject <NSCopying, NSMutableCopying>

/// Desired identifier of parent node. _Example: `city:1`_
///
/// @note Requred attribute.
@property (nonatomic, copy, nullable) NSString *parentID;

/// Desired sorting type of Tours returned.
///
/// @see `TKToursQuerySorting`
@property (nonatomic) TKToursQuerySorting sortingType;

/// Declaration of descending sorting order.
///
/// @note _Descending_ order is not supported for `TKToursQuerySortingTopSellers` sorting type.
@property (atomic) BOOL descendingSortingOrder;

/// Requested page number with results.
///
/// @note Accepted values: `1`--`X`. Implicit value is `1`.
@property (nonatomic, strong, nullable) NSNumber *pageNumber;

@end

NS_ASSUME_NONNULL_END
