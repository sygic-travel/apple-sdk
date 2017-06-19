//
//  TKToursManager+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 19/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TravelKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKToursManager : NSObject

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)sharedManager;

- (void)toursForQuery:(TKToursQuery *)query
	completion:(void (^)(NSArray<TKTour *>  * _Nullable places, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
