//
//  TKToursManager.h
//  TravelKit
//
//  Created by Michal Zelinka on 19/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TravelKit/TKTour.h>
#import <TravelKit/TKToursQuery.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKToursManager : NSObject

///---------------------------------------------------------------------------------------
/// @name Shared interface
///---------------------------------------------------------------------------------------

/// Shared Tours managing instance.
@property (class, readonly, strong) TKToursManager *sharedManager;

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

///---------------------------------------------------------------------------------------
/// @name Tours working queries
///---------------------------------------------------------------------------------------

/**
 Returns a collection of `TKTour` objects for the given query object.

 This method is good for fetching Tours to use for lists and other batch uses.

 @param query `TKToursQuery` object containing the desired attributes to look for.
 @param completion Completion block called on success or error.

 @note Experimental.
 */
- (void)toursForQuery:(TKToursQuery *)query
	completion:(void (^)(NSArray<TKTour *>  * _Nullable places, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
