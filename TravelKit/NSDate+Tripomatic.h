//
//  NSDate+Tripomatic.h
//  Tripomatic
//
//  Created by Michal Zelinka on 20/03/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef USE_TRAVELKIT_FOUNDATION

NS_ASSUME_NONNULL_BEGIN


@interface NSLocale (Tripomatic)

+ (NSLocale *)sharedPOSIXLocale;

@end


@interface NSCalendar (Tripomatic)

+ (NSCalendar *)sharedCalendar;

@end


@interface NSDateFormatter (Tripomatic)

+ (NSDateFormatter *)sharedDateTimeFormatter;
+ (NSDateFormatter *)sharedDateFormatter;
+ (NSDateFormatter *)sharedTimeFormatter;
+ (NSDateFormatter *)sharedMediumStyleDateFormatter;
+ (NSDateFormatter *)sharedDatePickerStyleDateTimeFormatter;
+ (NSDateFormatter *)sharedDEFormatDateFormatter;
+ (NSDateFormatter *)sharedEFormatDateFormatter;
+ (NSDateFormatter *)sharedLLLLYYYYFormatDateFormatter;
+ (NSDateFormatter *)sharedLLLLDFormatDateFormatter;
+ (NSDateFormatter *)shared8601DateTimeFormatter;
+ (NSDateFormatter *)shared8601RelativeDateTimeFormatter;

@end


@interface NSDate (Tripomatic)

- (NSDate *)dateByAddingNumberOfDays:(NSInteger)days;

+ (NSDate *)dateFromDateTimeString:(NSString *)dateString;
+ (NSDate *)dateFromGMTDateTimeString:(NSString *)dateString;
+ (NSDate *)dateFromDateString:(NSString *)dateString;
+ (NSDate *)dateFromGMTDateString:(NSString *)dateString;
+ (NSDate *)dateFrom8601DateTimeString:(NSString *)datetimeString;

+ (NSDate *)now;
- (NSDate *)midnight;

+ (NSDate *)beginDate;
+ (NSDate *)endDate;

- (NSString *)dateString;
- (NSString *)dateTimeString;
- (NSString *)GMTDateTimeString;
- (NSString *)a8601DateTimeString;

- (NSDate *)nearestHalfHourDate;

/**
 * Compares if date is within same date as today
 *
 * @return if date is today
 */
- (BOOL)isToday;

- (BOOL)isYesterday;
- (BOOL)isTomorrow;

/**
 * Compares if date is the same day as given one
 *
 * @param date date to compare with
 * @return if given day is in same day or no
 */
- (BOOL)isSameDayAsDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END

#endif // USE_TRAVELKIT_FOUNDATION
