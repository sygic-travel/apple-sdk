//
//  TKToursQuery.m
//  TravelKit
//
//  Created by Michal Zelinka on 16/06/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <TravelKit/TKToursQuery.h>

@implementation TKToursViatorQuery

- (void)setSortingType:(TKToursViatorQuerySorting)sortingType
{
	_sortingType = sortingType;
	_descendingSortingOrder = (sortingType != TKToursViatorQuerySortingPrice);
}

- (NSUInteger)hash
{
	NSMutableString *key = [@"viator" mutableCopy];

	if (_parentID) [key appendFormat:@"|parent:%@", _parentID];
	[key appendFormat:@"|sort:%tu", _sortingType];
	[key appendFormat:@"|desc:%d", _descendingSortingOrder];
	[key appendFormat:@"|page:%tu", _pageNumber.unsignedIntegerValue];

	return key.hash;
}

- (id)copy
{
	TKToursViatorQuery *query = [TKToursViatorQuery new];

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


@implementation TKToursGYGQuery

- (void)setSortingType:(TKToursGYGQuerySorting)sortingType
{
	_sortingType = sortingType;
	_descendingSortingOrder = (sortingType != TKToursGYGQuerySortingPrice && sortingType != TKToursGYGQuerySortingDuration);
}

- (NSUInteger)hash
{
	NSMutableString *key = [@"gyg" mutableCopy];

	if (_parentID) [key appendFormat:@"|parent:%@", _parentID];
	[key appendFormat:@"|sort:%tu", _sortingType];
	[key appendFormat:@"|desc:%d", _descendingSortingOrder];
	[key appendFormat:@"|page:%tu", _pageNumber.unsignedIntegerValue];
	[key appendFormat:@"|count:%tu", _count.unsignedIntegerValue];
	[key appendFormat:@"|duration:%@-%@", _minimalDuration, _maximalDuration];
	[key appendFormat:@"|term:'%@'", _searchTerm];
	if (_startDate) [key appendFormat:@"|fromDate:%.0f", _startDate.timeIntervalSince1970];
	if (_endDate) [key appendFormat:@"|toDate:%.0f", _endDate.timeIntervalSince1970];

	return key.hash;
}

- (id)copy
{
	TKToursGYGQuery *query = [TKToursGYGQuery new];

	query.parentID = [_parentID copy];
	query.sortingType = _sortingType;
	query.descendingSortingOrder = _descendingSortingOrder;
	query.pageNumber = [_pageNumber copy];
	query.searchTerm = [_searchTerm copy];
	query.count = [_count copy];
	query.startDate = _startDate;
	query.endDate = _endDate;
	query.minimalDuration = _minimalDuration;
	query.maximalDuration = _maximalDuration;

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
