//
//  TKTrip.m
//  TravelKit
//
//  Created by Michal Zelinka on 25/10/2017.
//  Copyright (c) 2012 Tripomatic. All rights reserved.
//

#import "TKMapWorker.h"
#import "TKTrip+Private.h"

#import "Foundation+TravelKit.h"
#import "NSObject+Parsing.h"
#import "NSDate+Tripomatic.h"

// NSLocalizedString(@"Trip to %@", @"Default trip name pattern -- f.e. Trip to London")
// NSLocalizedString(@"My Trip", @"Generic Trip name")


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark             - Trip Day Item implementation -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@implementation TKTripDayItem

+ (instancetype)itemForItemWithID:(NSString *)itemID
{
	return [[self alloc] initForItemWithID:itemID];
}

- (instancetype)initForItemWithID:(NSString *)itemID
{
	if (!itemID) return nil;

	if (self = [super init])
	{
		_itemID = [itemID copy];
	}

	return self;
}

- (instancetype)initFromDatabase:(NSDictionary *)dict
{
	if (self = [super init])
	{
		_itemID = [dict[@"item_id"] parsedString];
		_duration = [dict[@"duration"] parsedNumber];
		_note = [dict[@"note"] parsedString];
		_startTime = [dict[@"start_time"] parsedNumber];

		_transportMode = [[dict[@"transport_mode"] parsedNumber] unsignedIntegerValue];
		_transportType = [[dict[@"transport_type"] parsedNumber] unsignedIntegerValue];
		_transportAvoid = [[dict[@"transport_avoid"] parsedNumber] unsignedIntegerValue];
		_transportStartTime = [dict[@"transport_start_time"] parsedNumber];
		_transportDuration = [dict[@"transport_duration"] parsedNumber];
		_transportNote = [dict[@"transport_note"] parsedString];

		_transportPolyline = [dict[@"transport_polyline"] parsedString];
	}

	return self;
}

- (instancetype)initFromResponse:(NSDictionary *)dict
{
	if (self = [super init])
	{
		_itemID = [dict[@"place_id"] parsedString];
		_duration = [dict[@"duration"] parsedNumber];
		_note = [dict[@"note"] parsedString];
		_startTime = [dict[@"start_time"] parsedNumber];

		NSDictionary *transport = [dict[@"transport_from_previous"] parsedDictionary];

		if (transport) {

			id obj = [transport[@"mode"] parsedString];
			_transportMode = ([obj isEqual:@"pedestrian"]) ? TKDirectionTransportModeWalk :
			                 ([obj isEqual:@"car"]) ? TKDirectionTransportModeCar :
			                 ([obj isEqual:@"plane"]) ? TKDirectionTransportModeFlight :
			                 ([obj isEqual:@"bike"]) ? TKDirectionTransportModeBike :
			                 ([obj isEqual:@"bus"]) ? TKDirectionTransportModeBus :
			                 ([obj isEqual:@"train"]) ? TKDirectionTransportModeTrain :
			                 ([obj isEqual:@"boat"]) ? TKDirectionTransportModeBoat :
			                                           TKDirectionTransportModeUnknown;

			obj = [transport[@"type"] parsedString];
			_transportType = ([obj isEqual:@"fastest"]) ? TKDirectionTransportTypeFastest :
			                 ([obj isEqual:@"shortest"]) ? TKDirectionTransportTypeShortest :
			                 ([obj isEqual:@"economic"]) ? TKDirectionTransportTypeEconomic :
			                                               TKDirectionTransportTypeFastest;

			obj = [transport[@"avoid"] parsedArray];
			if ([obj containsObject:@"tolls"]) _transportAvoid |= TKTransportAvoidOptionTolls;
			if ([obj containsObject:@"highways"]) _transportAvoid |= TKTransportAvoidOptionHighways;
			if ([obj containsObject:@"ferries"]) _transportAvoid |= TKTransportAvoidOptionFerries;
			if ([obj containsObject:@"unpaved"]) _transportAvoid |= TKTransportAvoidOptionUnpaved;

			_transportStartTime = [transport[@"start_time"] parsedNumber];
			_transportDuration = [transport[@"duration"] parsedNumber];
			_transportNote = [transport[@"note"] parsedString];

			NSMutableArray *locs = [NSMutableArray arrayWithCapacity:6];
			for (NSDictionary *point in [transport[@"waypoints"] parsedArray])
			{
				CLLocationDegrees lat = [[point[@"location"][@"lat"] parsedNumber] doubleValue];
				CLLocationDegrees lng = [[point[@"location"][@"lng"] parsedNumber] doubleValue];
				CLLocation *loc = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
				if (loc) [locs addObject:loc];
			}

			if (locs.count) _transportPolyline = [TKMapWorker polylineFromPoints:locs];
		}
	}

	return self;
}

- (NSDictionary *)asRequestDictionary
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];

	dict[@"place_id"]   = _itemID ?: [NSNull null];
	dict[@"duration"]   = _duration ?: [NSNull null];
	dict[@"note"]       = _note ?: [NSNull null];
	dict[@"start_time"] = _startTime ?: [NSNull null];

	if (_transportMode) {

		NSMutableDictionary *trans = [NSMutableDictionary dictionaryWithCapacity:7];

		trans[@"mode"] = (_transportMode == TKDirectionTransportModeWalk) ? @"pedestrian" :
		                 (_transportMode == TKDirectionTransportModeCar) ? @"car" :
		                 (_transportMode == TKDirectionTransportModeFlight) ? @"plane" :
		                 (_transportMode == TKDirectionTransportModeBike) ? @"bike" :
		                 (_transportMode == TKDirectionTransportModeBus) ? @"bus" :
		                 (_transportMode == TKDirectionTransportModeTrain) ? @"train" :
		                 (_transportMode == TKDirectionTransportModeBoat) ? @"boat" : @"car";

		trans[@"type"] = (_transportType == TKDirectionTransportTypeFastest) ? @"fastest" :
		                 (_transportType == TKDirectionTransportTypeShortest) ? @"shortest" :
		                 (_transportType == TKDirectionTransportTypeEconomic) ? @"economic" : @"fastest";

		trans[@"avoid"] = [@[ @"tolls", @"highways", @"ferries", @"unpaved"  ]
		mappedArrayUsingBlock:^NSString *(NSString *avoid) {
			if      ([avoid isEqual:@"tolls"]) return (_transportAvoid & TKTransportAvoidOptionTolls) ? avoid : nil;
			else if ([avoid isEqual:@"highways"]) return (_transportAvoid & TKTransportAvoidOptionHighways) ? avoid : nil;
			else if ([avoid isEqual:@"ferries"]) return (_transportAvoid & TKTransportAvoidOptionFerries) ? avoid : nil;
			else if ([avoid isEqual:@"unpaved"]) return (_transportAvoid & TKTransportAvoidOptionUnpaved) ? avoid : nil;
			return nil;
		}];

		trans[@"start_time"] = _transportStartTime ?: [NSNull null];
		trans[@"duration"] = _transportDuration ?: [NSNull null];
		trans[@"note"] = _transportNote ?: [NSNull null];

		NSArray<CLLocation *> *points = (_transportPolyline) ?
			[TKMapWorker pointsFromPolyline:_transportPolyline] ?: @[ ] : @[ ];

		trans[@"waypoints"] = [points mappedArrayUsingBlock:^id(CLLocation *l) {
			return (l) ? @{ @"location": @{ @"lat": @(l.coordinate.latitude), @"lng": @(l.coordinate.longitude) } } : nil;
		}];

		dict[@"transport_from_previous"] = trans;
	}
	else dict[@"transport_from_previous"] = [NSNull null];

	return dict;
}

- (void)setTransportMode:(TKDirectionTransportMode)transportMode
{
	_transportMode = transportMode;

	if (transportMode == TKDirectionTransportModeUnknown) {
		_transportType = TKDirectionTransportTypeFastest;
		_transportAvoid = TKTransportAvoidOptionNone;
		_transportStartTime = nil;
		_transportDuration = nil;
		_transportNote = nil;
		_transportPolyline = nil;
	}
}

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark               - Trip Day implementation -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@implementation TKTripDay

#pragma mark Init methods

- (instancetype)init
{
	if (self = [super init])
		_items = [NSMutableArray array];

	return self;
}

- (instancetype)initFromResponse:(NSDictionary *)dict
{
	if (self = [super init])
	{
		_note = [dict[@"note"] parsedString];
		_items = [NSMutableArray arrayWithCapacity:10];

		for (NSDictionary *itemDict in [dict[@"itinerary"] parsedArray])
		{
			if (![itemDict parsedDictionary]) continue;
			TKTripDayItem *item = [[TKTripDayItem alloc] initFromResponse:itemDict];
			if (item) [_items addObject:item];
		}
	}

	return self;
}

- (instancetype)initFromDatabase:(NSDictionary *)dict
				itemDicts:(NSArray<NSDictionary *> *)itemDicts
{
	if (self = [super init])
	{
		_note = [dict[@"note"] parsedString];

		_items = [NSMutableArray arrayWithCapacity:10];

		for (NSDictionary *itemDict in itemDicts)
		{
			if (![itemDict parsedDictionary]) continue;
			TKTripDayItem *item = [[TKTripDayItem alloc] initFromDatabase:itemDict];
			if (item) [_items addObject:item];
		}
	}

	return self;
}

- (NSDictionary *)asRequestDictionary
{
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:2];

	dict[@"note"] = _note ?: [NSNull null];

	NSMutableArray<NSDictionary *> *dayItemDictsArray = [NSMutableArray arrayWithCapacity:_items.count];
	for (TKTripDayItem *item in _items.copy)
		[dayItemDictsArray addObject:[item asRequestDictionary]];
	dict[@"itinerary"] = dayItemDictsArray;

	return dict;
}

#pragma mark Workers

- (BOOL)containsItemWithID:(NSString *)itemID
{
	for (TKTripDayItem *it in _items.copy)
		if ([it.itemID isEqual:itemID])
			return YES;

	return NO;
}

- (NSArray<NSString *> *)itemIDs
{
	return [_items mappedArrayUsingBlock:^NSString *(TKTripDayItem *item) {
		return item.itemID;
	}];
}

- (void)addItemWithID:(NSString *)itemID
{
	[_items addObject:[TKTripDayItem itemForItemWithID:itemID]];
}

- (void)insertItemWithID:(NSString *)itemID atIndex:(NSUInteger)index
{
	NSMutableArray<TKTripDayItem *> *newItems = [_items mutableCopy];

	index = MIN(index, newItems.count);
	[newItems insertObject:[TKTripDayItem itemForItemWithID:itemID] atIndex:index];

	_items = newItems;
}

- (void)removeItemWithID:(NSString *)itemID
{
	_items = [[_items filteredArrayUsingBlock:^BOOL(TKTripDayItem *obj) {
		return ![obj.itemID isEqual:itemID];
	}] mutableCopy];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<Trip day | items: %tu>", _items.count];
}

- (BOOL)isToday
{
	if (_date) return [_date isToday];
	return NO;
}

- (NSString *)formattedDayName
{
	if (!_date)
		return [NSString stringWithFormat:NSLocalizedString(@"Day %tu", @"View title with number"), _dayIndex+1];

	if ([_date isToday])
		return NSLocalizedString(@"Today", @"View heading");
	else if ([_date isTomorrow])
		return NSLocalizedString(@"Tomorrow", @"View heading");
	else if ([_date isYesterday])
		return NSLocalizedString(@"Yesterday", @"View heading");

	return [[NSDateFormatter sharedDEFormatDateFormatter] stringFromDate:_date];
}


@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark               - Trip implementation -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@implementation TKTrip

+ (NSString *)randomTripID
{
	NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

	NSMutableString *randomString = [@LOCAL_TRIP_PREFIX mutableCopy];

	for (uint i = 0; i < 16; i++)
		[randomString appendFormat:@"%c", [letters characterAtIndex:arc4random()%[letters length]]];

	[randomString appendFormat:@"_%.0f", [[NSDate new] timeIntervalSince1970]];

	return randomString;
}

- (instancetype)init
{
    if (self = [super init])
	{
		_ID = [self.class randomTripID];
		_name = GENERIC_TRIP_NAME;
		_version = 1;
        _days = [NSMutableArray array];
		_privacy = TKTripPrivacyPrivate;
		_rights = TKTripRightsAllRights;
    }

    return self;
}

- (instancetype)initWithName:(NSString *)name
{
    if (self = [super init])
	{
		_ID = [self.class randomTripID];
		_name = name ?: GENERIC_TRIP_NAME;
		_version = 1;
        _days = [NSMutableArray array];
		_privacy = TKTripPrivacyPrivate;
		_rights = TKTripRightsAllRights;
    }

    return self;
}

- (instancetype)initFromDatabase:(NSDictionary *)dict
                        dayDicts:(NSArray<NSDictionary *> *)dayDicts
                    dayItemDicts:(NSArray<NSDictionary *> *)dayItemDicts
{
	if (self = [super init])
	{
		_ID = [dict[@"id"] parsedString];

		if (!_ID) return nil;

		// Basic attributes

		_name = [dict[@"name"] parsedString] ?: GENERIC_TRIP_NAME;
		_version = [[dict[@"version"] parsedNumber] unsignedIntegerValue] ?: 1;
		_userID = [dict[@"user_id"] parsedString];
		_ownerID = [dict[@"owner_id"] parsedString] ?: _userID;

		NSString *stored = [dict[@"starts_on"] parsedString];
		if (stored) _dateStart = [NSDate dateFromDateString:stored];

		stored = [dict[@"updated_at"] parsedString];
		if (stored) _lastUpdate = [NSDate dateFrom8601DateTimeString:stored];

		_changed = [[dict[@"changed"] parsedNumber] boolValue];
		_isTrashed = [[dict[@"deleted"] parsedNumber] boolValue];

		_privacy = [dict[@"privacy"] unsignedIntegerValue];
		_rights  = [dict[@"rights"]  unsignedIntegerValue];

		// Days
		NSUInteger daysCount = [[dict[@"days"] parsedNumber] unsignedIntegerValue];

		NSMutableArray<TKTripDay *> *days = [NSMutableArray arrayWithCapacity:10];

		for (NSUInteger dayIndex = 0; dayIndex < daysCount; dayIndex++)
		{
			NSDictionary *dayDict = [[dayDicts filteredArrayUsingBlock:^BOOL(NSDictionary *d) {
				return [[d[@"day_index"] parsedNumber] unsignedIntegerValue] == dayIndex;
			}] firstObject];

			NSArray<NSDictionary *> *itemDicts = [dayItemDicts filteredArrayUsingBlock:^BOOL(NSDictionary *it) {
				return [[it[@"day_index"] parsedNumber] unsignedIntegerValue] == dayIndex;
			}];

			[days addObject:( [[TKTripDay alloc] initFromDatabase:dayDict itemDicts:itemDicts] ?: [TKTripDay new] )];
		}

		_days = [days copy];
	}

	return self;
}

- (instancetype)initFromResponse:(NSDictionary *)dict
{
	if (self = [super init])
	{
		_ID = [dict[@"id"] parsedString];

		if (!_ID) return nil;

		// Basic attributes

		_name = [dict[@"name"] parsedString] ?: GENERIC_TRIP_NAME;
		_version = [[dict[@"version"] parsedNumber] unsignedIntegerValue] ?: 1;
		_userID = [dict[@"user_id"] parsedString];
		_ownerID = [dict[@"owner_id"] parsedString] ?: _userID;

		NSString *stored = [dict[@"starts_on"] parsedString];
		if (stored) _dateStart = [NSDate dateFromDateString:stored];

		stored = [dict[@"updated_at"] parsedString];
		if (stored) _lastUpdate = [NSDate dateFrom8601DateTimeString:stored];

		_isTrashed = [[dict[@"is_deleted"] parsedNumber] boolValue];

		stored = [dict[@"privacy_level"] parsedString];
		_privacy = ([stored isEqual:@"shareable"]) ? TKTripPrivacyShareable :
		           ([stored isEqual:@"public"])    ? TKTripPrivacyPublic    : TKTripPrivacyPrivate;

		_rights = TKTripRightsNoRights;
		NSDictionary *rights = [dict[@"privileges"] parsedDictionary];
		if ([[rights[@"edit"]   parsedNumber] boolValue]) _rights |= TKTripRightsEdit;
		if ([[rights[@"manage"] parsedNumber] boolValue]) _rights |= TKTripRightsManage;
		if ([[rights[@"delete"] parsedNumber] boolValue]) _rights |= TKTripRightsDelete;

		// Days

		NSMutableArray<TKTripDay *> *days = [NSMutableArray arrayWithCapacity:10];

		for (NSDictionary *dayDict in [dict[@"days"] parsedArray])
			[days addObject:( [[TKTripDay alloc] initFromResponse:dayDict] ?: [TKTripDay new] )];

		_days = [days copy];
	}

	return self;
}

- (BOOL)isEditable   { return (_rights & TKTripRightsEdit); }
- (BOOL)isManageable { return (_rights & TKTripRightsManage); }
- (BOOL)isDeletable  { return (_rights & TKTripRightsDelete); }


#pragma mark -
#pragma mark Getters


- (NSSet *)itemIDsInTrip
{
	NSMutableSet *ret = [NSMutableSet set];
	for (TKTripDay *day in _days.copy)
		for (NSString *itemID in day.itemIDs)
			[ret addObject:itemID];

	return ret;
}

- (BOOL)containsItemWithID:(NSString *)itemID
{
	for (TKTripDay *day in _days.copy)
		if ([day containsItemWithID:itemID])
			return YES;
	return NO;
}

- (BOOL)isEmpty
{
	for (TKTripDay *day in _days.copy)
		if (day.items.count)
			return NO;
	return YES;
}

- (BOOL)isEqual:(TKTrip *)trip
{
	// Equality check performs all required
	// fields indicating possible difference

	return (self.class == trip.class &&
	        self.version == trip.version &&
	       [self.lastUpdate isEqualToDate:trip.lastUpdate] &&
	        self.rights == trip.rights &&
	        self.privacy == trip.privacy);
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<Trip | ID: %@>\n\tName: %@\n\tVersion: %zd\n\tStart date: %@\n\tLast update: %@",
			_ID, _name, _version, _dateStart, _lastUpdate];
}

- (NSString *)formattedDuration
{
	NSString * retString = @"";

	if (_dateStart) {
		NSDateFormatter *formatter = [NSDateFormatter sharedLLLLDFormatDateFormatter];

		retString = [formatter stringFromDate:_dateStart];

		if (_days.count > 1) {
			NSInteger daysCount = (NSInteger)_days.count;
			NSDate *dateEnd = [_dateStart dateByAddingNumberOfDays:(daysCount-1)];
			NSString *endString = [formatter stringFromDate:dateEnd];

			retString = [retString stringByAppendingFormat:@" – %@", endString];
		}
	}
	else
	{
		retString = NSLocalizedString(@"%tu days", @"Number of days label, f.e. 3 days");
		retString = [NSString localizedStringWithFormat:retString, _days.count];
	}

	return retString;
}

- (NSArray<NSNumber *> *)indexesOfDaysContainingItemWithID:(NSString *)itemID
{
	if (!itemID) return @[ ];

	NSMutableArray<NSNumber *> *indexes = [NSMutableArray arrayWithCapacity:[_days count]];

	for (TKTripDay *day in _days.copy)
		if ([day containsItemWithID:itemID])
			[indexes addObject:@( [_days indexOfObject:day] )];

	return indexes;
}

- (TKTripDay *)dayWithDateAtIndex:(NSUInteger)index
{
	if (index >= _days.count)
		return nil;

	TKTripDay *day = _days[index];

	day.dayIndex = index;
	day.date = [[_dateStart dateByAddingNumberOfDays:(NSInteger)index] midnight];

	if (day.date) {

		static NSDateFormatter *shortDate = nil;
		static NSDateFormatter *dayNumber = nil;
		static NSDateFormatter *dayName = nil;
		static dispatch_once_t once;
		dispatch_once(&once, ^{
			shortDate = [NSDateFormatter new];
			shortDate.locale = [NSLocale currentLocale];
			shortDate.timeZone = [NSTimeZone systemTimeZone];
			shortDate.dateFormat = @"MMM d";
			dayNumber = [NSDateFormatter new];
			dayNumber.locale = [NSLocale currentLocale];
			dayNumber.timeZone = [NSTimeZone systemTimeZone];
			dayNumber.dateFormat = @"d";
			dayName = [NSDateFormatter new];
			dayName.locale = [NSLocale currentLocale];
			dayName.timeZone = [NSTimeZone systemTimeZone];
			dayName.dateFormat = @"E";
		});

		day.dayNumber = [dayNumber stringFromDate:day.date];
		day.dayName = [dayName stringFromDate:day.date];
		day.shortDateString = [shortDate stringFromDate:day.date];

	} else {

		day.dayNumber = [NSString stringWithFormat:@"%tu", index+1];
		day.dayName = NSLocalizedString(@"day", @"Day name label");
		day.shortDateString = [NSString stringWithFormat:@"%@ %@", day.dayName, day.dayNumber];

	}
	
	return day;
}


#pragma mark -
#pragma mark API serialization


- (NSDictionary *)asRequestDictionary
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];

	dict[@"id"] = _ID;

	if ([_ID hasPrefix:@LOCAL_TRIP_PREFIX])
		[dict removeObjectForKey:@"id"];

	dict[@"base_version"] = @(_version);
	if (_name) dict[@"name"] = _name;

	if (_lastUpdate) dict[@"updated_at"] =
		[[NSDateFormatter shared8601DateTimeFormatter] stringFromDate:_lastUpdate];

	if (_dateStart) {
		NSInteger daysCount = (NSInteger)_days.count;
		NSDateFormatter *fmt = [NSDateFormatter sharedDateFormatter];
		dict[@"starts_on"] = [fmt stringFromDate:_dateStart];
		dict[@"ends_on"] = [fmt stringFromDate:[_dateStart dateByAddingNumberOfDays:daysCount-1]];
	}

	dict[@"privacy_level"] =
	    (_privacy == TKTripPrivacyShareable) ? @"shareable" :
	    (_privacy == TKTripPrivacyPublic)    ? @"public"    : @"private";

	dict[@"is_deleted"] = @(_isTrashed);

	NSMutableArray<NSDictionary *> *dayDictsArray = [NSMutableArray arrayWithCapacity:_days.count];
	for (TKTripDay *day in _days.copy)
		[dayDictsArray addObject:[day asRequestDictionary]];
	dict[@"days"] = dayDictsArray;

	return dict;
}


#pragma mark -
#pragma mark Workers


- (void)addNewDay
{
	_days = [_days arrayByAddingObject:[TKTripDay new]];
}

- (void)removeDay:(TKTripDay *)day
{
	if (!day) return;

	NSMutableArray *days = [_days mutableCopy];

	if (days.count <= 1) return;

	[days removeObject:day];
	_days = [days copy];
}

- (void)addItem:(NSString *)itemID toDay:(NSUInteger)dayIndex {
    if (dayIndex < [_days count]) {
        TKTripDay *day = _days[dayIndex];
        [day addItemWithID:itemID];
    }
}

- (void)removeItem:(NSString *)itemID fromDay:(NSUInteger)dayIndex {
    if (dayIndex < [_days count]) {
        TKTripDay *day = _days[dayIndex];
        [day removeItemWithID:itemID];
    }
}

- (void)removeItem:(NSString *)itemID {
	for (TKTripDay *day in _days)
        [day removeItemWithID:itemID];
}

- (NSArray<TKTripDayItem *> *)occurrencesOfItemWithID:(NSString *)itemID
{
	NSMutableArray *occurrences = [NSMutableArray arrayWithCapacity:3];

	for (TKTripDay *day in _days.copy)
		for (TKTripDayItem *item in day.items.copy)
			if ([item.itemID isEqual:itemID])
				[occurrences addObject:item];

	return [occurrences copy];
}

- (BOOL)moveDayAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex
{
	BOOL ok = NO;
	if (sourceIndex != destinationIndex && sourceIndex < _days.count && destinationIndex < _days.count) {
		TKTripDay *movedDay = _days[sourceIndex];
		if (movedDay) {

			NSMutableArray *days = [_days mutableCopy];
			[days removeObjectAtIndex:sourceIndex];
			[days insertObject:movedDay atIndex:destinationIndex];
			_days = days;
			ok = YES;
		}
	}
	return ok;
}

- (BOOL)moveActivityAtDay:(NSUInteger)dayIndex withIndex:(NSUInteger)activityIndex
                    toDay:(NSUInteger)destDayIndex withIndex:(NSUInteger)destActivityIndex
{
	// NEW-TRIPS-TODO: Perform all the sticky/moving/transport-cropping magic 🎩

	BOOL ok = NO;
	if (dayIndex < _days.count && destDayIndex < _days.count) {
		if (dayIndex == destDayIndex) { // the same day
			if (activityIndex != destActivityIndex) {
				TKTripDay *tripDay = _days[dayIndex];
				if (activityIndex < tripDay.items.count && destActivityIndex < tripDay.items.count) {
					NSString *activityID = tripDay.items[activityIndex].itemID;
					[tripDay.items removeObjectAtIndex:activityIndex];
					[tripDay.items insertObject:[TKTripDayItem itemForItemWithID:activityID] atIndex:destActivityIndex];
					ok = YES;
				}
			}
		}
		else { // different days
			TKTripDay *srcDay = _days[dayIndex];
			TKTripDay *dstDay = _days[destDayIndex];
			if (activityIndex < srcDay.items.count && destActivityIndex <= dstDay.items.count) {
				NSString *activityID = srcDay.items[activityIndex].itemID;
				[srcDay.items removeObjectAtIndex:activityIndex];
				[dstDay.items insertObject:[TKTripDayItem itemForItemWithID:activityID] atIndex:destActivityIndex];
				ok = YES;
			}
		}
	}
	return ok;
}

- (BOOL)removeActivityAtDay:(NSUInteger)dayIndex withIndex:(NSUInteger)activityIndex
{
	BOOL ok = NO;
	if (dayIndex < _days.count) {
		TKTripDay *tripDay = _days[dayIndex];
		if (activityIndex < tripDay.items.count) {
			[tripDay.items removeObjectAtIndex:activityIndex];
			ok = YES;
		}
	}
	return ok;
}

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark             - Trip info implementation -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@implementation TKTripInfo

- (instancetype)initFromDatabase:(NSDictionary *)dict
{
	if (!dict) return nil;

	if (self = [super init])
	{
		_ID = [dict[@"id"] parsedString];
		_name = [dict[@"name"] parsedString];
		_version = [[dict[@"version"] parsedNumber] unsignedIntegerValue];
		_daysCount = [[dict[@"days"] parsedNumber] unsignedIntegerValue];
		_userID = [dict[@"user_id"] parsedString];
		_ownerID = [dict[@"owner_id"] parsedString];

		NSString *stored = [dict[@"starts_on"] parsedString];
		if (stored) _startDate = [NSDate dateFromDateString:stored];
		stored = [dict[@"updated_at"] parsedString];
		if (stored) _lastUpdate = [NSDate dateFrom8601DateTimeString:stored];

		_changed = [[dict[@"changed"] parsedNumber] boolValue];
		_isTrashed = [[dict[@"deleted"] parsedNumber] boolValue];

		_privacy = [[dict[@"privacy"] parsedNumber] unsignedIntegerValue];
		_rights = [[dict[@"rights"] parsedNumber] unsignedIntegerValue];
	}

	return self;
}

- (BOOL)isEditable   { return (_rights & TKTripRightsEdit); }
- (BOOL)isManageable { return (_rights & TKTripRightsManage); }
- (BOOL)isDeletable  { return (_rights & TKTripRightsDelete); }

- (BOOL)isEqual:(TKTripInfo *)trip
{
	// Equality check performs all required
	// fields indicating possible difference

	return (self.class == trip.class &&
	        self.version == trip.version &&
	       [self.lastUpdate isEqual:trip.lastUpdate] &&
	        self.rights == trip.rights &&
	        self.privacy == trip.privacy);
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<Trip Info | ID: %@>\n\tName = %@\n\tVersion = %tu\n\tStart date = %@\n\tDays count = %tu\n\tChanged = %c",
			_ID, _name, _version, _startDate, _daysCount, _changed];
}

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark           - Trip collaborator implementation -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@implementation TKTripCollaborator

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
	if (self = [super init])
	{
		_ID = [dictionary[@"id"] parsedNumber];
		_name = [dictionary[@"user_name"] parsedString];
		_email = [dictionary[@"user_email"] parsedString];
		_accepted = [[dictionary[@"accepted"] parsedNumber] boolValue];
		_hasWriteAccess = [[dictionary[@"access_level"] parsedString] isEqual:@"read-write"];

		NSString *image = [dictionary[@"user_photo_url"] parsedString];
		if ([image containsSubstring:@"gravatar"]) {
			NSRange r = [image rangeOfString:@"&d="];
			if (r.location != NSNotFound)
				image = [[image substringToPosition:r.location] stringByAppendingString:@"&d=null"];
		}

		if (image) _photoURL = [NSURL URLWithString:image];
	}

	return self;
}

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark             - Trip template implementation -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@implementation TKTripTemplate

- (instancetype)initFromResponse:(NSDictionary *)dictionary
{
	if (self = [super init])
	{
		_ID = [dictionary[@"id"] parsedNumber];
		_perex = [dictionary[@"description"] parsedString];

		NSDictionary *tripDict = [dictionary[@"trip"] parsedDictionary];
		if (tripDict) _trip = [[TKTrip alloc] initFromResponse:tripDict];

		if (!_ID || !_trip) return nil;

		_duration = [dictionary[@"duration"] parsedNumber] ?:
		            @(_trip.days.count * 86400);
	}

	return self;
}

- (NSArray<NSString *> *)allItemIDs
{
	return [[_trip itemIDsInTrip] allObjects];
}

@end
