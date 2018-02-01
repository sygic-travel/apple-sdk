//
//  TKTrip.h
//  TravelKit
//
//  Created by Michal Zelinka on 25/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TravelKit/TKDirectionDefinitions.h>

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
@property (nonatomic, copy) NSString *itemID;

/// Timestamp (in number of seconds from the midnight) indicating the planned start time of the Item.
@property (nonatomic, strong, nullable) NSNumber *startTime;

/// Planned duration of the Item.
@property (nonatomic, strong, nullable) NSNumber *duration;

/// A note string attached to the Item.
@property (nonatomic, copy, nullable) NSString *note;

///
@property (nonatomic) TKDirectionTransportMode transportMode;
@property (atomic) TKTransportAvoidOption transportAvoid;
@property (nonatomic, strong, nullable) NSNumber *transportStartTime;
@property (nonatomic, strong, nullable) NSNumber *transportDuration;
@property (nonatomic, copy, nullable) NSString *transportNote;
@property (nonatomic, copy, nullable) NSString *transportPolyline;

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)itemForItemWithID:(NSString *)itemID;

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
 Trip model.
 */
@interface TKTrip : NSObject

/// Trip identifier.
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
@property (nonatomic, assign) BOOL isTrashed;

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
 Trip Info model
 */
@interface TKTripInfo : NSObject

/// Trip identifier.
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
@property (nonatomic, readonly) BOOL isTrashed;

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
 Trip Conflict model

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
