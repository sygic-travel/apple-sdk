//
//  TKMedium.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <TravelKit/NSObject+Parsing.h>
#import "TKMedium+Private.h"

#define TKMEDIUM_SIZE_PLACEHOLDER_API     "{size}"

@implementation TKMedium


- (instancetype)initFromResponse:(NSDictionary *)response
{
	NSString *ID = [response[@"id"] parsedString];

	if (!ID) return nil;

	if (self = [super init])
	{
		// GUID
		_ID = ID;

		// Deny initialization if only placeholder icon received
		if (response[@"is_photo"] && [[response[@"is_photo"] parsedNumber] boolValue] == NO)
			return nil;

		id stored = [response[@"type"] parsedString];
		if ([stored isEqual:@"photo"]) _type = TKMediumTypeImage;
		else if ([stored isEqual:@"video"]) _type = TKMediumTypeVideo;
		else if ([stored isEqual:@"photo360"]) _type = TKMediumTypeImage360;
		else if ([stored isEqual:@"video360"]) _type = TKMediumTypeVideo360;
		else return nil;

		NSURL *url = nil;
		
		stored = [response[@"url"] parsedString];
		if (stored && (url = [NSURL URLWithString:stored])) _URL = url;
		else return nil;

		stored = [response[@"url_template"] parsedString];
		if (stored) stored = [stored stringByReplacingOccurrencesOfString:
			@TKMEDIUM_SIZE_PLACEHOLDER_API withString:@TKMEDIUM_SIZE_PLACEHOLDER];
		if (stored && (url = [NSURL URLWithString:stored])) _templateURL = url;
		else return nil;

		_title = [response[@"attribution"][@"title"] parsedString];
		_author = [response[@"attribution"][@"author"] parsedString];
		_license = [response[@"attribution"][@"license"] parsedString];

		_provider = [response[@"source"][@"provider"] parsedString];
		if ([_provider isEqualToString:@"twobits"]) _provider = @"tripomatic";
		_externalID = [response[@"source"][@"external_id"] parsedString];

		stored = [response[@"attribution"][@"author_url"] parsedString];
		if (stored) _authorURL = [NSURL URLWithString:stored];

		stored = [response[@"attribution"][@"title_url"] parsedString];
		if (stored) _originURL = [NSURL URLWithString:stored];

		_width = [[response[@"original"][@"width"] parsedNumber] integerValue];
		_height = [[response[@"original"][@"height"] parsedNumber] integerValue];

		NSArray *suitability = [response[@"suitability"] parsedArray];

		if ([suitability containsObject:@"square"]) _suitability |= TKMediumSuitabilitySquare;
		if ([suitability containsObject:@"portrait"]) _suitability |= TKMediumSuitabilityPortrait;
		if ([suitability containsObject:@"landscape"]) _suitability |= TKMediumSuitabilityLandscape;
		if ([suitability containsObject:@"video_preview"]) _suitability |= TKMediumSuitabilityVideoPreview;
	}

	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<TKMedium %@>\n\tTitle: %@,\n\tURL: %@\n\tAuthor: %@,"
		"\n\tAuthor URL: %@\n\tOrigin: %@,\n\tProvider = %@,\n\tSize: %f x %f",
			_ID, _title, _URL.absoluteString, _author, _authorURL.absoluteString,
			_originURL.absoluteString, _provider, _width, _height];
}

- (NSURL *)displayableImageURLForSize:(CGSize)size
{
	return [self displayableImageURLForSize:size contentMode:TKMediumContentModeCrop];
}

- (NSURL *)displayableImageURLForSize:(CGSize)size contentMode:(TKMediumContentMode)mode
{
	if (size.width < 24 || size.height < 24 ||
	    size.width > 4096 || size.height > 4096)
		return nil;

	NSString *modeString = (mode == TKMediumContentModeNoCropFit)  ? @"nc" :
	                       (mode == TKMediumContentModeNoCropFill) ? @"ncfill" : @"";

	NSString *sizeString = [NSString stringWithFormat:@"%.0fx%.0f%@", size.width, size.height, modeString];

	NSString *urlString = [[_templateURL absoluteString] stringByReplacingOccurrencesOfString:
	                       @TKMEDIUM_SIZE_PLACEHOLDER withString:sizeString];

	return [NSURL URLWithString:urlString];
}

- (NSURL *)displayableVideoURLForResolution:(TKMediumVideoResolution)resolution
{
	if (_type != TKMediumTypeVideo && _type != TKMediumTypeVideo360)
		return nil;

	NSString *resString = (resolution == TKMediumVideoResolution720p)  ? @"720p" :
	                      (resolution == TKMediumVideoResolution1080p) ? @"1080p" :
	                      (resolution == TKMediumVideoResolution4K)    ? @"4k" : nil;

	if (!resString) return nil;

	NSString *urlString = [[_templateURL absoluteString] stringByReplacingOccurrencesOfString:
	                       @TKMEDIUM_SIZE_PLACEHOLDER withString:resString];

	return [NSURL URLWithString:urlString];
}

@end
