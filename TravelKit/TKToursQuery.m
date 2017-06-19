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

	if (_parentID) [key appendString:_parentID];
	[key appendString:[@(_sortingType) stringValue]];
	[key appendString:(_descendingSortingOrder ? @"DESC":@"ASC")];
	[key appendString:([_pageNumber stringValue] ?: @"0")];

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
