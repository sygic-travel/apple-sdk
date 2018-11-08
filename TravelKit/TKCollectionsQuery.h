//
//  TKCollectionsQuery.h
//  TravelKit
//
//  Created by Michal Zelinka on 30/10/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Query enum declaring in which manner the related parameter should be treated.
 */
typedef NS_ENUM(NSUInteger, TKCollectionsQueryMatching) {
	/// Matching rule stating **ANY** of the queried criteria needs to be met.
	TKCollectionsQueryMatchingAny  = 0,
	/// Matching rule stating **ALL** of the queried criteria need to be met.
	TKCollectionsQueryMatchingAll  = 1,
};

/**
 A query object used for fetching specific collections of `TKCollection` objects.
 */
@interface TKCollectionsQuery : NSObject

/// Place ID to limit collections in.
@property (nonatomic, copy, nullable) NSString *parentPlaceID;

/// An array of Place IDs indicating a lookup for collections containing the specified Places.
@property (nonatomic, copy, nullable) NSArray<NSString *> *placeIDs;

/// Flag controlling the matching rule for `parentIDs`.
@property (atomic) TKCollectionsQueryMatching placeIDsMatching;

/// Tags to look for. All entries are being matched.
@property (nonatomic, copy, nullable) NSArray<NSString *> *tags;

/// Tags not to look for. All entries are being matched.
@property (nonatomic, copy, nullable) NSArray<NSString *> *tagsToOmit;

/// Search term to use. Usable for searching through English and localised names.
@property (nonatomic, copy, nullable) NSString *searchTerm;

/// Maximum number of results returned.
///
/// @note The default value is `10`. Accepted values: `1`--`30`.
@property (nonatomic, strong, nullable) NSNumber *limit;

/// Paging offset.
///
/// @note The implicit value is `0` to return the results starting with the first one.
@property (nonatomic, strong, nullable) NSNumber *offset;

/// Collections with unique places have increased rating.
///
/// @note This parameter is used only if `parentPlaceID` is set.
@property (atomic) BOOL preferUnique;

@end

NS_ASSUME_NONNULL_END
