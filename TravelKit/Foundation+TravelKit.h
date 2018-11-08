//
//  Foundation+TravelKit.h
//  TravelKit
//
//  Created by Michal Zelinka on 20/03/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef USE_TRAVELKIT_FOUNDATION

NS_ASSUME_NONNULL_BEGIN

// -----------------------------------------------------------------------
/// @name Generic `NSObject` stuff
// -----------------------------------------------------------------------

@interface NSObject (TravelKit)

/**
 Quick swizzling method for use within a class.

 @param swizzled Selector referencing a new implementation.
 @param original Selector referencing the original implementation.
 */
- (void)swizzleSelector:(SEL)swizzled withSelector:(SEL)original;

/**
 Generic swizzling method for use across classes.

 @param swizzled Selector referencing a new implementation.
 @param swizzledClass Class providing the `swizzled` selector.
 @param original Selector referencing the original implementation.
 @param originalClass Class providing the `original` selector.
 */
+ (void)swizzleSelector:(SEL)swizzled ofClass:(Class)swizzledClass
           withSelector:(SEL)original ofClass:(Class)originalClass;

@end

// -----------------------------------------------------------------------
/// @name `NSArray` stuff
// -----------------------------------------------------------------------

@interface NSArray<ObjectType> (TravelKit)

/**
 Index-picking from the array, a bit safer.

 @param index Index of the requested object.
 @return Desired object.
 */
- (nullable ObjectType)safeObjectAtIndex:(NSUInteger)index;

/**
 Array-mapping method for complex transformations.

 @param block Block used for customisable mapping.
 @return Mapped array.
 
 @note Any objects returned via block are included in the array returned. No type-checking is performed.
       Returning `nil` within the block works as filtering.
 */
- (NSArray *)mappedArrayUsingBlock:(id _Nullable (^)(ObjectType obj))block;

/**
 Array method for quick filtering purposes.

 @param block Block used to determine `obj` inclusion in the array returned.
 @return Filtered array.
 */
- (NSArray<ObjectType> *)filteredArrayUsingBlock:(BOOL (^)(ObjectType obj))block;

@end

// -----------------------------------------------------------------------
/// @name `NSDictionary` stuff
// -----------------------------------------------------------------------

@interface NSDictionary<KeyType, ObjectType> (TravelKit)

/**
 Simple method used to convert the dictionary to JSON string.

 @return Resulting JSON string.
 */
- (nullable NSString *)asJSONString;

/**
 Simple method used to convert the dictionary to JSON data.

 @return Resulting JSON data.
 */
- (nullable NSData *)asJSONData;

@end

// -----------------------------------------------------------------------
/// @name `NSString` stuff
// -----------------------------------------------------------------------

@interface NSString (TravelKit)

/**
 Pretty basic string trimming method.

 @return Trimmed string.
 */
- (NSString *)trimmedString;

/**
 Trimming function removing all the characters specified in the regular expression.

 @param regexString Regular expression used for trimming.
 @return Trimmed string.
 */
- (NSString *)stringByTrimmingCharactersInRegexString:(NSString *)regexString;

/**
 Index-safe variant of `substringToIndex:` providing a substring even if the position exceeds the string length.

 @param to Index of a position where to trim the string from.
 @return Resulting substring.
 */
- (NSString *)substringToPosition:(NSUInteger)to;

/**
 Simple and naive function parsing a specific substring between a given starters (searched in a given
 order) and an ending.

 @param starters An array of starter strings to consecutively look for before the parsed substring.
 @param ending A string to look for after a parsed substring.
 @return The resulting substring, if found.
 */
- (nullable NSString *)substringBetweenStarters:(NSArray<NSString *> *)starters andEnding:(NSString *)ending;

/**
 A method returing a string without any occurrence of a given substring.

 @param str Substring to cut from the string.
 @return Resulting string.
 */
- (NSString *)stringByDeletingOccurrencesOfString:(NSString *)str;

@end

// -----------------------------------------------------------------------
/// @name Mutability `NSString` stuff
// -----------------------------------------------------------------------

@interface NSString (TravelKitFoundationMutabilityType)

/// Immutable copy of the string.
- (NSString *)copy;
/// Mutable copy of the string.
- (NSMutableString *)mutableCopy;

@end

// -----------------------------------------------------------------------
/// @name Mutability `NSArray` stuff
// -----------------------------------------------------------------------

@interface NSArray<ObjectType> (TravelKitFoundationMutabilityType)

/// Immutable copy of the array.
- (NSArray<ObjectType> *)copy;
/// Mutable copy of the array.
- (NSMutableArray<ObjectType> *)mutableCopy;

@end

// -----------------------------------------------------------------------
/// @name Mutability `NSSet` stuff
// -----------------------------------------------------------------------

@interface NSSet<ObjectType> (TravelKitFoundationMutabilityType)

/// Immutable copy of the set.
- (NSSet<ObjectType> *)copy;
/// Mutable copy of the set.
- (NSMutableSet<ObjectType> *)mutableCopy;

@end

// -----------------------------------------------------------------------
/// @name Mutability `NSDictionary` stuff
// -----------------------------------------------------------------------

@interface NSDictionary<KeyType, ObjectType> (TravelKitFoundationMutabilityType)

/// Immutable copy of the dictionary.
- (NSDictionary<KeyType, ObjectType> *)copy;
/// Mutable copy of the dictionary.
- (NSMutableDictionary<KeyType, ObjectType> *)mutableCopy;

@end

NS_ASSUME_NONNULL_END

#endif // USE_TRAVELKIT_FOUNDATION
