//
//  TKCollection.h
//  TravelKit
//
//  Created by Michal Zelinka on 01/11/18.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TravelKit/TKPlace.h>

NS_HEADER_AUDIT_BEGIN(nullability, sendability)

NS_SWIFT_SENDABLE
@interface TKCollection : NSObject

@property (nonatomic, copy, readonly) NSNumber *ID NS_SWIFT_NAME(ID);
@property (nonatomic, copy, nullable, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *fullName;
@property (nonatomic, copy, nullable, readonly) NSString *perex;
@property (nonatomic, copy, readonly) NSString *parentPlaceID;

@property (nonatomic, copy, readonly) NSArray<TKPlaceTag *> *tags;
@property (nonatomic, copy, readonly) NSArray<NSString *> *placeIDs;

@end

NS_HEADER_AUDIT_END(nullability, sendability)
