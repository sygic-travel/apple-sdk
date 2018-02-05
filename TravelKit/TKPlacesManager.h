//
//  TKPlacesManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 23/05/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <TravelKit/TKPlace.h>
#import <TravelKit/TKPlacesQuery.h>
#import <TravelKit/TKMedium.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKPlacesManager : NSObject

///---------------------------------------------------------------------------------------
/// @name Shared interface
///---------------------------------------------------------------------------------------

/// Shared Places managing instance.
@property (class, readonly, strong) TKPlacesManager *sharedManager;

+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

///---------------------------------------------------------------------------------------
/// @name Place working queries
///---------------------------------------------------------------------------------------

/**
 Returns a collection of `TKPlace` objects for the given query object.

 This method is good for fetching Places to use for lists, map annotations and other batch uses.

 @param query `TKPlacesQuery` object containing the desired attributes to look for.
 @param completion Completion block called on success or error.
 */
- (void)placesForQuery:(TKPlacesQuery *)query
	completion:(void (^)(NSArray<TKPlace *>  * _Nullable places, NSError * _Nullable error))completion;

/**
 Returns a collection of `TKPlace` objects for the given IDs.

 @param placeIDs Array of strings matching desired Place IDs.
 @param completion Completion block called on success or error.
 */
- (void)placesWithIDs:(NSArray<NSString *> *)placeIDs
	completion:(void (^)(NSArray<TKPlace *> * _Nullable places, NSError * _Nullable error))completion;

/**
 Returns a Detailed `TKPlace` object for the given global Place identifier.

 This method is good for fetching further Place information to use f.e. on Place Detail screen.

 @param placeID Global identifier of the desired Place.
 @param completion Completion block called on success or error.
 */
- (void)detailedPlaceWithID:(NSString *)placeID
	completion:(void (^)(TKPlace * _Nullable place, NSError * _Nullable error))completion;

///---------------------------------------------------------------------------------------
/// @name Place working queries
///---------------------------------------------------------------------------------------

/**
 Returns a collection of `TKMedium` objects for the given global Place identifier.

 This method is used to fetch all Place media to be used f.e. for Gallery screen.

 @param placeID Global identifier of the desired Place.
 @param completion Completion block called on success or error.
 */
- (void)mediaForPlaceWithID:(NSString *)placeID
	completion:(void (^)(NSArray<TKMedium *> * _Nullable media, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
