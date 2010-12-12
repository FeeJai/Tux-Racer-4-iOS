//
//  TRAccelerometerDelegate.m
//  tuxracer
//
//  Created by emmanuel de Roux on 10/11/08.
//  Copyright 2008 école Centrale de Lyon. All rights reserved.
//

#import "TRAccelerometerDelegate.h"
#include <mach/mach.h>
#include <mach/mach_time.h>
#import "racing.h"

//Horizontal parameters
#define kYMax					    0.5 //between 0 and 1.0
#define kYSensibility               0.1 //between 0 and kYMax

//shake paramaters, for tricks
#define kAccelerationThreshold       (9 * (1. / (kAccelerometerFrequency)))

static enum {
    shaking=1,
    idle=0
}  shake_state ;


scalar_t accelerometerTurnFact() {
    return [[TRAccelerometerDelegate sharedAccelerometerDelegate] turnFact];
}

@implementation TRAccelerometerDelegate

static TRAccelerometerDelegate *sharedAccelerationDelegate=nil;

@synthesize glView;
@synthesize turnFact;
@synthesize gravity=_gravity;

+ (id)sharedAccelerometerDelegate
{
    return sharedAccelerationDelegate;
}

- (id) init
{
    self = [super init];
    if (self != nil) {
        glView = [EAGLView sharedView];
        sharedAccelerationDelegate = [self retain];
        _gravity = CGPointMake(0, -1);
        shake_state = idle;
    }
    return self;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    _gravity = CGPointMake(acceleration.x, acceleration.y);

    //On n'utilise l'acceleromètre que si on est en mode intro ou en mode racing
    if (g_game.mode==RACING)
    {
        //printf("x : %f ; y : %f ; z : %f \n",acceleration.x,acceleration.y,acceleration.z);
        self.turnFact=[self calculateTurnFact:acceleration];
        
        //Detects shakes and do some tricks while jumping
        float accel[3];
        accel[0] = fabsf(_previousGravity[0] - acceleration.x);
        accel[1] = fabsf(_previousGravity[1] - acceleration.y);
        accel[2] = fabsf(_previousGravity[2] - acceleration.z);
        

        if ((accel[0] >= kAccelerationThreshold ||
             accel[1] >= kAccelerationThreshold ||
             accel[2] >= kAccelerationThreshold) &&
             shake_state!=shaking)
        {
            shake_state=shaking;
            glView.keyboardFunction(100,0,0,1,1);  //touche D = 100
        }
        
        else if ((accel[0] < kAccelerationThreshold ||
             accel[1] < kAccelerationThreshold ||
             accel[2] < kAccelerationThreshold) &&
             shake_state == shaking)
        {
            if(get_trick_modifier()) // Make sure we don't miss a trick, so we check the value of trick_modifier in racing.c
            {
                shake_state=idle;
                glView.keyboardFunction(100,0,1,1,1);  //touche D = 100
            }
        }
        _previousGravity[0] = acceleration.x;
        _previousGravity[1] = acceleration.y;
        _previousGravity[2] = acceleration.z;
    }
}

-(scalar_t)calculateTurnFact:(UIAcceleration*)acceleration
{
    if ((acceleration.y)>kYMax) return -1.0;
    if ((acceleration.y)<-kYMax) return 1.0;
    if ((acceleration.y)>kYSensibility)  return -(kYSensibility+(1.0-kYSensibility)*(acceleration.y-kYSensibility)/(kYMax-kYSensibility));
    if ((acceleration.y)<-kYSensibility) return -(-kYSensibility+(-1.0+kYSensibility)*(acceleration.y+kYSensibility)/(-kYMax+kYSensibility));
    return 0.0;
}

@end
