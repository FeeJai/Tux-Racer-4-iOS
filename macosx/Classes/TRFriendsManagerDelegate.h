//
//  TRFriendsManagerDelegate.h
//  tuxracer
//
//  Created by emmanuel de Roux on 06/12/08.
//  Copyright 2008 école Centrale de Lyon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "prefsController.h"
#import "myHTTPErrors.h"

@interface TRFriendsManagerDelegate : NSObject <UIActionSheetDelegate> {
    IBOutlet UITableView* friendsTableView;
    IBOutlet UIBarButtonItem* editButton;
    IBOutlet prefsController* PC;
    IBOutlet UITableViewCell* insertCell;
    IBOutlet UITextField* insertTextField;
    
    NSMutableArray* _friendsList;
    NSString* _loginBeingAdded;
    
    id _backTarget;
    SEL _backSelector;
}
- (IBAction) edit:(id)sender;
- (IBAction) goBack:(id)sender;
- (void)addFriend:(NSString*)login;
- (BOOL) isAlreadyFriendOrYourself:(NSString*)friend;

- (void)setEditMode:(BOOL)edit animated:(BOOL)animated;
+ (TRFriendsManagerDelegate *)sharedFriendManager;

@property (readwrite, assign) id backTarget;
@property (readwrite, assign) SEL backSelector;
@end
