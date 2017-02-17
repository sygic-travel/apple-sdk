//
//  NSObject+Parsing.m
//  Tripomatic
//
//  Created by Michal Zelinka on 03/09/15.
//  Copyright (c) 2015 Tripomatic. All rights reserved.
//

#import "NSObject+Parsing.h"


@implementation NSObject (Parsing)

- (id)parsedArray
{
	return ([self isKindOfClass:[NSArray class]]) ? self : nil;
}

- (id)parsedDictionary
{
	return ([self isKindOfClass:[NSDictionary class]]) ? self : nil;
}

- (id)parsedString
{
	return ([self isKindOfClass:[NSString class]] &&
	        [(NSString *)self length]) ? self : nil;
}

- (id)parsedNumber
{
	return ([self isKindOfClass:[NSNumber class]]) ? self : nil;
}

- (id)objectAtIndex:(NSUInteger)index
{
	return nil;
}

- (id)objectForKeyedSubscript:(id)key
{
	return nil;
}

- (id)objectForKey:(id)key
{
	return nil;
}

@end
