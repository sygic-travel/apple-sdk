//
//  TKTrip+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 25/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKTrip.h"

#define LOCAL_TRIP_PREFIX         "*"
#define GENERIC_TRIP_NAME         @"My Trip"

// Note: Trip name definitions need to be updated in .m to be translated properly.


///////////////
#pragma mark - Trip Day Item model
///////////////


@interface TKTripDayItem ()

// Handled initializers
- (instancetype)initFromResponse:(NSDictionary *)dict;
- (instancetype)initFromDatabase:(NSDictionary *)dict;

@end


///////////////
#pragma mark - Trip Day model
///////////////


@interface TKTripDay ()

// Set of (hopefully set) properties
@property (atomic) NSUInteger dayIndex;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, copy) NSString *dayName;
@property (nonatomic, copy) NSString *dayNumber;
@property (nonatomic, copy) NSString *shortDateString;

// Handled initializers
- (instancetype)initFromResponse:(NSDictionary *)dict;
- (instancetype)initFromDatabase:(NSDictionary *)dict
					   itemDicts:(NSArray<NSDictionary *> *)itemDicts;

// Test for presence
- (BOOL)containsItemWithID:(NSString *)itemID;

// Insertion & removal methods
- (void)addItemWithID:(NSString *)itemID;
- (void)insertItemWithID:(NSString *)itemID atIndex:(NSUInteger)index;
- (void)removeItemWithID:(NSString *)itemID;

// Helpers
- (NSString *)formattedDayName;

@end


///////////////
#pragma mark - Trip model
///////////////


@interface TKTrip ()

@property (nonatomic, assign) TKTripPrivacy privacy;
@property (nonatomic, assign) TKTripRights rights;
@property (nonatomic, copy) NSString *ownerID, *userID; // Trip owner and Local record holder
@property (nonatomic, assign) BOOL changed;

@property (nonatomic, readonly) BOOL isEditable;
@property (nonatomic, readonly) BOOL isManageable;
@property (nonatomic, readonly) BOOL isDeletable;

// Dirty flag for synchronization
@property (atomic, assign) BOOL changedSinceLastSynchronization;

/**
 * Init object from dictionary taken from API
 *
 * @param dict Object from API
 * @return Object with fully filled information
 */
- (instancetype)initFromResponse:(NSDictionary *)dict;

/**
 * Init object from dictionary taken from SQL
 *
 * @param dict Trip dictionary from database
 * @param dayItemDicts Day Item dictionary objects from database
 * @return Trip object with filled information
 */
- (instancetype)initFromDatabase:(NSDictionary *)dict
                        dayDicts:(NSArray<NSDictionary *> *)dayDicts
                    dayItemDicts:(NSArray<NSDictionary *> *)dayItemDicts;

// Serialization methods
- (NSDictionary *)asRequestDictionary;

// Returns Trip day object with additional properties set
- (TKTripDay *)dayWithDateAtIndex:(NSUInteger)index;

// Duration string
- (NSString *)formattedDuration;

@end


///////////////
#pragma mark - Trip info
///////////////


@interface TKTripInfo ()

@property (nonatomic, copy) NSString *ownerID, *userID;

@property (nonatomic, readonly) BOOL isEditable;
@property (nonatomic, readonly) BOOL isManageable;
@property (nonatomic, readonly) BOOL isDeletable;

@property (nonatomic, assign) TKTripPrivacy privacy;
@property (nonatomic, assign) TKTripRights rights;

@property (nonatomic, assign) BOOL changed;

- (instancetype)initFromDatabase:(NSDictionary *)dict;

@end


///////////////
#pragma mark - Trip collaborator model
///////////////


@interface TKTripCollaborator : NSObject

@property (nonatomic, strong) NSNumber *ID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, strong) NSURL *photoURL;
@property (atomic) BOOL accepted;
@property (atomic) BOOL hasWriteAccess;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end


///////////////
#pragma mark - Trip template model
///////////////


@interface TKTripTemplate : NSObject

@property (nonatomic, strong) NSNumber *ID;
@property (nonatomic, strong) TKTrip *trip;
@property (nonatomic, copy) NSString *perex;
@property (nonatomic, strong) NSNumber *duration;

- (instancetype)initFromResponse:(NSDictionary *)dictionary;
- (NSArray<NSString *> *)allItemIDs;

@end
