//
//  NSObject+Parsing.m
//  TravelKit
//
//  Created by Michal Zelinka on 03/09/15.
//  Copyright (c) 2015 Tripomatic. All rights reserved.
//

#import "NSObject+Parsing.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSObject (Parsing)

#pragma mark - Parsing procedures

- (nullable __kindof NSArray *)parsedArray
{
	return ([self isKindOfClass:[NSArray class]]) ? (id)self : nil;
}

- (nullable __kindof NSDictionary *)parsedDictionary
{
	return ([self isKindOfClass:[NSDictionary class]]) ? (id)self : nil;
}

- (nullable __kindof NSString *)parsedString
{
	return ([self isKindOfClass:[NSString class]] &&
	        [(NSString *)self length]) ? (id)self : nil;
}

- (nullable __kindof NSNumber *)parsedNumber
{
	return ([self isKindOfClass:[NSNumber class]]) ? (id)self : nil;
}

#pragma mark - Parsing procedures

- (nullable __kindof NSObject *)objectAtIndexedSubscript:(__unused NSUInteger)index
{
	return nil;
}

- (nullable __kindof NSObject *)objectForKeyedSubscript:(__unused id)key
{
	return nil;
}

@end

NS_ASSUME_NONNULL_END
