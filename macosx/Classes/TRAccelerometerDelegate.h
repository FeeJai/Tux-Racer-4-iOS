//
//  TRAccelerometerDelegate.h
//  tuxracer
//
//  Created by emmanuel de Roux on 10/11/08.
//  Copyright 2008 école Centrale de Lyon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EAGLView.h"
#import "tuxracer.h"

#define kAccelerometerFrequency    30.0


@interface TRAccelerometerDelegate : NSObject <UIAccelerometerDelegate> {
    EAGLView* glView;
    scalar_t turnFact;
    CGPoint _gravity;
    CGFloat _previousGravity[3];
    uint64_t _lastTrickTime;
}
@property(nonatomic,retain)  EAGLView* glView;
@property(nonatomic)  scalar_t turnFact;
@property  CGPoint gravity;

+ (id)sharedAccelerometerDelegate;

//Gestion de l'acceleromètre :
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration;
-(scalar_t)calculateTurnFact:(UIAcceleration*)acceleration;
@end
