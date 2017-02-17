//
//  TKReference.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKReference : NSObject

@property (atomic) NSUInteger ID NS_SWIFT_NAME(ID);
@property (nonatomic, copy, nullable) NSString *itemID;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *type;
@property (nonatomic, copy, nullable) NSString *supplier;
@property (nonatomic, copy, nullable) NSNumber *price;
@property (nonatomic, copy, nullable) NSString *languageID;
@property (nonatomic, copy, nullable) NSURL *onlineURL;
@property (nonatomic, copy, nullable) NSArray<NSString *> *flags;
@property (atomic) NSInteger priority;
@property (nonatomic, copy, readonly) NSString *iconName;

- (instancetype)initFromResponse:(NSDictionary *)response forItemWithID:(NSString *)itemID;

@end

NS_ASSUME_NONNULL_END
