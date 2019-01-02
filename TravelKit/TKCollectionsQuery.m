//
//  TKCollectionsQuery.m
//  TravelKit
//
//  Created by Michal Zelinka on 30/10/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#import <TravelKit/TKCollectionsQuery.h>

@implementation TKCollectionsQuery

-(NSUInteger)hash
{
	NSUInteger result = 1;
	NSUInteger prime = 31;
	NSUInteger yesPrime = 1231;
	NSUInteger noPrime = 1237;

//	// Add any object that already has a hash function (NSString)
//	result = prime * result + [self.myObject hash];
//
//	// Add primitive variables (int)
//	result = prime * result + self.primitiveVariable;
//
//	// Boolean values (BOOL)
//	result = prime * result + self.isSelected?yesPrime:noPrime;

	result = prime * result + [_parentPlaceID hash];
	result = prime * result + [_placeIDs hash];
	result = prime * result + _placeIDsMatching;
	result = prime * result + [_tags hash];
	result = prime * result + [_tagsToOmit hash];
	result = prime * result + [_searchTerm hash];
	result = prime * result + [_limit hash];
	result = prime * result + [_offset hash];
	result = prime * result + (_preferUnique ? yesPrime : noPrime);

	return result;
}

@end
