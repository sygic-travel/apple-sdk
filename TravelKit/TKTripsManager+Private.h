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


@interface TKTripsManager ()

#pragma mark - Methods

// Trip database manipulation
- (BOOL)insertTrip:(TKTrip *)trip forUserWithID:(NSString *)userID;
- (BOOL)updateTrip:(TKTrip *)trip forUserWithID:(NSString *)userID;

// Trip archiving & deletion
- (BOOL)archiveTripWithID:(NSString *)tripID;
- (BOOL)restoreTripWithID:(NSString *)tripID;
- (BOOL)deleteTripWithID:(NSString *)tripID;

// Datatabse workers
- (BOOL)changeTripWithID:(NSString *)originalID toID:(NSString *)newID;
- (void)saveTripInfo:(TKTripInfo *)trip;

//// API fetching
//- (void)fetchTripWithID:(NSString *)tripID completion:(void (^)(TKTrip *))completion;

@end
