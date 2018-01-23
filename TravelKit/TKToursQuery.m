//
//  TKToursQuery.m
//  TravelKit
//
//  Created by Michal Zelinka on 16/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKToursQuery.h"

@implementation TKToursQuery

- (void)setSortingType:(TKToursQuerySorting)sortingType
{
	_sortingType = sortingType;
	_descendingSortingOrder = (sortingType != TKToursQuerySortingPrice);
}

- (NSUInteger)hash
{
	NSMutableString *key = [NSMutableString string];

	[key appendFormat:@"source:%tu", _source];
	if (_parentID) [key appendFormat:@"|parent:%@", _parentID];
	[key appendFormat:@"|sort:%tu", _sortingType];
	[key appendFormat:@"|desc:%tu", _descendingSortingOrder];
	[key appendFormat:@"|page:%tu", _pageNumber.unsignedIntegerValue];

	return key.hash;
}

- (id)copy
{
	TKToursQuery *query = [TKToursQuery new];

	query.parentID = [_parentID copy];
	query.sortingType = _sortingType;
	query.descendingSortingOrder = _descendingSortingOrder;
	query.pageNumber = [_pageNumber copy];

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
