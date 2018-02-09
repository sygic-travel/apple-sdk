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
- (NSArray<TKTripInfo *> *)allTripInfos;
- (NSArray<TKTripInfo *> *)upcomingTripInfos;
- (NSArray<TKTripInfo *> *)pastTripInfos;
- (NSArray<TKTripInfo *> *)futureTripInfos;
- (NSArray<TKTripInfo *> *)tripInfosInYear:(NSInteger)year;
- (NSArray<TKTripInfo *> *)unscheduledTripInfos;
- (NSArray<TKTripInfo *> *)deletedTripInfos;

- (NSArray<NSNumber *> *)yearsOfActiveTrips;

//async fun getTrip(from: DateTime?, to: DateTime?, includeOverlapping: Boolean = true): TripInfo[]
//async fun emptyTripsTrash(): void

#pragma mark - Trip saving

/**
 A method used to save a locally created or modified Trip.

 @param trip `TKTrip` instance to save.
 @return A boolean value indicating whether the saving operation was successful.
 */
- (BOOL)saveTrip:(TKTrip *)trip;

/**
 A method used to fetch a specific Trip from the API.

 @param tripID ID of the Trip to fetch.
 @param completion Fetched Trip object or an error.
 */
- (void)fetchTripWithID:(NSString *)tripID completion:(void (^)(TKTrip *_Nullable, NSError *_Nullable))completion;

/**
 A method used to permanently wipe the Trips marked as deleted.

 @param completion Completion block with a result or an error.
 */
- (void)emptyTrashWithCompletion:(void (^)(NSArray<NSString *> *_Nullable tripIDs, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END

