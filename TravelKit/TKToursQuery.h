//
//  TKToursQuery.h
//  TravelKit
//
//  Created by Michal Zelinka on 16/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <TravelKit/TKTour.h>
#import <TravelKit/TKMapRegion.h>

NS_ASSUME_NONNULL_BEGIN


#pragma mark - Definitions


/**
 Query enum declaring the sorting option for the Viator tour results returned.
 */
typedef NS_ENUM(NSUInteger, TKToursViatorQuerySorting) {
	/// Get results sorted by rating. Descending by default.
	TKToursViatorQuerySortingRating      = 0,
	/// Get results sorted by price. Ascending by default.
	TKToursViatorQuerySortingPrice       = 1,
	/// Get results sorted by Top selling items. Descending by default.
	TKToursViatorQuerySortingTopSellers  = 2,
};

/**
 Query enum declaring the sorting option for the GetYourGuide tour results returned.
 */
typedef NS_ENUM(NSUInteger, TKToursGYGQuerySorting) {
	/// Get results sorted by Top selling items. Descending by default.
	TKToursGYGQuerySortingPopularity  = 0,
	/// Get results sorted by rating. Descending by default.
	TKToursGYGQuerySortingRating      = 1,
	/// Get results sorted by price. Ascending by default.
	TKToursGYGQuerySortingPrice       = 2,
	/// Get results sorted by duration. Ascending by default.
	TKToursGYGQuerySortingDuration    = 3,
};


#pragma mark - Viator query


/**
 Query object used for fetching specific collections of `TKTour` objects from Viator.
 */
@interface TKToursViatorQuery : NSObject <NSCopying, NSMutableCopying>

/// Desired identifier of parent node. _Example: `city:1`_
///
/// @note Requred attribute.
@property (nonatomic, copy, nullable) NSString *parentID;

/// Desired sorting type of Tours returned.
///
/// @note Changing this property may change current `descendingSortingOrder` setting.
///
/// @see `TKToursViatorQuerySorting`
@property (nonatomic) TKToursViatorQuerySorting sortingType;

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
@interface TKToursGYGQuery : NSObject <NSCopying, NSMutableCopying>

/// Desired identifier of parent node.
/// It represents the area where tour takes place in.
///
/// @note Required attribute. _Example: `city:1`_.
///
/// @note You can find IDs of countries in [Google Sheets](https://docs.google.com/spreadsheets/d/1qlTdvBlLDo3fxBTSqmbqQOQJXsynfukBHxI_Xpi2Srw/edit#gid=0)
/// or [CSV file](https://admin.sygictraveldata.com/data-export/ijcw4rz32quouj3zwu1k70uhcgqfyp8g), you can also find IDs of top cities in [Google Sheets]
/// (https://docs.google.com/spreadsheets/d/1qlTdvBlLDo3fxBTSqmbqQOQJXsynfukBHxI_Xpi2Srw/edit#gid=1588428987) and
/// [CSV file](https://admin.sygictraveldata.com/data-export/zf8979vspcvz61dya3pyxbvsduyjtnh4) as well.
@property (nonatomic, copy, nullable) NSString *parentID;

/// Desired sorting type of Tours returned.
///
/// @note Changing this property may change current `descendingSortingOrder` setting.
///
/// @see `TKToursGYGQuerySorting`
@property (nonatomic) TKToursGYGQuerySorting sortingType;

/// Declaration of descending sorting order.
///
/// @note _Descending_ order is not supported for `TKToursQuerySortingTopSellers` sorting type.
@property (atomic) BOOL descendingSortingOrder;

/// A start date used to look for the tours.
@property (nonatomic, strong, nullable) NSDate *startDate;

/// An end date used to look for the tours.
@property (nonatomic, strong, nullable) NSDate *endDate;

/// Duration range in seconds.
///
/// @note Example value: `3600`.
@property (nonatomic, strong, nullable) NSNumber *minimalDuration;

/// Duration range in seconds.
///
/// @note Example value: `86400`.
@property (nonatomic, strong, nullable) NSNumber *maximalDuration;

/// A search term used to look for the tours.
@property (nonatomic, strong, nullable) NSString *searchTerm;

/// Limit results to an area defined by the given bounds.
@property (nonatomic, strong, nullable) TKMapRegion *bounds;

/// Requested number of results on a single page.
@property (nonatomic, strong, nullable) NSNumber *count;

/// Requested page number with results.
///
/// @note Accepted values: `1`--`X`. Implicit value is `1`.
@property (nonatomic, strong, nullable) NSNumber *pageNumber;

@end

NS_ASSUME_NONNULL_END
