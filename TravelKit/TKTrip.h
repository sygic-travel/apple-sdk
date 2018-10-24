//
//  TKTrip.h
//  TravelKit
//
//  Created by Michal Zelinka on 25/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TravelKit/TKDirection.h>

/**
 The mode of transport used to indicate the mean of transportation between places.
 */
typedef NS_OPTIONS(NSUInteger, TKTripTransportMode) {
	TKTripTransportModeUnknown         = (0), /// Unknown mode.
	TKTripTransportModePedestrian      = (1 << 0), /// Pedestrian mode.
	TKTripTransportModeCar             = (1 << 1), /// Car mode.
	TKTripTransportModePlane           = (1 << 2), /// Plane mode.
	TKTripTransportModeBike            = (1 << 3), /// Bike mode.
	TKTripTransportModeBus             = (1 << 4), /// Bus mode.
	TKTripTransportModeTrain           = (1 << 5), /// Train mode.
	TKTripTransportModeBoat            = (1 << 6), /// Boat mode.
	TKTripTransportModePublicTransport = (1 << 7), /// Public transport mode.
}; // ABI-EXPORTED


NS_ASSUME_NONNULL_BEGIN

///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Trip Day Item model
///-----------------------------------------------------------------------------


/**
 Trip Day Item model.
 */
@interface TKTripDayItem : NSObject

/// Item ID.
@property (nonatomic, copy, readonly) NSString *placeID;

/// Timestamp (in number of seconds from the midnight) indicating the planned start time of the Item.
@property (nonatomic, strong, nullable) NSNumber *startTime;

/// Planned duration of the Item.
@property (nonatomic, strong, nullable) NSNumber *duration;

/// A note string attached to the Item.
@property (nonatomic, copy, nullable) NSString *note;

///
@property (nonatomic) TKTripTransportMode transportMode;
@property (atomic) TKDirectionAvoidOption transportAvoid;
@property (nonatomic, strong, nullable) NSNumber *transportStartTime;
@property (nonatomic, strong, nullable) NSNumber *transportDuration;
@property (nonatomic, copy, nullable) NSString *transportNote;
@property (nonatomic, copy, nullable) NSString *transportPolyline;

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)itemForPlaceWithID:(NSString *)placeID;

@end


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Trip Day model
///-----------------------------------------------------------------------------


/**
 Trip Day model.
 */
@interface TKTripDay : NSObject

/// Working array of Item IDs.
@property (nonatomic, copy, readonly) NSArray<NSString *> *itemIDs;

/// Array of Item objects.
@property (nonatomic, strong) NSArray<TKTripDayItem *> *items;

/// String with a note.
@property (nonatomic, copy, nullable) NSString *note;

// Insertion & removal methods
- (void)addItemWithID:(NSString *)itemID;
- (void)insertItemWithID:(NSString *)itemID atIndex:(NSUInteger)index;
- (void)removeItemWithID:(NSString *)itemID;

// Test for presence
- (BOOL)containsItemWithID:(NSString *)itemID;

@end


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Trip model
///-----------------------------------------------------------------------------


/**
 The primary Trip model to work with.

 You may work with this object freely. Once you edit its contents according to needs, simply saving the trip
 via `-[TKTripsManager saveTrip:]` will store it locally and eventually synchronize after a synchronization
 loop occurs.
 */
@interface TKTrip : NSObject

/// Trip identifier. Has same value as ID in TKTripInfo for the same trip.
@property (nonatomic, readonly) NSString *ID NS_SWIFT_NAME(ID);

/// Trip name.
@property (nonatomic, copy) NSString *name;

/// Working Trip version.
@property (nonatomic, readonly) NSUInteger version;

/// Start date of the Trip.
@property (nonatomic, strong, nullable) NSDate *startDate;

/// Last Trip update timestamp.
@property (nonatomic, strong, readonly, nullable) NSDate *lastUpdate;

/// Flag indicating whether the Trip is currently placed in the Trash.
@property (nonatomic, assign) BOOL deleted;

/// Array of Trip Destination IDs. Customisable.
@property (nonatomic, copy) NSArray<NSString *> *destinationIDs;

/// Array of Trip Day objects.
@property (nonatomic, copy) NSArray<TKTripDay *> *days;

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/**
 * Init a new Trip object with a generated ID and a given name.
 *
 * @param name Name of the creted trip
 * @return Object with fully filled information
 */
- (instancetype)initWithName:(NSString *)name;

// Item workers
- (NSArray<TKTripDayItem *> *)occurrencesOfItemWithID:(NSString *)itemID;

// Information providers
- (NSSet<NSString *> *)itemIDsInTrip;
- (BOOL)containsItemWithID:(NSString *)itemID;
- (NSArray<NSNumber *> *)indexesOfDaysContainingItemWithID:(NSString *)itemID;
- (BOOL)isEmpty;

@end


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Trip info object
///-----------------------------------------------------------------------------


/**
 Lightweight, read-only Trip Info model. Useful for listings, collections and similar stuff.
 Includes same information as TKTrip, but does not carry whole TKTripDayItems, but only information about their count.
 TKTripInfo can not be used to delete whole trip.
 */
@interface TKTripInfo : NSObject

/// TripInfo identifier. Has same value as ID in TKTrip for the same trip.
@property (nonatomic, copy, readonly) NSString *ID NS_SWIFT_NAME(ID);

/// Trip name.
@property (nonatomic, copy, readonly) NSString *name;

/// Working Trip version.
@property (nonatomic, readonly) NSUInteger version;

/// Start date of the Trip.
@property (nonatomic, strong, readonly, nullable) NSDate *startDate;

/// Last Trip update timestamp.
@property (nonatomic, strong, readonly, nullable) NSDate *lastUpdate;

/// Flag indicating whether the Trip is currently placed in the Trash.
@property (nonatomic, readonly) BOOL deleted;

/// Array of Trip Destination IDs. Customisable.
@property (nonatomic, copy, readonly) NSArray<NSString *> *destinationIDs;

/// A number of days/day length defined for the Trip.
@property (nonatomic, readonly) NSUInteger daysCount;

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

@end


///-----------------------------------------------------------------------------
#pragma mark -
#pragma mark Trip conflict object
///-----------------------------------------------------------------------------


/**
 Trip Conflict model.

 This object is used to specify the user's decision whether to keep a local (on device) version of a particular
 trip or prefer the the remote (server) version contributed in the meantime.
 */
@interface TKTripConflict : NSObject

/// Local (on device) Trip instance.
@property (nonatomic, strong, readonly) TKTrip *localTrip;
/// Remote (server) Trip instance.
@property (nonatomic, strong, readonly) TKTrip *remoteTrip;
/// Optional name of a person authoring the remote Trip instance.
@property (nonatomic, copy, readonly, nullable) NSString *remoteTripEditor;
/// Optional date when the remote Trip instance has been pushed.
@property (nonatomic, strong, readonly, nullable) NSDate *remoteTripUpdateDate;

/// A flag indicating whether the local Trip instance should be force-pushed to the server (`YES`) or rather
/// overwritten by the server version (`NO`).
@property (atomic) BOOL forceLocalTrip;

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

@end

NS_ASSUME_NONNULL_END
