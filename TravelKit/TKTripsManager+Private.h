//
//  TKTripsManager+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 30/10/2017.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TravelKit/TKTripsManager.h>

#import "TKTrip+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface TKTripsManager ()

#pragma mark - Methods

// Trip database manipulation
- (BOOL)insertTrip:(TKTrip *)trip;
- (BOOL)storeTrip:(TKTrip *)trip;
- (BOOL)deleteTripWithID:(NSString *)tripID;

// Datatabse workers
- (BOOL)changeTripWithID:(NSString *)originalID toID:(NSString *)newID;
- (void)saveTripInfo:(TKTripInfo *)trip;

// Synchronization
- (NSArray<TKTripInfo *> *)changedTripInfos;

@end

NS_ASSUME_NONNULL_END
