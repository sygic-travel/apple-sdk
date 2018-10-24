//
//  TKTrip.m
//  TravelKit
//
//  Created by Michal Zelinka on 25/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
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

+ (instancetype)itemForPlaceWithID:(NSString *)placeID
{
	return [[self alloc] itemForPlaceWithID:placeID];
}

- (instancetype)initForPlaceWithID:(NSString *)placeID
{
	if (!placeID) return nil;

	if (self = [super init])
	{
		_placeID = [placeID copy];
	}

	return self;
}

- (instancetype)copy
{
	TKTripDayItem *item = [TKTripDayItem itemForPlaceWithID:_placeID];
	item.duration = _duration;
	item.note = [_note copy];
	item.startTime = _startTime;

	item.transportMode = _transportMode;
	item.transportAvoid = _transportAvoid;
	item.transportStartTime = _transportStartTime;
	item.transportDuration = _transportDuration;
	item.transportNote = [_transportNote copy];
	item.transportRouteID = [_transportRouteID copy];

	item.transportPolyline = [_transportPolyline copy];

	return item;
}

- (BOOL)isEqual:(TKTripDayItem *)object
{
	return ([object isKindOfClass:[TKTripDayItem class]] &&
	        [[self asRequestDictionary] isEqual:[object asRequestDictionary]]);
}

- (instancetype)initFromDatabase:(NSDictionary *)dict
{
	if (self = [super init])
	{
		_placeID = [dict[@"item_id"] parsedString];
		_duration = [dict[@"duration"] parsedNumber];
		_note = [dict[@"note"] parsedString];
		_startTime = [dict[@"start_time"] parsedNumber];

		_transportMode = [[dict[@"transport_mode"] parsedNumber] unsignedIntegerValue];
		_transportAvoid = [[dict[@"transport_avoid"] parsedNumber] unsignedIntegerValue];
		_transportStartTime = [dict[@"transport_start_time"] parsedNumber];
		_transportDuration = [dict[@"transport_duration"] parsedNumber];
		_transportNote = [dict[@"transport_note"] parsedString];
		_transportRouteID = [dict[@"transport_route_id"] parsedString];

		_transportPolyline = [dict[@"transport_polyline"] parsedString];
	}

	return self;
}

- (instancetype)initFromResponse:(NSDictionary *)dict
{
	if (self = [super init])
	{
		_placeID = [dict[@"place_id"] parsedString];
		_duration = [dict[@"duration"] parsedNumber];
		_note = [dict[@"note"] parsedString];
		_startTime = [dict[@"start_time"] parsedNumber];

		NSDictionary *transport = [dict[@"transport_from_previous"] parsedDictionary];

		if (transport) {

			NSString *mode = [transport[@"mode"] parsedString];
			_transportMode = ([mode isEqual:@"pedestrian"]) ? TKTripTransportModePedestrian :
			                 ([mode isEqual:@"car"]) ? TKTripTransportModeCar :
			                 ([mode isEqual:@"plane"]) ? TKTripTransportModePlane :
			                 ([mode isEqual:@"bike"]) ? TKTripTransportModeBike :
			                 ([mode isEqual:@"bus"]) ? TKTripTransportModeBus :
			                 ([mode isEqual:@"train"]) ? TKTripTransportModeTrain :
			                 ([mode isEqual:@"boat"]) ? TKTripTransportModeBoat :
			                 ([mode isEqual:@"public_transit"]) ? TKTripTransportModePublicTransport :
			                     TKTripTransportModeUnknown;

			NSArray<NSString *> *avoidOpts = [transport[@"avoid"] parsedArray];
			if ([avoidOpts containsObject:@"tolls"]) _transportAvoid |= TKDirectionAvoidOptionTolls;
			if ([avoidOpts containsObject:@"highways"]) _transportAvoid |= TKDirectionAvoidOptionHighways;
			if ([avoidOpts containsObject:@"ferries"]) _transportAvoid |= TKDirectionAvoidOptionFerries;
			if ([avoidOpts containsObject:@"unpaved"]) _transportAvoid |= TKDirectionAvoidOptionUnpaved;

			_transportStartTime = [transport[@"start_time"] parsedNumber];
			_transportDuration = [transport[@"duration"] parsedNumber];
			_transportNote = [transport[@"note"] parsedString];
			_transportRouteID = [transport[@"route_id"] parsedString];

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

	dict[@"place_id"]   = _placeID ?: [NSNull null];
	dict[@"duration"]   = _duration ?: [NSNull null];
	dict[@"note"]       = _note ?: [NSNull null];
	dict[@"start_time"] = _startTime ?: [NSNull null];

	if (_transportMode) {

		NSMutableDictionary *trans = [NSMutableDictionary dictionaryWithCapacity:7];

		trans[@"mode"] = (_transportMode == TKTripTransportModePedestrian) ? @"pedestrian" :
		                 (_transportMode == TKTripTransportModeCar) ? @"car" :
		                 (_transportMode == TKTripTransportModePlane) ? @"plane" :
		                 (_transportMode == TKTripTransportModeBike) ? @"bike" :
		                 (_transportMode == TKTripTransportModeBus) ? @"bus" :
		                 (_transportMode == TKTripTransportModeTrain) ? @"train" :
		                 (_transportMode == TKTripTransportModeBoat) ? @"boat" :
		                 (_transportMode == TKDirectionModePublicTransport) ? @"public_transit" :
		                     @"car";

		trans[@"avoid"] = [@[ @"tolls", @"highways", @"ferries", @"unpaved"  ]
		mappedArrayUsingBlock:^NSString *(NSString *avoid) {
			if      ([avoid isEqual:@"tolls"]) return (_transportAvoid & TKDirectionAvoidOptionTolls) ? avoid : nil;
			else if ([avoid isEqual:@"highways"]) return (_transportAvoid & TKDirectionAvoidOptionHighways) ? avoid : nil;
			else if ([avoid isEqual:@"ferries"]) return (_transportAvoid & TKDirectionAvoidOptionFerries) ? avoid : nil;
			else if ([avoid isEqual:@"unpaved"]) return (_transportAvoid & TKDirectionAvoidOptionUnpaved) ? avoid : nil;
			return nil;
		}];

		trans[@"start_time"] = _transportStartTime ?: [NSNull null];
		trans[@"duration"] = _transportDuration ?: [NSNull null];
		trans[@"note"] = _transportNote ?: [NSNull null];
		trans[@"route_id"] = _transportRouteID ?: [NSNull null];

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

- (void)setTransportMode:(TKTripTransportMode)transportMode
{
	_transportMode = transportMode;

	if (transportMode == TKTripTransportModeUnknown) {
		_transportAvoid = TKDirectionAvoidOptionNone;
		_transportStartTime = nil;
		_transportDuration = nil;
		_transportNote = nil;
		_transportRouteID = nil;
		_transportPolyline = nil;
	}
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<Trip Day Item %p | Place ID: %@>", self, _placeID];
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
		NSMutableArray *items = [NSMutableArray arrayWithCapacity:10];

		for (NSDictionary *itemDict in [dict[@"itinerary"] parsedArray])
		{
			if (![itemDict parsedDictionary]) continue;
			TKTripDayItem *item = [[TKTripDayItem alloc] initFromResponse:itemDict];
			if (item) [items addObject:item];
		}

		_items = [items copy];
	}

	return self;
}

- (instancetype)initFromDatabase:(NSDictionary *)dict
				itemDicts:(NSArray<NSDictionary *> *)itemDicts
{
	if (self = [super init])
	{
		_note = [dict[@"note"] parsedString];

		NSMutableArray *items = [NSMutableArray arrayWithCapacity:10];

		for (NSDictionary *itemDict in itemDicts)
		{
			if (![itemDict parsedDictionary]) continue;
			TKTripDayItem *item = [[TKTripDayItem alloc] initFromDatabase:itemDict];
			if (item) [items addObject:item];
		}

		_items = [items copy];
	}

	return self;
}

- (instancetype)copy
{
	return [[TKTripDay alloc] initFromResponse:[self asRequestDictionary]];
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
		if ([it.placeID isEqual:itemID])
			return YES;

	return NO;
}

- (NSArray<NSString *> *)itemIDs
{
	return [_items mappedArrayUsingBlock:^NSString *(TKTripDayItem *item) {
		return item.placeID;
	}];
}

- (void)addItemWithID:(NSString *)itemID
{
	NSMutableArray *items = [_items mutableCopy];
	[items addObject:[TKTripDayItem itemForPlaceWithID:itemID]];
	_items = [items copy];
}

- (void)insertItemWithID:(NSString *)itemID atIndex:(NSUInteger)index
{
	NSMutableArray<TKTripDayItem *> *newItems = [_items mutableCopy];

	index = MIN(index, newItems.count);
	[newItems insertObject:[TKTripDayItem itemForPlaceWithID:itemID] atIndex:index];
	_items = newItems;
}

- (void)removeItemWithID:(NSString *)itemID
{
	_items = [[_items filteredArrayUsingBlock:^BOOL(TKTripDayItem *obj) {
		return ![obj.placeID isEqual:itemID];
	}] mutableCopy];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<Trip Day %p | items: %tu>", self, _items.count];
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
		[randomString appendFormat:@"%c", [letters characterAtIndex:arc4random() % letters.length]];

	[randomString appendFormat:@"_%.0f", [[NSDate new] timeIntervalSince1970]];

	return randomString;
}

- (instancetype)initWithName:(NSString *)name
{
    if (self = [super init])
	{
		_ID = [self.class randomTripID];
		_name = name;
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

		_name = [dict[@"name"] parsedString] ?: @"";
		_version = [[dict[@"version"] parsedNumber] unsignedIntegerValue] ?: 1;
		_ownerID = [dict[@"owner_id"] parsedString];

		NSString *stored = [dict[@"starts_on"] parsedString];
		if (stored) _startDate = [NSDate dateFromDateString:stored];

		stored = [dict[@"updated_at"] parsedString];
		if (stored) _lastUpdate = [NSDate dateFrom8601DateTimeString:stored];

		_changed = [[dict[@"changed"] parsedNumber] boolValue];
		_deleted = [[dict[@"deleted"] parsedNumber] boolValue];

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

		_destinationIDs = [[dict[@"destination_ids"] parsedString] componentsSeparatedByString:@"|"] ?: @[ ];
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

		_name = [dict[@"name"] parsedString] ?: @"";
		_version = [[dict[@"version"] parsedNumber] unsignedIntegerValue] ?: 1;
		_ownerID = [dict[@"owner_id"] parsedString];

		NSString *stored = [dict[@"starts_on"] parsedString];
		if (stored) _startDate = [NSDate dateFromDateString:stored];

		stored = [dict[@"updated_at"] parsedString];
		if (stored) _lastUpdate = [NSDate dateFrom8601DateTimeString:stored];

		_deleted = [[dict[@"is_deleted"] parsedNumber] boolValue];

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

		_destinationIDs = [[dict[@"destinations"] parsedArray] filteredArrayUsingBlock:^BOOL(id obj) {
			return [obj isKindOfClass:[NSString class]];
		}] ?: @[ ];
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
	return [NSString stringWithFormat:@"<Trip | ID: %@>\n\tName: %@\n\tVersion: %lu\n\tStart date: %@\n\tLast update: %@",
			_ID, _name, (unsigned long)_version, _startDate, _lastUpdate];
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

	if (_startDate) {
		NSInteger daysCount = (NSInteger)_days.count;
		NSDateFormatter *fmt = [NSDateFormatter sharedDateFormatter];
		dict[@"starts_on"] = [fmt stringFromDate:_startDate];
		dict[@"ends_on"] = [fmt stringFromDate:[_startDate dateByAddingNumberOfDays:daysCount-1]];
	} else {
		dict[@"starts_on"] = [NSNull null];
		dict[@"ends_on"] = [NSNull null];
	}

	dict[@"privacy_level"] =
	    (_privacy == TKTripPrivacyShareable) ? @"shareable" :
	    (_privacy == TKTripPrivacyPublic)    ? @"public"    : @"private";

	dict[@"is_deleted"] = @(_deleted);

	NSMutableArray<NSDictionary *> *dayDictsArray = [NSMutableArray arrayWithCapacity:_days.count];
	for (TKTripDay *day in _days.copy)
		[dayDictsArray addObject:[day asRequestDictionary]];
	dict[@"days"] = dayDictsArray;
	dict[@"destinations"] = _destinationIDs ?: @[ ];

	return dict;
}


#pragma mark -
#pragma mark Workers


- (NSArray<TKTripDayItem *> *)occurrencesOfItemWithID:(NSString *)itemID
{
	NSMutableArray *occurrences = [NSMutableArray arrayWithCapacity:3];

	for (TKTripDay *day in _days.copy)
		for (TKTripDayItem *item in day.items.copy)
			if ([item.placeID isEqual:itemID])
				[occurrences addObject:item];

	return [occurrences copy];
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
		_ownerID = [dict[@"owner_id"] parsedString];

		_destinationIDs = [[dict[@"destination_ids"] parsedString]
			componentsSeparatedByString:@"|"] ?: @[ ];

		NSString *stored = [dict[@"starts_on"] parsedString];
		if (stored) _startDate = [NSDate dateFromDateString:stored];
		stored = [dict[@"updated_at"] parsedString];
		if (stored) _lastUpdate = [NSDate dateFrom8601DateTimeString:stored];

		_changed = [[dict[@"changed"] parsedNumber] boolValue];
		_deleted = [[dict[@"deleted"] parsedNumber] boolValue];

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
		if ([image containsString:@"gravatar"]) {
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


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#pragma mark             - Trip conflict implementation -

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


@implementation TKTripConflict

- (instancetype)initWithLocalTrip:(TKTrip *)localTrip remoteTrip:(TKTrip *)remoteTrip
                 remoteTripEditor:(NSString *)remoteTripEditor remoteTripUpdateDate:(NSDate *)remoteTripUpdateDate
{
	if (!localTrip || !remoteTrip)
		return nil;

	if (self = [super init])
	{
		_localTrip = localTrip;
		_remoteTrip = remoteTrip;
		_remoteTripEditor = remoteTripEditor;
		_remoteTripUpdateDate = remoteTripUpdateDate;
	}

	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<TripConflict %p | Trip: %@ | %@ on %@>",
	        self, _localTrip.ID, _remoteTripEditor, _remoteTripUpdateDate];
}

@end
