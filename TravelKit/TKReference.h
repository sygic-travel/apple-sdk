//
//  TKReference.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Entity handling basic information about additional linked content. References are entities that
 represent places' relations to other websites, articles, social networks, rental options, passes,
 tickets, tours, accomodation providers, parkings, transfers and other services.
 For more information please see [Sygic Travel API](http://docs.sygictravelapi.com/1.1/#section-references)
 */
@interface TKReference : NSObject <NSCopying>

///---------------------------------------------------------------------------------------
/// @name Properties
///---------------------------------------------------------------------------------------

/// Reference identifier.
@property (atomic, readonly) NSUInteger ID NS_SWIFT_NAME(ID);

/// Reference title.
@property (nonatomic, copy, readonly) NSString *title;

/// Reference type.
///
/// @note For a complete list of nested reference types see [References sheet](https://docs.google.com/spreadsheets/d/1i8HQGVQ4eBvUrROGWIPMdrmUxRUAfS0tW914P16iJg4/edit?usp=sharing) .
@property (nonatomic, copy, readonly) NSString *type;

/// Reference supplier.
@property (nonatomic, copy, nullable, readonly) NSString *supplier;

/// Potential price of the Reference if applicable. Value in `USD`.
@property (nonatomic, copy, nullable, readonly) NSNumber *price;

/// Reference language. See list of available language IDs: `language`.
///
/// @note May be `nil` if generic. 
@property (nonatomic, copy, nullable, readonly) NSString *languageID;

/// Online `NSURL` of the Reference.
@property (nonatomic, copy, readonly) NSURL *onlineURL;

/// Additional flags.
@property (nonatomic, copy, nullable, readonly) NSArray<NSString *> *flags;

/// Reference priority. Higher means more important.
@property (atomic, readonly) NSInteger priority;

/// Name of a proposed icon for the Reference.
@property (nonatomic, copy, readonly) NSString *iconName;

@end

NS_ASSUME_NONNULL_END
