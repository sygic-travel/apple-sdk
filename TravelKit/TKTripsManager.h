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

/**
  A method used to get an info of all locally stored Trips.

 @return An array of `TKTripInfo` objects.
 */
- (NSArray<TKTripInfo *> *)allTripInfos;

/**
  A method used to get an info of all upcoming Trips.

 @return An array of `TKTripInfo` objects.
 */
- (NSArray<TKTripInfo *> *)upcomingTripInfos;

/**
  A method used to get an info of all past Trips.

 @return An array of `TKTripInfo` objects.
 */
- (NSArray<TKTripInfo *> *)pastTripInfos;

/**
  A method used to get an info of all future Trips.

 @return An array of `TKTripInfo` objects.
 */
- (NSArray<TKTripInfo *> *)futureTripInfos;

/**
  A method used to get an info of all Trips in a specific year.

 @return An array of `TKTripInfo` objects.
 */
- (NSArray<TKTripInfo *> *)tripInfosInYear:(NSInteger)year;

/**
  A method used to get an info of all Trips with no date set.

 @return An array of `TKTripInfo` objects.
 */
- (NSArray<TKTripInfo *> *)unscheduledTripInfos;

/**
  A method used to get an info of all Trips marked as deleted.

 @return An array of `TKTripInfo` objects.
 */
- (NSArray<TKTripInfo *> *)deletedTripInfos;

/**
 A method used to get an info of Trips planned in a specified date range.

 @param startDate A start date to filter the Trips with. Optional.
 @param endDate An end date to filter the Trips with. Optional.
 @param includeOverlapping A flag indicating whether the Trips which overlap
        the given bounds in any way should be included as well.
 @return An array of `TKTripInfo` objects.
 */
- (NSArray<TKTripInfo *> *)tripInfosForStartDate:(nullable NSDate *)startDate
	endDate:(nullable NSDate *)endDate includeOverlapping:(BOOL)includeOverlapping;

/**
  A method used to get a list of years where some Trip is planned.

 @return An array of `NSNumber`s representing years with some Trip planned.
 */
- (NSArray<NSNumber *> *)yearsOfActiveTrips;

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

