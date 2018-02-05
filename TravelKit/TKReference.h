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
 Entity handling basic information about additional linked content.
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
@property (nonatomic, copy, readonly) NSString *type;

/// Reference supplier.
@property (nonatomic, copy, nullable, readonly) NSString *supplier;

/// Potential price of the Reference if applicable. Value in `USD`.
@property (nonatomic, copy, nullable, readonly) NSNumber *price;

/// Reference language.
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
