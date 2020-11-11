//
//  TKMedium.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


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
 Enum identifying a video resolution of `TKMedium`.
 */
typedef NS_ENUM(NSUInteger, TKMediumVideoResolution) {
	/// 720p resolution.
	TKMediumVideoResolution720p   NS_SWIFT_NAME(res720p)  = 720,
	/// 1080p resolution.
	TKMediumVideoResolution1080p  NS_SWIFT_NAME(res1080p) = 1080,
	/// 4K resolution.
	TKMediumVideoResolution4K     NS_SWIFT_NAME(res4K)    = 2160,
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

/**
 Enum identifying content mode of the requested `TKMedium`.
 */
typedef NS_ENUM(NSUInteger, TKMediumContentMode) {
	/// Crop the image. `200x200` will be returned with the exact size, filling the given
	/// dimensions so the longer image dimension will be cropped.
    ///
    /// @note Works as `UIViewContentModeScaleAspectFill` with bounds clipping.
	TKMediumContentModeCrop         = 0,
	/// Don't crop the image and fit inside the given dimensions.
	///
	/// For `400x400`, the longer image dimension will be 400px, the other might be shorter.
    ///
    /// @note Works as `UIViewContentModeScaleAspectFit` without clipping.
	TKMediumContentModeNoCropFit    = 1,
	/// Don't crop the image and fill inside the given dimensions.
	///
	/// For `400x400`, the shorter image dimension will be 400px, the other might be longer.
    ///
    /// @note Works as `UIViewContentModeScaleAspectFill` without clipping.
	TKMediumContentModeNoCropFill   = 2,
};

NS_ASSUME_NONNULL_BEGIN

/**
 Entity preserving information about a remote displayable Medium. An Image or a Video.
 */
@interface TKMedium : NSObject

///---------------------------------------------------------------------------------------
/// @name Properties
///---------------------------------------------------------------------------------------

/// Global identifier.
@property (nonatomic, copy, readonly) NSString *ID NS_SWIFT_NAME(ID);

/// Medium type.
@property (atomic, readonly) TKMediumType type;

/// Medium suitability.
@property (atomic, readonly) TKMediumSuitability suitability;

/// Medium width, if available.
@property (atomic, readonly) CGFloat width;

/// Medium height, if available.
@property (atomic, readonly) CGFloat height;

///---------------------------------------------------------------------------------------
/// @name Attribution
///---------------------------------------------------------------------------------------

/// Medium title.
@property (nonatomic, copy, nullable, readonly) NSString *title;

/// Medium author, usually full name or similar.
@property (nonatomic, copy, nullable, readonly) NSString *author;

/// Medium provider.
@property (nonatomic, copy, nullable, readonly) NSString *provider;

/// Medium license name.
@property (nonatomic, copy, nullable, readonly) NSString *license;

/// Unmodified Medium URL.
///
/// This URL links the original Medium file.
///
/// @note To get a URL for different dimensions, use `-displayableImageURLForSize:contentMode:`.
@property (nonatomic, strong, readonly) NSURL *URL;

/// URL for the original source of the image.
@property (nonatomic, strong, nullable, readonly) NSURL *originURL;

/// URL link to a Medium author.
@property (nonatomic, strong, nullable, readonly) NSURL *authorURL;

/// External ID of the Medium.
@property (nonatomic, copy, nullable, readonly) NSString *externalID;

///---------------------------------------------------------------------------------------
/// @name Helping methods
///---------------------------------------------------------------------------------------

/**
 Method for getting an URL to a Medium image with a given size.

 @param size Desired size of the image.
 @param mode Content mode of the image.
 @return URL for loading the resized image.
 */
- (nullable NSURL *)displayableImageURLForSize:(CGSize)size contentMode:(TKMediumContentMode)mode;
- (nullable NSURL *)displayableImageURLForSize:(CGSize)size;

/**
 Method for getting an URL to a Medium video with a given resolution.

 @param resolution Desired resolution of the video.
 @return URL for video playback.
 */
- (nullable NSURL *)displayableVideoURLForResolution:(TKMediumVideoResolution)resolution;

@end

NS_ASSUME_NONNULL_END
