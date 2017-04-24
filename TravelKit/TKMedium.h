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


/**
 Enum identifying a `TKMedium` type.
 */
typedef NS_ENUM(NSUInteger, TKMediumType) {
	/// Unknown type – fallback value
	TKMediumTypeUnknown      = 0,
	/// Image type.
	TKMediumTypeImage        = 1,
	/// Video type.
	TKMediumTypeVideo        = 2,
	/// 360° image type.
	TKMediumTypeImage360     = 3,
	/// 360° video type.
	TKMediumTypeVideo360     = 4,
};

/**
 Enum identifying a suitability of `TKMedium` for basic use cases.
 */
typedef NS_OPTIONS(NSUInteger, TKMediumSuitability) {
	/// No known suitability (default value).
	TKMediumSuitabilityNone           = 0,
	/// Medium suitable for square presentation.
	TKMediumSuitabilitySquare         = 1,
	/// Medium suitable for portrait presentation.
	TKMediumSuitabilityPortrait       = 2,
	/// Medium suitable for landscape presentation.
	TKMediumSuitabilityLandscape      = 4,
	/// Medium suitable for video preview.
	TKMediumSuitabilityVideoPreview   = 8,
};

NS_ASSUME_NONNULL_BEGIN

/**
 Entity preserving information about a remote Medium, f.e. an image or a video.
 */
@interface TKMedium : NSObject

/// Global identifier.
@property (nonatomic, copy) NSString *ID NS_SWIFT_NAME(ID);
/// Medium type.
@property (atomic) TKMediumType type;
/// Medium suitability.
@property (atomic) TKMediumSuitability suitability;
/// Medium width, if available.
@property (atomic) CGFloat width;
/// Medium height, if available.
@property (atomic) CGFloat height;
/// Medium title.
@property (nonatomic, copy, nullable) NSString *title;
/// Medium author, usually full name or similar.
@property (nonatomic, copy, nullable) NSString *author;
/// Medium provider.
@property (nonatomic, copy, nullable) NSString *provider;
/// Medium license name.
@property (nonatomic, copy, nullable) NSString *license;
/// Medium source URL.
@property (nonatomic, strong, nullable) NSURL *URL;
/// Medium source Preview URL.
@property (nonatomic, strong, nullable) NSURL *previewURL;
/// Origin URL of the Medium.
@property (nonatomic, strong, nullable) NSURL *originURL;
/// URL link to a Medium author.
@property (nonatomic, strong, nullable) NSURL *authorURL;
/// External ID of the Medium.
@property (nonatomic, copy, nullable) NSString *externalID;

@end

NS_ASSUME_NONNULL_END
