//
//  TKPlacesQuery.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKPlacesQuery.h"

@implementation TKPlacesQuery

- (NSUInteger)hash
{
	NSMutableString *key = [NSMutableString string];

	if (_levels) [key appendString:[@(_levels) stringValue]];
	if (_searchTerm.length) [key appendString:_searchTerm];
	if (_categories.count) [key appendString:[_categories componentsJoinedByString:@"+"]];
	if (_tags.count) [key appendString:[_tags componentsJoinedByString:@"+"]];
	if (_parentID.length) [key appendString:_parentID];
	if (_quadKeys.count) [key appendString:[_quadKeys componentsJoinedByString:@"+"]];
	if (_mapSpread) [key appendString:[_mapSpread stringValue]];
	if (_limit) [key appendString:[_limit stringValue]];
	if (_bounds) [key appendString:_bounds.description];

	return key.hash;
}

@end
