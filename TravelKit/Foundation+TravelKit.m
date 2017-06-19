//
//  Foundation+TravelKit.m
//  TravelKit
//
//  Created by Michal Zelinka on 20/03/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <objc/runtime.h>
#import "Foundation+TravelKit.h"


@implementation NSObject (TravelKit)

- (void)swizzleSelector:(SEL)swizzled withSelector:(SEL)original
{
	Class class = [self class];

	Method origMethod = class_getInstanceMethod(class, original);
	Method overrideMethod = class_getInstanceMethod(class, swizzled);

	if (class_addMethod(class, original,
		method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod)))
	{
		class_replaceMethod(class, swizzled,
			method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
	}
}

+ (void)swizzleSelector:(SEL)swizzledSelector ofClass:(Class)swizzledClass
           withSelector:(SEL)originalSelector ofClass:(Class)originalClass
{
	Method oldMethod = class_getInstanceMethod(originalClass, originalSelector);
	Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);

	class_addMethod(originalClass, swizzledSelector,
					method_getImplementation(swizzledMethod),
					method_getTypeEncoding(swizzledMethod));

	swizzledMethod = class_getInstanceMethod(originalClass, swizzledSelector);
	method_exchangeImplementations(oldMethod, swizzledMethod);
}

@end


@implementation NSArray (TravelKit)

- (id)safeObjectAtIndex:(NSUInteger)index
{
	if (self.count > index)
		return self[index];
	return nil;
}

- (NSArray *)mappedArrayUsingBlock:(id _Nullable (^)(id obj, NSUInteger idx))block
{
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:self.count];

	[self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx,
	  BOOL * _Nonnull __unused stop) {
		id remapped = block(obj, idx);
		if (remapped) [results addObject:remapped];
	}];

	return results;
}

- (NSArray *)filteredArrayUsingBlock:(BOOL (^)(id obj, NSUInteger idx))block
{
	NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:self.count];

	[self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx,
	  BOOL * _Nonnull __unused stop) {
		BOOL include = block(obj, idx);
		if (include) [filtered addObject:obj];
	}];

	return filtered;
}

@end


@implementation NSString (TravelKit)

- (NSString *)trimmedString
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)stringByTrimmingCharactersInRegexString:(NSString *)regexString
{
	NSRegularExpression *regex = [NSRegularExpression
		regularExpressionWithPattern:regexString options:(NSRegularExpressionOptions)0 error:nil];

	return [regex stringByReplacingMatchesInString:self
		options:(NSMatchingOptions)0 range:NSMakeRange(0, self.length) withTemplate:@""];
}

@end


@implementation NSDateFormatter (TravelKit)

+ (NSDateFormatter *)shared8601DateTimeFormatter
{
	static NSDateFormatter *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[NSDateFormatter alloc] init];
		shared.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		shared.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
	});
	return shared;
}

@end
