//
//  TravelKit.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for TravelKit.
FOUNDATION_EXPORT double TravelKitVersionNumber;

//! Project version string for TravelKit.
FOUNDATION_EXPORT const unsigned char TravelKitVersionString[];

#import <TravelKit/TKPlace.h>
#import <TravelKit/TKPlacesQuery.h>
#import <TravelKit/TKReference.h>
#import <TravelKit/TKMedium.h>
#import <TravelKit/TKMapRegion.h>
#import <TravelKit/TKPlacesQuery.h>
#import <TravelKit/Foundation+TravelKit.h>
#import <TravelKit/NSObject+Parsing.h>

typedef NS_ENUM(NSUInteger, TKErrorCode) {
	TKErrorCodePlacesFailed = 100,
	TKErrorCodePlaceDetailsFailed = 200,
	TKErrorCodePlaceMediaFailed = 300,
};


@interface TravelKit : NSObject

+ (void)placesForQuery:(TKPlacesQuery *)query
	completion:(void (^)(NSArray<TKPlace *> *places, NSError *error))completion;

+ (void)detailedPlaceWithID:(NSString *)placeID
	completion:(void (^)(TKPlace *place, NSError *error))completion;

+ (void)mediaForPlaceWithID:(NSString *)placeID
	completion:(void (^)(NSArray<TKMedium *> *media, NSError *error))completion;

@end
