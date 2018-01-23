//
//  TKUserSettings+Private.h
//  TravelKit
//
//  Created by Michal Zelinka on 14/02/2014.
//  Copyright (c) 2014 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


#pragma mark - Persistent User Settings


@interface TKUserSettings : NSObject

// App settings
@property (nonatomic, copy, nullable) NSDictionary *userCredentials;
@property (nonatomic, assign) NSTimeInterval changesTimestamp;
@property (atomic, readonly) NSInteger launchNumber;
@property (nonatomic, readonly, nullable) NSDate *installationDate;
@property (nonatomic, copy) NSString *uniqueID;

@property (class, readonly, strong) TKUserSettings *sharedSettings;
@property (class, readonly, strong) NSUserDefaults *sharedDefaults;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;

/**
 Commit settings into system preferences
 */
- (void)commit;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
