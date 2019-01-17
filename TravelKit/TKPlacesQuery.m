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

-(NSUInteger)hash
{
	NSUInteger result = 1;
	NSUInteger prime = 31;
//	NSUInteger yesPrime = 1231;
//	NSUInteger noPrime = 1237;

//	// Add any object that already has a hash function (NSString)
//	result = prime * result + [self.myObject hash];
//
//	// Add primitive variables (int)
//	result = prime * result + self.primitiveVariable;
//
//	// Boolean values (BOOL)
//	result = prime * result + self.isSelected?yesPrime:noPrime;

	result = prime * result + [_searchTerm hash];
	result = prime * result + _levels;
	result = prime * result + _categories;
	result = prime * result + _categoriesMatching;
	result = prime * result + [_tags.description hash];
	result = prime * result + _tagsMatching;
	result = prime * result + [_parentIDs.description hash];
	result = prime * result + _parentIDsMatching;
	result = prime * result + [_quadKeys.description hash];
	result = prime * result + [_mapSpread hash];
	result = prime * result + [_minimumRating hash];
	result = prime * result + [_maximumRating hash];
	result = prime * result + [_limit hash];
	result = prime * result + [_offset hash];
	result = prime * result + [_bounds.description hash];

	return result;
}

- (id)copy
{
	TKPlacesQuery *query = [TKPlacesQuery new];

	query.levels = _levels;
	query.searchTerm = [_searchTerm copy];
	query.categories = _categories;
	query.categoriesMatching = _categoriesMatching;
	query.tags = [_tags copy];
	query.tagsMatching = _tagsMatching;
	query.parentIDs = [_parentIDs copy];
	query.parentIDsMatching = _parentIDsMatching;
	query.quadKeys = [_quadKeys copy];
	query.mapSpread = _mapSpread;
	query.minimumRating = _minimumRating;
	query.maximumRating = _maximumRating;
	query.limit = _limit;
	query.offset = _offset;
	query.bounds = _bounds;

	return query;
}

- (id)mutableCopy
{
	return [self copy];
}

- (id)copyWithZone:(NSZone __unused *)zone
{
	return [self copy];
}

- (id)mutableCopyWithZone:(NSZone __unused *)zone
{
	return [self copy];
}

@end
