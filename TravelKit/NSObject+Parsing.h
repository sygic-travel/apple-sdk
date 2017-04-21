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

NS_ASSUME_NONNULL_END
