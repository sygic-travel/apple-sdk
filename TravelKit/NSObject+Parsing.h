//
//  NSObject+Parsing.h
//  Tripomatic
//
//  Created by Michal Zelinka on 03/09/15.
//  Copyright (c) 2015 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Parsing)

@property (nonatomic, readonly, nullable) NSArray *parsedArray;
@property (nonatomic, readonly, nullable) NSDictionary *parsedDictionary;
@property (nonatomic, readonly, nullable) NSString *parsedString;
@property (nonatomic, readonly, nullable) NSNumber *parsedNumber;

- (nullable id)objectAtIndex:(NSUInteger)index;
- (nullable id)objectForKeyedSubscript:(nonnull id)key;
- (nullable id)objectForKey:(nonnull id)key;

@end

// Object macros
NS_INLINE _Nullable id objectOrNil(_Nullable id obj) \
	{ return ![[NSNull null] isEqual:obj] ? obj : nil; }
NS_INLINE id objectOrNull(_Nullable id obj) \
	{ return obj ?: [NSNull null]; }

// String macros
#define stringOrValue(str, value)        ([str parsedString] ?: value)
#define nonEmptyString(str)               [str parsedString]

// Number macros
#define numberOrValue(number, value)     ([number parsedNumber] ?: value)
#define numberOrNil(number)               [number parsedNumber]

// Dictionary macros
#define dictionaryOrValue(dict, value)   ([dict parsedDictionary] ?: value)
#define dictionaryOrNil(dict)             [dict parsedDictionary]

// Array macros
#define arrayOrValue(array, value)       ([array parsedArray] ?: value)
#define arrayOrNil(array)                 [array parsedArray]

NS_ASSUME_NONNULL_END
