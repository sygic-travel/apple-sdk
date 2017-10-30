//
//  TKTrip.h
//  TravelKit
//
//  Created by Michal Zelinka on 25/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TKDirectionTransportMode) {
	TKDirectionTransportModeUnknown = 0,
	TKDirectionTransportModeWalk,
	TKDirectionTransportModeCar,
	TKDirectionTransportModeFlight,
	TKDirectionTransportModeBike,
	TKDirectionTransportModeBus,
	TKDirectionTransportModeTrain,
	TKDirectionTransportModeBoat,
}; // ABI-EXPORTED

typedef NS_ENUM(NSUInteger, TKDirectionTransportType) {
	TKDirectionTransportTypeFastest = 0,
	TKDirectionTransportTypeShortest,
	TKDirectionTransportTypeEconomic,
}; // ABI-EXPORTED

typedef NS_OPTIONS(NSUInteger, TKTransportAvoidOption) {
	TKTransportAvoidOptionNone        = (0),
	TKTransportAvoidOptionTolls       = (1 << 0),
	TKTransportAvoidOptionHighways    = (1 << 1),
	TKTransportAvoidOptionFerries     = (1 << 2),
	TKTransportAvoidOptionUnpaved     = (1 << 3),
}; // ABI-EXPORTED

typedef NS_ENUM(NSUInteger, TKTripPrivacy) {
	TKTripPrivacyPrivate = 0,
	TKTripPrivacyShareable,
	TKTripPrivacyPublic,
}; // ABI-EXPORTED

typedef NS_OPTIONS(NSUInteger, TKTripRights) {
	TKTripRightsNoRights    = (0),
	TKTripRightsEdit        = (1 << 0),
	TKTripRightsManage      = (1 << 1),
	TKTripRightsDelete      = (1 << 2),
	TKTripRightsAllRights   = TKTripRightsEdit | TKTripRightsManage | TKTripRightsDelete,
}; // ABI-EXPORTED


///////////////
#pragma mark - Trip Day Item model
///////////////


@interface TKTripDayItem : NSObject

/// Item ID
@property (nonatomic, copy) NSString *itemID;

@property (nonatomic, strong, nullable) NSNumber *startTime;
@property (nonatomic, strong, nullable) NSNumber *duration;
@property (nonatomic, copy, nullable) NSString *note;

@property (nonatomic) TKDirectionTransportMode transportMode;
@property (atomic) TKDirectionTransportType transportType;
@property (atomic) TKTransportAvoidOption transportAvoid;
@property (nonatomic, strong, nullable) NSNumber *transportStartTime;
@property (nonatomic, strong, nullable) NSNumber *transportDuration;
@property (nonatomic, copy, nullable) NSString *transportNote;
@property (nonatomic, copy, nullable) NSString *transportPolyline;

+ (instancetype)itemForItemWithID:(NSString *)itemID;

@end


///////////////
#pragma mark - Trip Day model
///////////////


@interface TKTripDay : NSObject

/// Array of Item IDs
@property (nonatomic, copy, readonly) NSArray<NSString *> *itemIDs;

/// Array of Item objects
@property (nonatomic, strong) NSMutableArray<TKTripDayItem *> *items;

/// String with a note
@property (nonatomic, copy) NSString *note;

@end


///////////////
#pragma mark - Trip model
///////////////


@interface TKTrip : NSObject

@property (nonatomic, readonly) NSString *ID NS_SWIFT_NAME(ID);
@property (nonatomic, copy) NSString *name;
@property (nonatomic, readonly) NSUInteger version;
@property (nonatomic, strong, nullable) NSDate *dateStart;
@property (nonatomic, strong, readonly, nullable) NSDate *lastUpdate;
@property (nonatomic, assign) BOOL isTrashed;

/** Array of Trip Day objects */
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

// Day workers
- (void)addNewDay;
- (void)removeDay:(TKTripDay *)day;

// Item workers
- (void)addItem:(NSString *)itemID toDay:(NSUInteger)dayIndex;
- (void)removeItem:(NSString *)itemID fromDay:(NSUInteger)dayIndex;
- (void)removeItem:(NSString *)itemID;

- (NSArray<TKTripDayItem *> *)occurrencesOfItemWithID:(NSString *)itemID;

// Information providers
- (NSSet<NSString *> *)itemIDsInTrip;
- (BOOL)containsItemWithID:(NSString *)itemID;
- (NSArray<NSNumber *> *)indexesOfDaysContainingItemWithID:(NSString *)itemID;
- (BOOL)isEmpty;

// Manipulation methods
- (BOOL)moveDayAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex;
- (BOOL)moveActivityAtDay:(NSUInteger)dayIndex withIndex:(NSUInteger)activityIndex toDay:(NSUInteger)destDayIndex withIndex:(NSUInteger)destIndex;
- (BOOL)removeActivityAtDay:(NSUInteger)dayIndex withIndex:(NSUInteger)activityIndex;

@end


///////////////
#pragma mark - Trip info
///////////////


@interface TKTripInfo : NSObject

@property (nonatomic, copy, readonly) NSString *ID NS_SWIFT_NAME(ID);
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, readonly) NSUInteger version;

@property (nonatomic, strong, readonly, nullable) NSDate *startDate;
@property (nonatomic, strong, readonly, nullable) NSDate *lastUpdate;

@property (nonatomic, readonly) NSUInteger daysCount;
@property (nonatomic, readonly) BOOL isTrashed;

@end


NS_ASSUME_NONNULL_END
