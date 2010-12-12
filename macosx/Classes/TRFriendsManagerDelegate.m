//
//  TRFriendsManagerDelegate.m
//  tuxracer
//
//  Created by emmanuel de Roux on 06/12/08.
//  Copyright 2008 école Centrale de Lyon. All rights reserved.
//

#import "TRFriendsManagerDelegate.h"
#import "scoresController.h"
#import "ConnectionController.h"


@implementation TRFriendsManagerDelegate
@synthesize backTarget=_backTarget;
@synthesize backSelector=_backSelector;
- (void)awakeFromNib
{
    [self setEditMode:YES animated:NO];
}

static TRFriendsManagerDelegate * sharedFriendManager;
- (id) init
{
    self = [super init];
    if (self != nil) {
        [prefsController setDefaults];
        _friendsList = [[NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"friendsList"]] retain];
        sharedFriendManager = [self retain];
    }
    return self;
}

- (void) dealloc
{
    [_loginBeingAdded release];
    [_friendsList release];
    [super dealloc];
}

+ (TRFriendsManagerDelegate *)sharedFriendManager
{
    return sharedFriendManager;
}


#pragma mark tableView delegate

- (void)setEditMode:(BOOL)edit animated:(BOOL)animated
{
    //Go into edit mode
    if (edit) {
        [editButton setTitle:NSLocalizedString(@"Cancel",@"Classes/TRFriendsManagerDelegate.m")];
        
        //cas vide
        [insertTextField setText:@""];
        [insertTextField resignFirstResponder];
        [friendsTableView setEditing:TRUE animated:animated];
        [friendsTableView reloadData];
    }
    else {
        [editButton setTitle:NSLocalizedString(@"Edit",@"Classes/TRFriendsManagerDelegate.m")];
        [friendsTableView setEditing:FALSE animated:animated];
        [friendsTableView reloadData];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1; 
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([_friendsList count] == 0) return 1;
    return [_friendsList count] + ([friendsTableView isEditing] ? 1 : 0);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete:
            if(indexPath.row == 0) return;
            [_friendsList removeObjectAtIndex:indexPath.row-1];
            [[NSUserDefaults standardUserDefaults] setObject:_friendsList forKey:@"friendsList"];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationTop];
            break;
        case UITableViewCellEditingStyleInsert:
            [insertTextField resignFirstResponder];
            [self addFriend:[insertTextField text]];
            break;
        default:
            break;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row != 0;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0)
        return UITableViewCellEditingStyleNone;
    else
        return UITableViewCellEditingStyleDelete;
    
}

- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellSeparatorStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [insertTextField resignFirstResponder];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([friendsTableView isEditing] && indexPath.row == 0) return insertCell;
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"cellID"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    if(![_friendsList count])
        cell.text = @"Should not be seen.";
    else if(indexPath.row-1 < [_friendsList count] && indexPath.row > 0)
        cell.text = [_friendsList objectAtIndex:indexPath.row-1];
    
    return cell;
}

#pragma mark Friends Manager Functions


- (IBAction) edit:(id)sender {
    [self setEditMode:![friendsTableView isEditing] animated:YES];
}

-(void)treatData:(NSString*)data {
    int error = [data intValue];
    if (error == LOGIN_EXISTS) {
        [_friendsList insertObject:_loginBeingAdded atIndex:0];
        [[NSUserDefaults standardUserDefaults] setObject:_friendsList forKey:@"friendsList"];
        [insertTextField setText:@""];
        [friendsTableView reloadData];
    } else {
        [PC treatError:data];
        [insertTextField setText:_loginBeingAdded];
    }
}

- (void)addFriend:(NSString*)login {
    if (![login isEqualToString:@""] && ![self isAlreadyFriendOrYourself:login]) {
        if(!_loginBeingAdded) [_loginBeingAdded release];
        _loginBeingAdded=[login retain];
        [insertTextField setText:_loginBeingAdded];
        ConnectionController* conn = [[[ConnectionController alloc] init] autorelease];
        NSString* queryString = [NSString stringWithFormat:@"login=%@",login];
        [conn postRequest:queryString atURL:[tuxRiderRootServer stringByAppendingString:@"checkLogin.php"] withWaitMessage:NSLocalizedString(@"Checking login...",@"Classes/TRFriendsManagerDelegate.m") sendResponseTo:self withMethod:@selector(treatData:)];        
    } 
    else 
    {
        [insertTextField setText:@""];
    }
}

- (BOOL) isAlreadyFriendOrYourself:(NSString*)friend {
    for (NSString* name in _friendsList) {
        if ([name isEqualToString:friend]) 
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error !",@"Classes/TRFriendsManagerDelegate.m") message:[NSString stringWithFormat:@"%@ %@",friend,NSLocalizedString(@"is already in your friends list.",@"Classes/TRFriendsManagerDelegate.m")] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
            [alert release];
            return YES;
        }
    }
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([friend isEqualToString:[prefs objectForKey:@"username"]]) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error !",@"Classes/TRFriendsManagerDelegate.m") message:NSLocalizedString(@"You cannot be friend with yourself.",@"Classes/TRFriendsManagerDelegate.m") delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",@"Classes/TRFriendsManagerDelegate.m") otherButtonTitles:nil];
        [alert show];
        [alert release];
        return YES;
    }
    return NO;
}

#pragma mark transitions Functions

- (IBAction) goBack:(id)sender{
    [[NSUserDefaults standardUserDefaults] synchronize]; 
    if(!_backTarget) return;
    BOOL (*back)(id, SEL) = (BOOL (*)(id, SEL))[_backTarget methodForSelector:_backSelector];
    back(_backTarget, _backSelector);
}

#pragma mark TextField delegate function
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    [self addFriend:[theTextField text]];
    return YES;
}

@end
