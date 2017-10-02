//
//  Foundation+TravelKit.h
//  TravelKit
//
//  Created by Michal Zelinka on 20/03/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef USE_FOUNDATION_TRAVELKIT

NS_ASSUME_NONNULL_BEGIN

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
+ (void)swizzleSelector:(SEL)swizzled ofClass:(Class)swizzledClass withSelector:(SEL)original ofClass:(Class)originalClass;

@end


@interface NSArray<ObjectType> (TravelKit)

/**
 Index picking from the array, a bit safer.

 @param index Index of the requested object.
 @return Desired object.
 */
- (nullable ObjectType)safeObjectAtIndex:(NSUInteger)index;

/**
 Array mapping method for complex transformations.

 @param block Block used for customisable mapping.
 @return Mapped array.
 
 @note Any objects returned via block are included in the array returned. No type-checking is performed.
       Returning `nil` within the block works as filtering.
 */
- (NSArray *)mappedArrayUsingBlock:(id _Nullable (^)(ObjectType obj, NSUInteger idx))block;

/**
 Array method for quick filtering purposes.

 @param block Block used to determine `obj` inclusion in the array returned.
 @return Filtered array.
 */
- (NSArray<ObjectType> *)filteredArrayUsingBlock:(BOOL (^)(ObjectType obj, NSUInteger idx))block;

@end


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

@end


@interface NSDateFormatter (TravelKit)

/**
 Shared _ISO 8601_ Datetime formatter for generic use.

 @return Shared `NSDateFormatter` processing _ISO 8601_ formatted strings.
 */
+ (NSDateFormatter *)shared8601DateTimeFormatter;

@end

NS_ASSUME_NONNULL_END

#endif // USE_FOUNDATION_TRAVELKIT
