//
//  TKPlacesQuery.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKPlacesQuery.h"

@implementation TKPlacesQuery

- (instancetype)init
{
	if (self = [super init])
	{
		_categoriesMatching = TKPlacesQueryMatchingAll;
		_tagsMatching = TKPlacesQueryMatchingAll;
		_parentIDsMatching = TKPlacesQueryMatchingAll;
	}

	return self;
}

- (NSUInteger)hash
{
	NSMutableString *key = [NSMutableString string];

	if (_levels) [key appendString:[@(_levels) stringValue]];
	if (_searchTerm.length) [key appendString:_searchTerm];
	if (_categories.count) [key appendString:[_categories componentsJoinedByString:@"+"]];
	if (_categoriesMatching) [key appendString:@"@"];
	if (_tags.count) [key appendString:[_tags componentsJoinedByString:@"+"]];
	if (_tagsMatching) [key appendString:@"@"];
	if (_parentIDs.count) [key appendString:[_parentIDs componentsJoinedByString:@"+"]];
	if (_parentIDsMatching) [key appendString:@"@"];
	if (_quadKeys.count) [key appendString:[_quadKeys componentsJoinedByString:@"+"]];
	if (_mapSpread) [key appendString:[_mapSpread stringValue]];
	if (_limit) [key appendString:[_limit stringValue]];
	if (_bounds) [key appendString:_bounds.description];

	return key.hash;
}

- (id)copy
{
	TKPlacesQuery *query = [TKPlacesQuery new];

	query.levels = _levels;
	query.searchTerm = [_searchTerm copy];
	query.categories = [_categories copy];
	query.categoriesMatching = _categoriesMatching;
	query.tags = [_tags copy];
	query.tagsMatching = _tagsMatching;
	query.parentIDs = [_parentIDs copy];
	query.parentIDsMatching = _parentIDsMatching;
	query.quadKeys = [_quadKeys copy];
	query.mapSpread = _mapSpread;
	query.limit = _limit;
	query.bounds = _bounds;

	return query;
}

- (id)copyWithZone:(NSZone __unused *)zone
{
	return [self copy];
}

@end
