//
//  NSObject+Parsing.h
//  TravelKit
//
//  Created by Michal Zelinka on 03/09/15.
//  Copyright (c) 2015 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef USE_NSOBJECT_PARSING

NS_ASSUME_NONNULL_BEGIN

/** Handles additional properties and methods for quick parsing needs.

 This category introduces some generally used overrides, namely:
 
 - `-objectAtIndexedSubscript:`
 - `-objectForKeyedSubscript:`

 Using these methods eases parsing by omitting some extra checks.
 
 Consider having a following JSON input:
 
```json
{
    "id" : "poi:530",
    "name" : "Eiffel Tower",
    "location" : {
        "latitude" : 48.858262,
        "longitude" : 2.2944955
    },
    "perex" : "Once the world's tallest man-made structure",
    "level" : "poi"
}
```
 
 By converting it to an object using native `NSJSONSerialization` procedure, it's very easy to read object's properties using the provided nethods:

```objc
// Parse strings only if they are strings in JSON, otherwise `nil`
NSString *ID = [place[@"id"] parsedString];
NSString *name = [place[@"name"] parsedString];
NSString *perex = [place[@"perex"] parsedString];

CLLocation *location = nil;

// Parse coordinates only if placed within `location` object as number properties
NSNumber *latitude = [place[@"location"][@"latitude"] parsedNumber];
NSNumber *longitude = [place[@"location"][@"latitude"] parsedNumber];

// Easy `nil`-checking due to parsing to objects
if (latitude && longitude)
    location = [[CLLocation alloc] initWithLatitude:latitude.doubleValue longitude:longitude.doubleValue];

// If all required properties are non-`nil`, celebrate!
if (ID && name && location)
    NSLog(@"Valid TKPlace may be initialised, woohoo!");
```

 Parsing nested values and futher processing of the obtained values becomes very straight-forward.

 @warning Overriding of `NSObject` affects your app flow as usually sending these messages to `NSObject` or other classes inheriting from them would lead to a crash -- that may be a correct behaviour for debugging purposes. This override will cause both of these examples to return `nil` instead of crashing.

````objc
NSNumber *number = @1;

// This code would usually crash due to an unrecognised selector sent
//   to the `number` object as `NSNumber` doesn't implement key subscripting.
[number[@"props"] parsedArray]; // returns `nil`

// Same case, `NSNumber` doesn't implement index subscripting.
[number[0] parsedNumber]; // returns `nil`
````

 @note These methods only affect _Objective-C_ runtime and _NSObject_-based classes. _Swift_ runtime works with a different base structure. To parse _Swift_ objects containing _JSON_ data using the same manner try using [`SwiftyJSON`](https://github.com/SwiftyJSON/SwiftyJSON) framework.
 */

@interface NSObject (Parsing)

///---------------------------------------------------------------------------------------
/// @name Fast access properties
///---------------------------------------------------------------------------------------

/// Returns `self` if of an `NSArray` kind, otherwise `nil`.
@property (nonatomic, readonly, nullable) __kindof NSArray *parsedArray;

/// Returns `self` if of an `NSDictionary` kind, otherwise `nil`.
@property (nonatomic, readonly, nullable) __kindof NSDictionary *parsedDictionary;

/// Returns `self` if of an non-empty `NSString` kind, otherwise `nil`.
@property (nonatomic, readonly, nullable) __kindof NSString *parsedString;

/// Returns `self` if of an `NSNumber` kind, otherwise `nil`.
@property (nonatomic, readonly, nullable) __kindof NSNumber *parsedNumber;

///---------------------------------------------------------------------------------------
/// @name Enumeration/collection methods
///---------------------------------------------------------------------------------------

/**
 Method for quick obtaining of array members.

 @param index Index in an array.
 @return Object at index `index` of the array or nil.
 */
- (nullable __kindof NSObject *)objectAtIndexedSubscript:(NSUInteger)index;

/**
 Method for quick obtaining of dictionary members.

 @param key Key in the dictionary.
 @return Object for the key `key` of the dictionary or nil.
 */
- (nullable __kindof NSObject *)objectForKeyedSubscript:(nonnull id)key;

@end

NS_ASSUME_NONNULL_END

#endif // USE_NSOBJECT_PARSING
