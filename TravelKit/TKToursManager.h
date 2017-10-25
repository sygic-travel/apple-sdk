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

@property (class, readonly, strong) TKToursManager *sharedManager;

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (void)toursForQuery:(TKToursQuery *)query
	completion:(void (^)(NSArray<TKTour *>  * _Nullable places, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
