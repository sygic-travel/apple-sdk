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
@property (atomic) NSUInteger ID NS_SWIFT_NAME(ID);

/// Reference title.
@property (nonatomic, copy, nullable) NSString *title;

/// Reference type.
@property (nonatomic, copy, nullable) NSString *type;

/// Reference supplier.
@property (nonatomic, copy, nullable) NSString *supplier;

/// Potential price of the Reference if applicable.
@property (nonatomic, copy, nullable) NSNumber *price;

/// Reference language.
///
/// @note May be `nil` if generic. 
@property (nonatomic, copy, nullable) NSString *languageID;

/// Online `NSURL` of the Reference.
@property (nonatomic, copy, nullable) NSURL *onlineURL;

/// Additional flags.
@property (nonatomic, copy, nullable) NSArray<NSString *> *flags;

/// Reference priority. Higher means more important.
@property (atomic) NSInteger priority;

/// Name of a proposed icon for the Reference.
@property (nonatomic, copy, readonly) NSString *iconName;

@end

NS_ASSUME_NONNULL_END
