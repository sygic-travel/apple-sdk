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

- (NSArray *)mappedArrayUsingBlock:(id _Nullable (^)(id _Nonnull))block
{
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:self.count];

	[self enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger __unused idx,
	  BOOL * _Nonnull __unused stop) {
		id remapped = block(obj);
		if (remapped) [results addObject:remapped];
	}];

	return results;
}

- (NSArray *)filteredArrayUsingBlock:(BOOL (^)(id _Nonnull))block
{
	NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:self.count];

	[self enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger __unused idx,
	  BOOL * _Nonnull __unused stop) {
		BOOL include = block(obj);
		if (include) [filtered addObject:obj];
	}];

	return filtered;
}

@end


@implementation NSDictionary (TravelKit)

- (NSDictionary *)filteredDictionaryUsingBlock:(BOOL (^)(id _Nonnull, id _Nonnull))block
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:self.count];

	[self enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj,
	  BOOL * _Nonnull __unused stop) {
		if (block(key, obj))
			dict[key] = obj;
	}];

	return dict;
}

- (NSString *)asJSONString
{
	NSData *jsonData = [self asJSONData];
	return (jsonData) ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : nil;
}

- (NSData *)asJSONData
{
	NSError *err = nil;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:kNilOptions error:&err];
	return (!err) ? jsonData : nil;
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

- (NSString *)substringToPosition:(NSUInteger)to
{
	NSUInteger max = MIN(to, self.length);
	return [self substringToIndex:max];
}

- (NSString *)substringBetweenStarters:(NSArray<NSString *> *)starters andEnding:(NSString *)ending
{
	NSRange range = NSMakeRange(0, [self length]-1);

	for (NSString *starter in starters) {
		NSRange tmp = [self rangeOfString:starter options:0 range:range];
		if (tmp.location == NSNotFound)
			return nil;
		range.length = range.length - (tmp.location - range.location) - [starter length];
		range.location = tmp.location + [starter length];
	}

	NSRange tmp = [self rangeOfString:ending options:0 range:range];
	if (tmp.location == NSNotFound)
		return nil;
	range.length = tmp.location - range.location;

	return [self substringWithRange:range];
}

- (NSString *)stringByDeletingOccurrencesOfString:(NSString *)str
{
	return [self stringByReplacingOccurrencesOfString:str withString:@""];
}

@end


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation NSString (TravelKitFoundationMutabilityType) @end

@implementation NSArray (TravelKitFoundationMutabilityType) @end

@implementation NSSet (TravelKitFoundationMutabilityType) @end

@implementation NSDictionary (TravelKitFoundationMutabilityType) @end

#pragma clang diagnostic pop
