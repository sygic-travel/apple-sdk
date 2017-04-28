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
 Enum identifying a basic type of `TKMedium`.
 */
typedef NS_ENUM(NSUInteger, TKMediumType) {
	/// Unknown type – fallback value.
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
 Enum identifying a suitability of `TKMedium` for some basic use cases.
 */
typedef NS_OPTIONS(NSUInteger, TKMediumSuitability) {
	/// No known suitability (default value).
	TKMediumSuitabilityNone           = 0,
	/// Medium suitable for square presentation.
	TKMediumSuitabilitySquare         = 1 << 0,
	/// Medium suitable for portrait presentation.
	TKMediumSuitabilityPortrait       = 1 << 1,
	/// Medium suitable for landscape presentation.
	TKMediumSuitabilityLandscape      = 1 << 2,
	/// Medium suitable for _square_ video preview.
	TKMediumSuitabilityVideoPreview   = 1 << 3,
};

NS_ASSUME_NONNULL_BEGIN

/**
 Entity preserving information about a remote displayable Medium, f.e. an Image or a Video.
 */
@interface TKMedium : NSObject

///---------------------------------------------------------------------------------------
/// @name Properties
///---------------------------------------------------------------------------------------

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
