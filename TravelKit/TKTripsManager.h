//
//  TKTripsManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 30/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TravelKit/TKTrip.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A working manager used to work with `Trip` objects.
 */
@interface TKTripsManager : NSObject

#pragma mark - Shared instance

///---------------------------------------------------------------------------------------
/// @name Shared interface
///---------------------------------------------------------------------------------------

/// Shared Trips managing instance.
@property (class, readonly, strong) TKTripsManager *sharedManager;

+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

///---------------------------------------------------------------------------------------
/// @name Trips working queries
///---------------------------------------------------------------------------------------

#pragma mark - Trip getters

/**
 Main getter method to get a `TKTrip` object.

 @param tripID An ID of a Trip.
 @return Fully-loaded `TKTrip` object.
 */
- (nullable TKTrip *)tripWithID:(NSString *)tripID;

/**
 Method used to get a light `TKTripInfo` object.

 @param tripID An ID of a Trip.
 @return `TKTripInfo` object.
 */
- (nullable TKTripInfo *)infoForTripWithID:(NSString *)tripID;

#pragma mark - Trip collection getters

/**
 A method used to get all locally stored Trips.

 @return An array of `TKTrip` objects.
 */
- (NSArray<TKTrip *> *)allTrips;

// Filtered Trip getters
- (NSArray<TKTripInfo *> *)upcomingTripInfos;
- (NSArray<TKTripInfo *> *)pastTripInfos;
- (NSArray<TKTripInfo *> *)futureTripInfos;
- (NSArray<TKTripInfo *> *)tripInfosInYear:(NSInteger)year;
- (NSArray<TKTripInfo *> *)tripInfosWithNoDate;
- (NSArray<TKTripInfo *> *)trashedTripInfos;
- (NSArray<NSString *> *)yearsOfTrips;

#pragma mark - Trip saving

/**
 A method used to save a locally created or modified Trip.

 @param trip `TKTrip` instance to save.
 @return A boolean value indicating whether the saving operation was successful.
 */
- (BOOL)saveTrip:(TKTrip *)trip;

@end

NS_ASSUME_NONNULL_END
