//
//  TRTabBarItem.m
//  tuxracer
//
//  Created by emmanuel de Roux on 18/01/09.
//  Copyright 2009 école Centrale de Lyon. All rights reserved.
//

#import "TRTabBarItem.h"


@implementation TRTabBarItem

@synthesize orderType=_orderType;
- (id) init
{
    self = [super init];
    if (self != nil) {
        self.orderType=@"classic";
    }
    return self;
}

- (void) dealloc
{
    self.orderType=nil;
    [super dealloc];
}

@end
