//
//  TKMedium.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#define TKMEDIUM_SIZE_PLACEHOLDER   "__SIZE__"


typedef NS_ENUM(NSUInteger, TKMediumType) {
	TKMediumTypeUnknown      = 0,
	TKMediumTypeImage        = 1,
	TKMediumTypeVideo        = 2,
	TKMediumTypeImage360     = 3,
	TKMediumTypeVideo360     = 4,
};

typedef NS_OPTIONS(NSUInteger, TKMediumSuitability) {
	TKMediumSuitabilityNone           = 0,
	TKMediumSuitabilitySquare         = 1,
	TKMediumSuitabilityPortrait       = 2,
	TKMediumSuitabilityLandscape      = 4,
	TKMediumSuitabilityVideoPreview   = 8,
};

NS_ASSUME_NONNULL_BEGIN

@interface TKMedium : NSObject

@property (nonatomic, copy) NSString *ID NS_SWIFT_NAME(ID);
@property (atomic) TKMediumType type;
@property (atomic) TKMediumSuitability suitability;
@property (atomic) CGFloat width, height;
@property (nonatomic, copy, nullable) NSString *title, *author, *provider, *license;
@property (nonatomic, strong, nullable) NSURL *URL, *previewURL;
@property (nonatomic, strong, nullable) NSURL *originURL, *authorURL;
@property (nonatomic, copy, nullable) NSString *externalID;

- (instancetype)initFromResponse:(NSDictionary *)response;

@end

NS_ASSUME_NONNULL_END
