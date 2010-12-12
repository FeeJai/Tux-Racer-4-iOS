//
//  touchwinsys.m
//  tuxracer
//
//  Created by emmanuel de roux on 22/10/08.
//  Copyright 2008 école Centrale de Lyon. All rights reserved.
//

#import "EAGLView.h"
#import "TRAppDelegate.h"
#include "tuxracer.h"
#include "winsys.h"
#import "sharedGeneralFunctions.h"

/*---------------------------------------------------------------------------*/
/*! 
 Requests that the screen be redrawn
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_post_redisplay() 
{
	[[EAGLView sharedView] setNeedsDisplay];
}


/*---------------------------------------------------------------------------*/
/*! 
 Sets the display callback
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_set_display_func( winsys_display_func_t func )
{
	[[EAGLView sharedView] setDisplayFunction:func];
}


/*---------------------------------------------------------------------------*/
/*! 
 Sets the idle callback
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_set_idle_func( winsys_idle_func_t func )
{
	[[EAGLView sharedView] setIdleFunction:func];
    //func();
}


/*---------------------------------------------------------------------------*/
/*! 
 Sets the reshape callback
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_set_reshape_func( winsys_reshape_func_t func )
{
}



/*---------------------------------------------------------------------------*/
/*! 
 Sets the keyboard callback
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_set_keyboard_func( winsys_keyboard_func_t func )
{
	[[EAGLView sharedView] setKeyboardFunction:func];
}


/*---------------------------------------------------------------------------*/
/*! 
 Sets the mouse button-press callback
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_set_mouse_func( winsys_mouse_func_t func )
{
	[[EAGLView sharedView] setMouseFunction:func];
}


/*---------------------------------------------------------------------------*/
/*! 
 Sets the mouse motion callback (when a mouse button is pressed)
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_set_motion_func( winsys_motion_func_t func )
{
    [[EAGLView sharedView] setMouseMotionFunction:func];
}


/*---------------------------------------------------------------------------*/
/*! 
 Sets the mouse motion callback (when no mouse button is pressed)
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_set_passive_motion_func( winsys_motion_func_t func )
{
}



/*---------------------------------------------------------------------------*/
/*! 
 Copies the OpenGL back buffer to the front buffer
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_swap_buffers()
{
    //glFlush();
}


/*---------------------------------------------------------------------------*/
/*! 
 Moves the mouse pointer to (x,y)
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_warp_pointer( int x, int y )
{
}


/*---------------------------------------------------------------------------*/
/*! 
 Initializes the OpenGL rendering context, and creates a window (or 
 sets up fullscreen mode if selected)
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_init( int *argc, char **argv, char *window_title, 
				 char *icon_title )
{
}

/*---------------------------------------------------------------------------*/
/*! 
 Initializes the OpenGL rendering context, and creates a window (or 
 sets up fullscreen mode if selected)
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_get_gravity(float * grav_x, float * grav_y)
{
    CGPoint gravity = [[TRAccelerometerDelegate sharedAccelerometerDelegate] gravity];
    *grav_x = gravity.x;
    *grav_y = gravity.y;
}

void winsys_set_high_framerate( bool_t highframerate )
{
    [[TRAppDelegate sharedAppDelegate] setIsHighFrameRateMode:highframerate];
}

@interface TRMainThreadExecuter : NSObject

@end

#ifdef TR_DEBUG_MODE
static uint64_t date = 0;
#endif

@implementation TRMainThreadExecuter
static TRMainThreadExecuter * sharedMainThreadExecuter = nil;
+ (id)sharedMainThreadExecuter
{
    if(!sharedMainThreadExecuter)
        sharedMainThreadExecuter = [[[self class] alloc] init];
    return sharedMainThreadExecuter;
}
- (void)execute2:(NSDictionary*)val
{
    void (*f)(void*, void*) = [[val objectForKey:@"func"] pointerValue];
    void * arg1 = [[val objectForKey:@"arg1"] pointerValue];
    void * arg2 = [[val objectForKey:@"arg2"] pointerValue];
#ifdef TR_DEBUG_MODE
    TRDebugLog("Context switch took %dms\n", (int32_t)(((int64_t)udate() - (int64_t)date) / 1000000));
#endif
    f(arg1, arg2);
}

@end

void winsys_perform_on_main_thread_sync2( void (*func)(void*, void*), void * arg1, void * arg2 )
{
#ifdef TR_DEBUG_MODE
    date = udate();
#endif
    [[TRMainThreadExecuter sharedMainThreadExecuter] performSelectorOnMainThread:@selector(execute2:)
    withObject:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSValue valueWithPointer:func], @"func",
        [NSValue valueWithPointer:arg1], @"arg1",
        [NSValue valueWithPointer:arg2], @"arg2",
        nil]
         waitUntilDone:YES];
}

void winsys_perform_on_main_thread_sync1( void (*func)(void*), void * arg1 )
{
#ifdef TR_DEBUG_MODE
    date = udate();
#endif
    [[TRMainThreadExecuter sharedMainThreadExecuter] performSelectorOnMainThread:@selector(execute2:)
    withObject:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSValue valueWithPointer:func], @"func",
        [NSValue valueWithPointer:arg1], @"arg1",
        nil]
         waitUntilDone:YES];
}

void winsys_perform_on_main_thread_sync0( void (*func)(void) )
{
#ifdef TR_DEBUG_MODE
    date = udate();
#endif
    [[TRMainThreadExecuter sharedMainThreadExecuter] performSelectorOnMainThread:@selector(execute2:)
    withObject:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSValue valueWithPointer:func], @"func",
        nil]
         waitUntilDone:YES];
}

/*---------------------------------------------------------------------------*/
/*! 
 Deallocates resources in preparation for program termination
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_shutdown()
{
}

/*---------------------------------------------------------------------------*/
/*! 
 Enables/disables key repeat messages from being generated
 \return  
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_enable_key_repeat( bool_t enabled )
{
}

/*---------------------------------------------------------------------------*/
/*! 
 Shows/hides mouse cursor
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_show_cursor( bool_t visible )
{
}



/*---------------------------------------------------------------------------*/
/*! 
 Processes and dispatches events.  This function never returns.
 \return  No.
 \author  jfpatry
 \date    Created:  2000-10-19
 \date    Modified: 2000-10-19
 */
void winsys_process_events()
{
}

/*---------------------------------------------------------------------------*/
/*! 
 Sets the function to be called when program ends.  Note that this
 function should only be called once.
 \author  jfpatry
 \date    Created:  2000-10-20
 \date Modified: 2000-10-20 */
void winsys_atexit( winsys_atexit_func_t func )
{
    static bool_t called = False;
	
    check_assertion( called == False, "winsys_atexit called twice" );
	
    called = True;
	
    atexit(func);
}

/*---------------------------------------------------------------------------*/
/*! 
 Show the preferences
 */
void winsys_show_preferences( void )
{
    [[TRAppDelegate sharedAppDelegate] showPreferences:nil];
}

/*---------------------------------------------------------------------------*/
/*! 
 Show the rankings
 */
void winsys_show_rankings( void )
{
    displaySlopes();
}

/*---------------------------------------------------------------------------*/
/*! 
 Exits the program
 \author  jfpatry
 \date    Created:  2000-10-20
 \date    Modified: 2000-10-20
 */
void winsys_exit( int code )
{
    exit(code);
}

const char * winsys_localized_string( const char * key, const char * comment )
{
    NSString * string = NSLocalizedString([NSString stringWithUTF8String:key],[NSString stringWithUTF8String:comment]);
    return [string UTF8String];
}
