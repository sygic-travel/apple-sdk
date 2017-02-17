//
//  Foundation+TravelKit.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "Foundation+TravelKit.h"

@implementation NSString (TravelKit)

- (BOOL)tk_containsSubstring:(NSString *)str
{
	if (!str) return NO;
	return [self rangeOfString:str].location != NSNotFound;
}

@end
