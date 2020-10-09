//
//  NSDate+Tripomatic.m
//  Tripomatic
//
//  Created by Michal Zelinka on 20/03/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//
//  Implementation sources:
//  https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/DataFormatting/Articles/dfDateFormatting10_4.html
//  http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
//

#import <TravelKit/NSDate+Tripomatic.h>


@implementation NSLocale (Tripomatic)

// POSIX locale is used on formatters which generate output date strings to be used
// for serialization, communication with API etc. It eliminates random locale-aware
// stuff and bugs like am/pm/12/24 hrs output based on system locale, force am/pm
// even when not specified by the formatter string etc.

+ (NSLocale *)sharedPOSIXLocale
{
	static NSLocale *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
	});
	return shared;
}

@end


static NSCalendar *__NSCalendar__sharedCalendar = nil;
@implementation NSCalendar (Tripomatic)

+ (NSCalendar *)sharedCalendar
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[self updateSharedCalendar];
		[[NSNotificationCenter defaultCenter] addObserver:self
		    selector:@selector(updateSharedCalendar)
		    name:NSSystemTimeZoneDidChangeNotification object:nil];
//		[[NSNotificationCenter defaultCenter] addObserver:self
//		    selector:@selector(updateSharedCalendar)
//		    name:UIApplicationSignificantTimeChangeNotification object:nil];
	});
	return __NSCalendar__sharedCalendar;
}

+ (void)updateSharedCalendar
{
	__NSCalendar__sharedCalendar = [NSCalendar currentCalendar];
}

@end


@implementation NSDateFormatter (Tripomatic)

+ (NSDateFormatter *)sharedDateTimeFormatter
{
	static NSDateFormatter *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[NSDateFormatter alloc] init];
		shared.locale = [NSLocale sharedPOSIXLocale];
		shared.dateFormat = @"yyyy-MM-dd HH:mm:ss";
	});
	return shared;
}

+ (NSDateFormatter *)sharedDateFormatter
{
	static NSDateFormatter *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[NSDateFormatter alloc] init];
		shared.locale = [NSLocale sharedPOSIXLocale];
		shared.dateFormat = @"yyyy-MM-dd";
		shared.lenient = YES;
	});
	return shared;
}

+ (NSDateFormatter *)sharedTimeFormatter
{
	static NSDateFormatter *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[NSDateFormatter alloc] init];
		shared.dateStyle = NSDateFormatterNoStyle;
		shared.timeStyle = NSDateFormatterShortStyle;
	});
	return shared;
}

+ (NSDateFormatter *)sharedMediumStyleDateFormatter
{
	static NSDateFormatter *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[NSDateFormatter alloc] init];
		shared.dateStyle = NSDateFormatterMediumStyle;
	});
	return shared;
}

+ (NSDateFormatter *)sharedDatePickerStyleDateTimeFormatter
{
	static NSDateFormatter *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[NSDateFormatter alloc] init];
		shared.dateStyle = NSDateFormatterMediumStyle;
		shared.timeStyle = NSDateFormatterShortStyle;
	});
	return shared;
}

+ (NSDateFormatter *)sharedDEFormatDateFormatter
{
	static NSDateFormatter *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[NSDateFormatter alloc] init];
		shared.dateFormat = @"E d";
	});
	return shared;
}

+ (NSDateFormatter *)sharedEFormatDateFormatter
{
	static NSDateFormatter *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[NSDateFormatter alloc] init];
		shared.dateFormat = @"E";
	});
	return shared;
}

+ (NSDateFormatter *)sharedLLLLYYYYFormatDateFormatter
{
	static NSDateFormatter *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[NSDateFormatter alloc] init];
		shared.dateFormat = @"LLLL yyyy";
	});
	return shared;
}

+ (NSDateFormatter *)sharedLLLLDFormatDateFormatter
{
	static NSDateFormatter *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[NSDateFormatter alloc] init];
		shared.dateFormat = @"LLLL d";
	});
	return shared;
}

+ (NSDateFormatter *)shared8601DateTimeFormatter
{
	static NSDateFormatter *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[NSDateFormatter alloc] init];
		shared.locale = [NSLocale sharedPOSIXLocale];
		shared.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
	});
	return shared;
}

+ (NSDateFormatter *)shared8601RelativeDateTimeFormatter
{
	static NSDateFormatter *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[NSDateFormatter alloc] init];
		shared.locale = [NSLocale sharedPOSIXLocale];
		shared.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
	});
	return shared;
}

@end


@implementation NSDate (Tripomatic)

- (NSDate *)dateByAddingNumberOfDays:(NSInteger)days
{
	// Note: This method works with REAL celendar, dealing with timezone and DST changes.
	//       Never ever do this again by adding/subtracting time interval
	NSDateComponents *components = [[NSDateComponents alloc] init];
	components.day = days;
	@synchronized ([NSCalendar sharedCalendar]) {
		return [[NSCalendar sharedCalendar] dateByAddingComponents:components toDate:self options:0];
	}
}

+ (NSDate *)dateFromDateTimeString:(NSString *)dateString
{
	return [[NSDateFormatter sharedDateTimeFormatter] dateFromString:dateString];
}

+ (NSDate *)dateFromGMTDateTimeString:(NSString *)dateString
{
	NSTimeInterval diff = [[NSTimeZone systemTimeZone] secondsFromGMT];
	NSDate *date = [self dateFromDateTimeString:dateString];
	return [NSDate dateWithTimeInterval:diff sinceDate:date];
}

+ (NSDate *)dateFromDateString:(NSString *)dateString
{
	return [[NSDateFormatter sharedDateFormatter] dateFromString:dateString];
}

+ (NSDate *)dateFromGMTDateString:(NSString *)dateString
{
	NSTimeInterval diff = [[NSTimeZone systemTimeZone] secondsFromGMT];
	NSDate *date = [self dateFromDateString:dateString];
	return [NSDate dateWithTimeInterval:diff sinceDate:date];
}

+ (NSDate *)dateFrom8601DateTimeString:(NSString *)datetimeString
{
	return [[NSDateFormatter shared8601DateTimeFormatter] dateFromString:datetimeString];
}

+ (NSDate *)now
{
	return [NSDate new];
}

- (NSDate *)midnight
{
	@synchronized ([NSCalendar sharedCalendar]) {
		return [[NSCalendar sharedCalendar] startOfDayForDate:self];
	}
}

- (NSString *)dateString
{
	return [[NSDateFormatter sharedDateFormatter] stringFromDate:self];
}

- (NSString *)dateTimeString
{
	return [[NSDateFormatter sharedDateTimeFormatter] stringFromDate:self];
}

- (NSString *)GMTDateTimeString
{
	NSTimeInterval diff = -[[NSTimeZone systemTimeZone] secondsFromGMT];
	NSDate *gmt = [self dateByAddingTimeInterval:diff];

	return [[NSDateFormatter sharedDateTimeFormatter] stringFromDate:gmt];
}

- (NSString *)a8601DateTimeString
{
	return [[NSDateFormatter shared8601DateTimeFormatter] stringFromDate:self];
}

- (NSDate *)nearestHalfHourDate
{
	return [NSDate dateWithTimeIntervalSince1970:(ceil([self timeIntervalSince1970] / (30.0*60.0))*(30*60))];
}

- (BOOL)isToday
{
	@synchronized ([NSCalendar sharedCalendar]) {
		return [[NSCalendar sharedCalendar] isDateInToday:self];
	}
}

- (BOOL)isYesterday
{
	@synchronized ([NSCalendar sharedCalendar]) {
		return [[NSCalendar sharedCalendar] isDateInYesterday:self];
	}
}

- (BOOL)isTomorrow
{
	@synchronized ([NSCalendar sharedCalendar]) {
		return [[NSCalendar sharedCalendar] isDateInTomorrow:self];
	}
}

- (BOOL)isSameDayAsDate:(NSDate *)date
{
	@synchronized ([NSCalendar sharedCalendar]) {
		return [[NSCalendar sharedCalendar] isDate:self inSameDayAsDate:date];
	}
}

@end
