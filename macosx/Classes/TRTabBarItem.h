//
//  TRTabBarItem.h
//  tuxracer
//
//  Created by emmanuel de Roux on 18/01/09.
//  Copyright 2009 école Centrale de Lyon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TRTabBarItem : UITabBarItem {
    NSString* _orderType;
}
@property(retain) NSString* orderType;
@end
