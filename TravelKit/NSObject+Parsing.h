//
//  NSObject+Parsing.h
//  Tripomatic
//
//  Created by Michal Zelinka on 03/09/15.
//  Copyright (c) 2015 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Handles additional properties and methods for quick parsing needs.

 This category introduces some generally used overrides, namely `-objectAtIndex:`, `-objectForKeyedSubscript:` and `-objectForKey:`. Using these methods eases parsing by omitting some extra checks, f.e.:
 
     NSNumber *duration = [place[@"duration"] parsedNumber];

 may be used to easily parse an `NSNumber` object from `NSArray` if all conditions are met and returns `nil` in any conflicting situation.

 **Note:** This overriding affects your app as usually sending these messages to `NSObject` or other classes inheriting from them would lead to a crash which may be a correct behaviour for debugging purposes.
 */

@interface NSObject (Parsing)

///---------------------------------------------------------------------------------------
/// @name Fast access properties
///---------------------------------------------------------------------------------------

/// Returns `self` if of an `NSArray` type, otherwise `nil`.
@property (nonatomic, readonly, nullable) NSArray *parsedArray;

/// Returns `self` if of an `NSDictionary` type, otherwise `nil`.
@property (nonatomic, readonly, nullable) NSDictionary *parsedDictionary;

/// Returns `self` if of an non-empty `NSString` type, otherwise `nil`.
@property (nonatomic, readonly, nullable) NSString *parsedString;

/// Returns `self` if of an `NSNumber` instance, otherwise `nil`.
@property (nonatomic, readonly, nullable) NSNumber *parsedNumber;

///---------------------------------------------------------------------------------------
/// @name Enumeration/collection methods
///---------------------------------------------------------------------------------------

/**
 Method for quick obtaining of array members.

 @param index Index in an array.
 @return Object at index `index` of the array or nil.
 */
- (nullable id)objectAtIndex:(NSUInteger)index;

/**
 Method for quick obtaining of dictionary members.

 @param key Key in the dictionary.
 @return Object for the key `key` of the dictionary or nil.
 */
- (nullable id)objectForKeyedSubscript:(nonnull id)key;

/**
 Method for quick obtaining of dictionary members.

 @param key Key in the dictionary.
 @return Object for the key `key` of the dictionary or nil.
 */
- (nullable id)objectForKey:(nonnull id)key;

@end

NS_ASSUME_NONNULL_END
