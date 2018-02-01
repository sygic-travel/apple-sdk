//
//  TKToursQuery.h
//  TravelKit
//
//  Created by Michal Zelinka on 16/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <TravelKit/TKTour.h>

NS_ASSUME_NONNULL_BEGIN


#pragma mark - Definitions


/**
 Query enum declaring the sorting option for the Viator tour results returned.
 */
typedef NS_ENUM(NSUInteger, TKViatorToursQuerySorting) {
	/// Get results sorted by rating. Descending by default.
	TKViatorToursQuerySortingRating      = 0,
	/// Get results sorted by price. Ascending by default.
	TKViatorToursQuerySortingPrice       = 1,
	/// Get results sorted by Top selling items. Descending by default.
	TKViatorToursQuerySortingTopSellers  = 2,
};

/**
 Query enum declaring the sorting option for the GetYourGuide tour results returned.
 */
typedef NS_ENUM(NSUInteger, TKGYGToursQuerySorting) {
	/// Get results sorted by rating. Descending by default.
	TKGYGToursQuerySortingRating      = 0,
	/// Get results sorted by price. Ascending by default.
	TKGYGToursQuerySortingPrice       = 1,
	/// Get results sorted by Top selling items. Descending by default.
	TKGYGToursQuerySortingPopularity  = 2,
	/// Get results sorted by duration. Ascending by default.
	TKGYGToursQuerySortingDuration    = 3,
};


#pragma mark - Viator query


/**
 Query object used for fetching specific collections of `TKTour` objects from Viator.
 */
@interface TKViatorToursQuery : NSObject <NSCopying, NSMutableCopying>

/// Desired identifier of parent node. _Example: `city:1`_
///
/// @note Requred attribute.
@property (nonatomic, copy, nullable) NSString *parentID;

/// Desired sorting type of Tours returned.
///
/// @note Changing this property may change current `descendingSortingOrder` setting.
///
/// @see `TKToursQuerySorting`
@property (nonatomic) TKViatorToursQuerySorting sortingType;

/// Declaration of descending sorting order.
///
/// @note _Descending_ order is not supported for `TKToursQuerySortingTopSellers` sorting type.
@property (atomic) BOOL descendingSortingOrder;

/// Requested page number with results.
///
/// @note Accepted values: `1`--`X`. Implicit value is `1`.
@property (nonatomic, strong, nullable) NSNumber *pageNumber;

@end


#pragma mark - GetYourGuide query


/**
 Query object used for fetching specific collections of `TKTour` objects from GetYourGuide.
 */
@interface TKGYGToursQuery : NSObject <NSCopying, NSMutableCopying>

/// Desired identifier of parent node. _Example: `city:1`_
///
/// @note Requred attribute.
@property (nonatomic, copy, nullable) NSString *parentID;

/// Desired sorting type of Tours returned.
///
/// @note Changing this property may change current `descendingSortingOrder` setting.
///
/// @see `TKToursQuerySorting`
@property (nonatomic) TKGYGToursQuerySorting sortingType;

/// Declaration of descending sorting order.
///
/// @note _Descending_ order is not supported for `TKToursQuerySortingTopSellers` sorting type.
@property (atomic) BOOL descendingSortingOrder;

/// Requested page number with results.
///
/// @note Accepted values: `1`--`X`. Implicit value is `1`.
@property (nonatomic, strong, nullable) NSNumber *pageNumber;



/// Requested number of results on a single page.
@property (nonatomic, strong, nullable) NSString *searchTerm;
@property (nonatomic, strong, nullable) NSNumber *count;
@property (nonatomic, strong, nullable) NSDate *startDate;
@property (nonatomic, strong, nullable) NSDate *endDate;
/// Duration range in seconds. Note: :7200 == 0:7200 and 3600: == 3600:43200.
@property (nonatomic, strong, nullable) NSNumber *minimalDuration;
@property (nonatomic, strong, nullable) NSNumber *maximalDuration;

//bounds	optional	string	"41.78,12.34,41.99,12.64"
//Limit results to area defined by bounds. Bounds are defined by string composed of four floats in format {south},{west},{north},{east}. The units are in degrees of latitude/longitude. This parameter is exclusive with parent_place_id"

@end

NS_ASSUME_NONNULL_END
