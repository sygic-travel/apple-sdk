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

@interface TKTripsManager : NSObject

#pragma mark - Shared instance

///---------------------------------------------------------------------------------------
/// @name Shared interface
///---------------------------------------------------------------------------------------

/// Shared Trips managing instance.
@property (class, readonly, strong) TKTripsManager *sharedManager;

+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

#pragma mark - Trip getters

///---------------------------------------------------------------------------------------
/// @name Trips working queries
///---------------------------------------------------------------------------------------

- (nullable TKTrip *)tripWithID:(NSString *)tripID;
- (nullable TKTripInfo *)infoForTripWithID:(NSString *)tripID;

// Trip getters
- (NSArray<TKTrip *> *)allTrips;

// Filtered Trip getters
- (NSArray<TKTripInfo *> *)upcomingTripInfos;
- (NSArray<TKTripInfo *> *)pastTripInfos;
- (NSArray<TKTripInfo *> *)futureTripInfos;
- (NSArray<TKTripInfo *> *)tripInfosInYear:(NSInteger)year;
- (NSArray<TKTripInfo *> *)tripInfosWithNoDate;
- (NSArray<TKTripInfo *> *)trashedTripInfos;
- (NSArray<NSString *> *)yearsOfTrips;

// Trip savers
- (BOOL)saveTrip:(TKTrip *)trip;

@end

NS_ASSUME_NONNULL_END
