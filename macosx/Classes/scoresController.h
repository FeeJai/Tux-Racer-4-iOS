//
//  scoresController.h
//  tuxracer
//
//  Created by emmanuel de Roux on 01/12/08.
//  Copyright 2008 école Centrale de Lyon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EAGLView.h"
#import "TransitionView.h"
#import "TRTabBarItem.h"

@interface scoresController : NSObject <UIActionSheetDelegate> {
    NSMutableArray* _listOfCourses;
    NSString* _currentSlope;
    NSString* _orderType;
    NSArray* _currentRankings;
    NSArray* _currentPercentage;
    IBOutlet EAGLView* glView;
    IBOutlet TransitionView* transitionView;
    IBOutlet UIView* friendsManagerView;
    IBOutlet UIView* rankingsView;
    IBOutlet UIView* slopesView;
    IBOutlet UITableView* slopesTableView;
    IBOutlet UITabBar* tabBar;
    IBOutlet TRTabBarItem* scoreBarItem;
    IBOutlet TRTabBarItem* speedOnlyBarItem;
    IBOutlet UITableView* rankingsTableView;
}
@property(nonatomic,retain) NSString* _currentSlope;
@property(copy) NSString* orderType;
+ (id) sharedScoresController;
- (NSString*)gameOrderType;
- (void) saveScoreOnlineAfterRace:(int)score onPiste:(NSString*)piste herring:(int)herring time:(char*)time;
- (void) displayRankingsAfterRace:(int)score onPiste:(NSString*)piste herring:(int)herring time:(char*)time;
- (void) treatError:(NSString*)erreur;
- (IBAction) refreshSlopesView:(id)sender;
- (IBAction) displaySlopes:(id)sender;
- (IBAction) displayRankings:(id)sender;
- (IBAction) toggleFriendList:(id)sender;
- (void) dirtyScores;
- (void) treatSaveScoreAfterRaceResult:(NSString*)result;
- (void) treatDisplayRankingsAfterRaceResult:(NSString*)result;
- (void) treatSyncScoresResult:(NSString*)result;
- (void) syncScores;
- (void) refreshSlopes:(BOOL)syncIfNeeded;
- (void) refreshRankings;
- (void) treatData:(NSString*) data;

@end
