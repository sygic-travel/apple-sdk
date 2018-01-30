//
//  TKTour.h
//  TravelKit
//
//  Created by Michal Zelinka on 16/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/**
 Basic Tour model keeping various information about its properties.
 */

@interface TKTour : NSObject

///---------------------------------------------------------------------------------------
/// @name Properties
///---------------------------------------------------------------------------------------

/// Global identifier.
@property (nonatomic, copy) NSString *ID NS_SWIFT_NAME(ID);

/// Displayable name of the tour, translated if possible. Example: _Buckingham Palace_.
@property (nonatomic, copy) NSString *title;

/// Short perex introducing the tour.
@property (nonatomic, copy, nullable) NSString *perex;

/// Price value. Provided in `USD`.
@property (nonatomic, strong, nullable) NSNumber *price;

/// Original price value. Usable for discount calculation. Value in `USD`.
@property (nonatomic, strong, nullable) NSNumber *originalPrice;

/// Star rating value.
///
/// @note Possible values: double in range `0`--`5`.
@property (nonatomic, strong, nullable) NSNumber *rating;

/// Duration string. Should be provided in a target language.
///
/// @note Duration may be specified by either a string or numeric values.
@property (nonatomic, copy, nullable) NSString *duration;

/// Minimal duration in seconds.
///
/// @note Duration may be specified by either a string or numeric values.
@property (nonatomic, copy, nullable) NSNumber *durationMin;

/// Maximal duration in seconds.
///
/// @note Duration may be specified by either a string or numeric values.
@property (nonatomic, copy, nullable) NSNumber *durationMax;

/// Online URL of the Tour.
@property (nonatomic, strong, nullable) NSURL *URL;

/// Thumbnail URL to an image of approximate size 600x400 pixels.
@property (nonatomic, strong, nullable) NSURL *photoURL;

/// Count of reviews.
@property (nonatomic, strong, nullable) NSNumber *reviewsCount;

@end

NS_ASSUME_NONNULL_END
