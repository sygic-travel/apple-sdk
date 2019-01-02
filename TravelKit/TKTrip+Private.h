//
//  TKTrip+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 25/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKTrip.h"

NS_ASSUME_NONNULL_BEGIN

#define LOCAL_TRIP_PREFIX         "*"


///-----------------------------------------------------------------------------
#pragma mark - Trip definitions
///-----------------------------------------------------------------------------


/**
 Enum indicating Trip privacy state.
 */
typedef NS_ENUM(NSUInteger, TKTripPrivacy) {
	TKTripPrivacyPrivate = 0, /// Private Trip.
	TKTripPrivacyShareable, /// Sharable Trip. Can be shared via URL.
	TKTripPrivacyPublic, /// Public Trip. May be joined by other users.
}; // ABI-EXPORTED

/**
 Enum indicating Trip rights.
 */
typedef NS_OPTIONS(NSUInteger, TKTripRights) {
	TKTripRightsNoRights    = (0), /// No rights.
	TKTripRightsEdit        = (1 << 0), /// Editing rights. Allows editing all properties not mentioned below.
	TKTripRightsManage      = (1 << 1), /// Managing rights. Allows managing the privacy setting and Trip collaborators.
	TKTripRightsDelete      = (1 << 2), /// Deleting rights. Allows moving the Trip to the Trash.
	TKTripRightsAllRights   = TKTripRightsEdit | TKTripRightsManage | TKTripRightsDelete,
}; // ABI-EXPORTED


///-----------------------------------------------------------------------------
#pragma mark - Trip Day Item model
///-----------------------------------------------------------------------------


@interface TKTripDayItem ()

@property (nonatomic, copy, nullable) NSString *transportRouteID;

// Handled initializers
- (instancetype)initFromResponse:(NSDictionary *)dict;
- (instancetype)initFromDatabase:(NSDictionary *)dict;

@end


///-----------------------------------------------------------------------------
#pragma mark - Trip Day model
///-----------------------------------------------------------------------------


@interface TKTripDay ()

// Handled initializers
- (instancetype)initFromResponse:(NSDictionary *)dict;
- (instancetype)initFromDatabase:(NSDictionary *)dict
					   itemDicts:(NSArray<NSDictionary *> *)itemDicts;

@end


///-----------------------------------------------------------------------------
#pragma mark - Trip model
///-----------------------------------------------------------------------------


@interface TKTrip ()

@property (nonatomic, strong, readwrite, nullable) NSDate *lastUpdate;
@property (nonatomic, assign) BOOL changed;

@property (nonatomic, assign) TKTripPrivacy privacy;
@property (nonatomic, assign) TKTripRights rights;
@property (nonatomic, copy, nullable) NSString *ownerID; // Trip owner and Local record holder

@property (nonatomic, readonly) BOOL isEditable;
@property (nonatomic, readonly) BOOL isManageable;
@property (nonatomic, readonly) BOOL isDeletable;

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

@end


///-----------------------------------------------------------------------------
#pragma mark - Trip info
///-----------------------------------------------------------------------------


@interface TKTripInfo ()

@property (nonatomic, copy) NSString *ownerID;

@property (nonatomic, readonly) BOOL isEditable;
@property (nonatomic, readonly) BOOL isManageable;
@property (nonatomic, readonly) BOOL isDeletable;

@property (nonatomic, assign) TKTripPrivacy privacy;
@property (nonatomic, assign) TKTripRights rights;

@property (nonatomic, assign) BOOL changed;

- (instancetype)initFromDatabase:(NSDictionary *)dict;

@end


///-----------------------------------------------------------------------------
#pragma mark - Trip conflict model
///-----------------------------------------------------------------------------


@interface TKTripConflict ()

- (instancetype)initWithLocalTrip:(TKTrip *)localTrip remoteTrip:(TKTrip *)remoteTrip
                 remoteTripEditor:(NSString *)remoteTripEditor remoteTripUpdateDate:(NSDate *)remoteTripUpdateDate;

@end


///-----------------------------------------------------------------------------
#pragma mark - Trip collaborator model
///-----------------------------------------------------------------------------


@interface TKTripCollaborator : NSObject

@property (nonatomic, strong) NSNumber *ID;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, strong, nullable) NSURL *photoURL;
@property (atomic) BOOL accepted;
@property (atomic) BOOL hasWriteAccess;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end


///-----------------------------------------------------------------------------
#pragma mark - Trip template model
///-----------------------------------------------------------------------------


@interface TKTripTemplate : NSObject

@property (nonatomic, strong) NSNumber *ID;
@property (nonatomic, strong) TKTrip *trip;
@property (nonatomic, copy, nullable) NSString *perex;
@property (nonatomic, strong, nullable) NSNumber *duration;

- (instancetype)initFromResponse:(NSDictionary *)dictionary;
- (NSArray<NSString *> *)allItemIDs;

@end

NS_ASSUME_NONNULL_END
