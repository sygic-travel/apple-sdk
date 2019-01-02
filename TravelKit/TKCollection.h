//
//  TKCollection.h
//  TravelKit
//
//  Created by Michal Zelinka on 01/11/18.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TravelKit/TKPlace.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKCollection : NSObject

@property (nonatomic, strong) NSNumber *ID NS_SWIFT_NAME(ID);
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy) NSString *fullName;
@property (nonatomic, copy, nullable) NSString *perex;
@property (nonatomic, copy) NSString *parentPlaceID;

@property (nonatomic, copy) NSArray<TKPlaceTag *> *tags;
@property (nonatomic, copy) NSArray<NSString *> *placeIDs;

@end

NS_ASSUME_NONNULL_END
