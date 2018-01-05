//
//  TKTrip+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 25/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKTrip.h"

#define LOCAL_TRIP_PREFIX         "*"


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

// Handled initializers
- (instancetype)initFromResponse:(NSDictionary *)dict;
- (instancetype)initFromDatabase:(NSDictionary *)dict
					   itemDicts:(NSArray<NSDictionary *> *)itemDicts;

@end


///////////////
#pragma mark - Trip model
///////////////


@interface TKTrip ()

@property (nonatomic, assign) TKTripPrivacy privacy;
@property (nonatomic, assign) TKTripRights rights;
@property (nonatomic, copy) NSString *ownerID; // Trip owner and Local record holder
@property (nonatomic, assign) BOOL changed;

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


///////////////
#pragma mark - Trip info
///////////////


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
