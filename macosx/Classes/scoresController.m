//
//  scoresController.m
//  tuxracer
//
//  Created by emmanuel de Roux on 01/12/08.
//  Copyright 2008 école Centrale de Lyon. All rights reserved.
//

#import "scoresController.h"
#import <QuartzCore/QuartzCore.h>
#import "sharedGeneralFunctions.h"
#import "ConnectionController.h"
#import "myHTTPErrors.h"
#import "TRSlopeInfoCell.h"
#import "TRRankingDelegate.h"
#import "TRFriendsManagerDelegate.h"
#import "save.h"
#import "game_over.h"

static scoresController* sharedScoresController=nil;

NSString * tuxRiderRootServer = TUXRIDER_ROOT_SERVER;

void saveScoreOnlineAfterRace(char* raceName,int score,int herring,int minutes,int seconds,int hundredths){
    char buff[10];
    sprintf( buff, "%02d:%02d:%02d", minutes, seconds, hundredths );
    [sharedScoresController saveScoreOnlineAfterRace:score onPiste:[NSString stringWithCString:raceName] herring:herring time:buff];
}

void displayRankingsAfterRace(char* raceName,int score,int herring,int minutes,int seconds,int hundredths){
    char buff[10];
    sprintf( buff, "%02d:%02d:%02d", minutes, seconds, hundredths );
    [sharedScoresController displayRankingsAfterRace:score onPiste:[NSString stringWithCString:raceName] herring:herring time:buff];
}

void displaySlopes()
{
    [sharedScoresController displaySlopes:nil];
}

void dirtyScores ()
{
    [sharedScoresController dirtyScores];
}

@implementation scoresController
@synthesize _currentSlope, orderType=_orderType;

- (id) init
{
    self = [super init];
    if (self != nil) {
        sharedScoresController=self;
    }
    return self;
}

- (void)awakeFromNib
{
    self.orderType=@"speed only";
    [tabBar setSelectedItem:speedOnlyBarItem];
    scoreBarItem.orderType=@"classic";
    speedOnlyBarItem.orderType=@"speed only";
}

- (void) dealloc
{
    self.orderType=nil;
    [_currentPercentage release];
    [_currentRankings release];
    [_listOfCourses release];
    [super dealloc];
}

+ (id) sharedScoresController {
    return sharedScoresController;
}

#pragma mark Saving scores functions

- (NSString*)gameOrderType {
    if (g_game.is_speed_only_mode) return @"speed only";
    else return @"classic";
}

//called by a C func
- (void) saveScoreOnlineAfterRace:(int)score onPiste:(NSString*)piste herring:(int)herring time:(char*)time{   
    //On enregistre le score en ligne que si l'utilisateur l'a choisi dans les prefs
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    if([prefs boolForKey:@"saveScoresAfterRace"]) {
        ConnectionController* conn = [[[ConnectionController alloc] init] autorelease];
        NSMutableString* queryString = [NSMutableString stringWithFormat:@"login=%@&mdp=%@&piste=%@&order=%@&score=%d&herring=%d&time=%s",[prefs valueForKey:@"username"],[prefs valueForKey:@"password"],piste,[self gameOrderType],score,herring,time];
        //Si le joueur ajouté des amis
        int i;
        for (i = 0; i<[[prefs objectForKey:@"friendsList"] count]; i++) {
            [queryString appendFormat:@"&friends[%d]=%@",i,[[prefs objectForKey:@"friendsList"] objectAtIndex:i]];
        }
        [conn postRequest:queryString atURL:[tuxRiderRootServer stringByAppendingString:@"saveScore.php"] withWaitMessage:NSLocalizedString(@"Saving score online...",@"") sendResponseTo:self withMethod:@selector(treatSaveScoreAfterRaceResult:)];
    
        //Set this to true so the user car go back to race select screen by touching the screen whatever happens (cancel, error, all good, etc...)
        g_game.rankings_displayed=true;
    }
    else {
        [self displayRankingsAfterRace:score onPiste:piste herring:herring time:time];
    }
}

//calls a C func
- (void) syncScores {
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    ConnectionController* conn = [[[ConnectionController alloc] init] autorelease];
    NSString* queryString = [NSString stringWithFormat:@"login=%@&mdp=%@&%s",[prefs valueForKey:@"username"],[prefs valueForKey:@"password"],editSynchronizeScoresRequest()];
    [conn postRequest:queryString atURL:[tuxRiderRootServer stringByAppendingString:@"synchronize.php"] withWaitMessage:NSLocalizedString(@"Saving unsaved scores online...",@"") sendResponseTo:self withMethod:@selector(treatSyncScoresResult:)];
}

- (void) dirtyScores {
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setInteger:([prefs integerForKey:@"needsSync"]+1) forKey:@"needsSync"];
}

#pragma mark display functions

- (IBAction) toggleFriendList:(id)sender {
    if([transitionView isTransitioning]) {
		// Don't interrupt an ongoing transition
		return;
	}
	// If view 1 is already a subview of the transition view replace it with view 2, and vice-versa.
	if([rankingsView superview]) {
        [[TRFriendsManagerDelegate sharedFriendManager] setEditMode:YES animated:NO];
        [[TRFriendsManagerDelegate sharedFriendManager] setBackTarget:self];
        [[TRFriendsManagerDelegate sharedFriendManager] setBackSelector:_cmd];
		[transitionView replaceSubview:rankingsView withSubview:friendsManagerView transition:kCATransitionPush direction:kCATransitionFromRight duration:0.25];
    } else {
        [self refreshRankings];
        [transitionView replaceSubview:friendsManagerView withSubview:rankingsView transition:kCATransitionPush direction:kCATransitionFromLeft duration:0.25];
    }
}


- (IBAction) displaySlopes:(id)sender {
    
    if([transitionView isTransitioning]) {
		// Don't interrupt an ongoing transition
		return;
	}
	// If view 1 is already a subview of the transition view replace it with view 2, and vice-versa.
	if([glView superview]) {
		//Affiche les slopes
		[glView stopAnimation];
		[transitionView replaceSubview:glView withSubview:slopesView transition:kCATransitionMoveIn direction:kCATransitionFromTop duration:0.50];
        [self refreshSlopes:TRUE];
	} else {
		//Affiche le jeu
        [glView startAnimation];
		[transitionView replaceSubview:slopesView withSubview:glView transition:kCATransitionReveal direction:kCATransitionFromBottom duration:0.50];
    }
    
}

- (IBAction) displayRankings:(id)sender {
    if([transitionView isTransitioning]) {
		// Don't interrupt an ongoing transition
		return;
	}
	// If view 1 is already a subview of the transition view replace it with view 2, and vice-versa.
	if([slopesView superview]) {
		//Affiche les rankings
        [self refreshRankings];
		[transitionView replaceSubview:slopesView withSubview:rankingsView transition:kCATransitionPush direction:kCATransitionFromRight duration:0.50];
	} else {
		//Affiche les slopes
        [self refreshSlopes:NO];
        //On selectionne le bon bouton de la tab bar
        if ([self.orderType isEqualToString:@"classic"]) {
            [tabBar setSelectedItem:scoreBarItem];
        } else {
            [tabBar setSelectedItem:speedOnlyBarItem];
        }
        
        [transitionView replaceSubview:rankingsView withSubview:slopesView transition:kCATransitionPush direction:kCATransitionFromLeft duration:0.50];
    }
}

//called by a C func

- (void) displayRankingsAfterRace:(int)score onPiste:(NSString*)piste herring:(int)herring time:(char*)time{
    //On enregistre le score en ligne que si l'utilisateur l'a choisi dans les prefs
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    if([prefs boolForKey:@"displayRankingsAfterRace"]) {
        ConnectionController* conn = [[[ConnectionController alloc] init] autorelease];
        NSMutableString* queryString = [NSMutableString stringWithFormat:@"login=%@&mdp=%@&order=%@&piste=%@&score=%d&herring=%d&time=%s",[prefs valueForKey:@"username"],[prefs valueForKey:@"password"],[self gameOrderType],piste,score,herring,time];
        //Si le joueur ajouté des amis
        int i;
        for (i = 0; i<[[prefs objectForKey:@"friendsList"] count]; i++)
            [queryString appendFormat:@"&friends[%d]=%@",i,[[prefs objectForKey:@"friendsList"] objectAtIndex:i]];
        [conn postRequest:queryString atURL:[tuxRiderRootServer stringByAppendingString:@"displayRankingsAfterRace.php"] withWaitMessage:NSLocalizedString(@"Getting World rankings for the score you just did...",@"") sendResponseTo:self withMethod:@selector(treatDisplayRankingsAfterRaceResult:)];
        
        //Set this to true so the user car go back to race select screen by touching the screen whatever happens (cancel, error, all good, etc...)
        g_game.rankings_displayed=true;
    }
}

#pragma mark traitement des reponses HTTP

-(void) treatError:(NSString*)erreur{
    int err = [erreur intValue];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error !" message:@"" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    switch (err) {
        case LOGIN_ERROR:
            [alert setMessage:NSLocalizedString(@"Wrong login or password. Go to settings pannel to settle this problem.",@"")];
            [alert show];
            break;
        case SERVER_ERROR:
            [alert setMessage:NSLocalizedString(@"Internal server error! Please try again Later.",@"")];
            [alert show];
            break;
        case CONNECTION_ERROR:
            [alert setMessage:NSLocalizedString(@"Check your network connection and try again.",@"")];
            [alert show];
            break;
        case SCORE_SAVED:
            //Set this to true so the rankings will be displayed
            g_game.needs_save_or_display_rankings=true;
            //function implemented in game_over.c
            displaySavedAndRankings([NSLocalizedString(@"Congratulations !",@"") UTF8String], [(NSString*)[_currentRankings objectAtIndex:0] UTF8String], [(NSString*)[_currentRankings objectAtIndex:1] UTF8String], [(NSString*)[_currentRankings objectAtIndex:2] UTF8String],[[_currentPercentage objectAtIndex:0] doubleValue], [[_currentPercentage objectAtIndex:1] doubleValue], [[_currentPercentage objectAtIndex:2] doubleValue]);
            [prefs setInteger:([prefs integerForKey:@"needsSync"]-1) forKey:@"needsSync"];
            break;
        case RANKINGS_AFTER_RACE_OBTAINED:
            //Set this to true so the rankings will be displayed
            g_game.needs_save_or_display_rankings=true;
            //function implemented in game_over.c
            displaySavedAndRankings([NSLocalizedString(@"World rankings",@"") UTF8String], [(NSString*)[_currentRankings objectAtIndex:0] UTF8String], [(NSString*)[_currentRankings objectAtIndex:1] UTF8String], [(NSString*)[_currentRankings objectAtIndex:2] UTF8String],[[_currentPercentage objectAtIndex:0] doubleValue], [[_currentPercentage objectAtIndex:1] doubleValue], [[_currentPercentage objectAtIndex:2] doubleValue]);
            break;
        case NEEDS_NEW_VERSION:
            [alert setTitle:NSLocalizedString(@"Score not saved !",@"")];
            [alert setMessage:NSLocalizedString(@"For security reasons, you need to update Tux Rider World Challenge to save scores online. Go to the App Store to do the update.",@"")];
            [alert show];
            break;
        case BETTER_SCORE_EXISTS:
            [alert setTitle:NSLocalizedString(@"Score not saved !",@"")];
            [alert setMessage:NSLocalizedString(@"A better score already exists for this login !",@"")];
            [alert show];
            break;
        case NO_SCORES_SAVED_YET:
            [alert setTitle:NSLocalizedString(@"No rankings available !",@"")];
            [alert setMessage:NSLocalizedString(@"You don't have any scores saved online for the moment !",@"")];
            [_listOfCourses removeAllObjects];
            [slopesTableView reloadData];
            [alert show];
            break;
        case SCORE_UPDATED:
            //Do nothing, OK
            break;
        case NOTHING_UPDATED:
            [alert setTitle:NSLocalizedString(@"No need to update !",@"")];
            [alert setMessage:NSLocalizedString(@"Scores online were already up-to-date.",@"")];
            [prefs setInteger:0 forKey:@"needsSync"];
            [self refreshSlopes:YES];
            [alert show];
            break;
        case NO_SCORES_REGISTERED:
            [alert setTitle:NSLocalizedString(@"No rankings available !",@"")];
            [alert setMessage:NSLocalizedString(@"You don't have any scores saved online for this race in \"speed only\" mode for the moment !",@"")];
            [(TRRankingDelegate*)[rankingsTableView delegate] resetData];
            [rankingsTableView reloadData];
            [alert show];
            break;
        case RANKINGS_OK:
            //Do nothing
            break;
        default:
            [alert setMessage:NSLocalizedString(@"Unknown error!",@"")];
            [alert show];
            break;
    }
    [alert release];
}

- (void) treatData:(NSString*) data {
    //[[[allCountries componentsSeparatedByString:@"|||"] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] retain];
    //Sur chaque ligne, une série de data séparés par le symbole  |||
    //chaaque ligne est materialisee par \r\n
    //les lignes sont séparées en paquets, chacuns séparés par un \r\t\n\r\t\n
    //paquet n°1 : nom du pays
    //paquet n°2, 3 et 4 sur chaque ligne, nomdelapiste|||friendsRanking|||countryRanking|||worldRanking
    //paquer n°5 : une ligne, Status de la requete
    //Mais en cas d'erreur de conection, il n'y a qu'une seule ligne qui contient @"\r\t\n\r\t\n" puis le numéro de l'erreur
    if (![data isEqualToString:@""]) {
        NSArray* datas = [data componentsSeparatedByString:@"\r\t\n\r\t\n"];
        //On traite l'éventuelle erreur
        if([datas count] < 2)
            [self treatError:[NSString stringWithFormat:@"%d", SERVER_ERROR]];
        else
        {
            [self treatError:[datas objectAtIndex:1]];
            if ([[datas objectAtIndex:1] intValue] == RANKINGS_OK) {
                //on recupere la liste des pistes
                [_listOfCourses release];
                _listOfCourses = [[[datas objectAtIndex:0] componentsSeparatedByString:@"\r\n"] retain];
                
                //save cache
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                if ([self.orderType isEqualToString:@"speed only"])
                    [prefs setObject:data forKey:@"rankingCacheSpeedOnly"];
                else
                    [prefs setObject:data forKey:@"rankingCache"];
                //reload data
                [slopesTableView reloadData];
            }
        }
    }
    else {
        [_listOfCourses release];
        _listOfCourses=[[NSMutableArray alloc] init];
        [slopesTableView reloadData];
    }
}



- (void) treatSaveScoreAfterRaceResult:(NSString*)result {
    NSArray* datas = [result componentsSeparatedByString:@"\r\n"];
    if ([datas count]==3){
        NSString* erreur = [datas objectAtIndex:2];
        [_currentRankings release];
        [_currentPercentage release];
        _currentRankings = [[[datas objectAtIndex:0] componentsSeparatedByString:@"|||"] retain];
        _currentPercentage = [[[datas objectAtIndex:1] componentsSeparatedByString:@"|||"] retain];
        [self treatError:erreur];
    } else [self treatError:[NSString stringWithFormat:@"%d",SERVER_ERROR ]];
}

- (void) treatDisplayRankingsAfterRaceResult:(NSString*)result {
    NSArray* datas = [result componentsSeparatedByString:@"\r\n"];
    if ([datas count]==3){
        NSString* erreur = [datas objectAtIndex:2];
        [_currentRankings release];
        [_currentPercentage release];
        _currentRankings = [[[datas objectAtIndex:0] componentsSeparatedByString:@"|||"] retain];
        _currentPercentage = [[[datas objectAtIndex:1] componentsSeparatedByString:@"|||"] retain];
        [self treatError:erreur];
    } else [self treatError:[NSString stringWithFormat:@"%d",SERVER_ERROR ]];
    //Set this to true so the user car go back to race select screen by touching the screen
    g_game.rankings_displayed=true;
}

- (void) treatSyncScoresResult:(NSString*)result {
    NSArray * results = [result componentsSeparatedByString:@"\r\t\n\r\t\n"];
    if([results count] < 2) return;
    
    NSString* error = [results objectAtIndex:1];

    if ([error intValue]==SCORE_UPDATED) {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setInteger:0 forKey:@"needsSync"];
        [self refreshSlopes:TRUE];
    } else [self treatData:result];
}

#pragma mark refreshing functions

- (IBAction) refreshSlopesView:(id)sender {
    [self refreshSlopes:NO];
}

- (void) refreshSlopes:(BOOL)syncIfNeeded {
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    //Si un cache existe, on l'utilise
    if ([self.orderType isEqualToString:@"speed only"]) {
            [(scoresController*)[slopesTableView delegate] treatData:[prefs objectForKey:@"rankingCacheSpeedOnly"]];
    } else {
            [(scoresController*)[slopesTableView delegate] treatData:[prefs objectForKey:@"rankingCache"]];
    }
    
    //Si certains scores n'ont pas été sauvegardés en ligne, on averti l'utilisateur et on lui propose d'abord de le faire
    if ([prefs boolForKey:@"needsSync"]>0 && syncIfNeeded) {
        UIActionSheet* alert = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Unsaved scores detected. Do you want to save them online now ?",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"No",@"") destructiveButtonTitle:NSLocalizedString(@"Yes",@"") otherButtonTitles:nil];
        [alert setActionSheetStyle:UIActionSheetStyleBlackOpaque];
        [alert showInView:transitionView];
        [alert release];
    }
    else {
        ConnectionController* conn = [[[ConnectionController alloc] init] autorelease];
        NSMutableString* queryString = [NSMutableString stringWithFormat:@"login=%@&mdp=%@&order=%@",[prefs objectForKey:@"username"],[prefs objectForKey:@"password"],self.orderType];
        //Si le joueur ajouté des amis
        int i;
        for (i = 0; i<[[prefs objectForKey:@"friendsList"] count]; i++) {
            [queryString appendFormat:@"&friends[%d]=%@",i,[[prefs objectForKey:@"friendsList"] objectAtIndex:i]];
        }
        [conn postRequest:queryString atURL:[tuxRiderRootServer stringByAppendingString:@"displaySlopes.php"] withWaitMessage:NSLocalizedString(@"Refreshing rankings...",@"") sendResponseTo:self withMethod:@selector(treatData:)];
    }
}

- (void) refreshRankings {
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    //Si un cache existe, on l'utilise
    if ([self.orderType isEqualToString:@"speed only"]) {
        [(TRRankingDelegate*)[rankingsTableView delegate] treatData:[prefs objectForKey:[_currentSlope stringByAppendingString:@"SpeedOnly"]]];
    } else {
        [(TRRankingDelegate*)[rankingsTableView delegate] treatData:[prefs objectForKey:_currentSlope]];
    } 

    ConnectionController* conn = [[[ConnectionController alloc] init] autorelease];
    
    NSMutableString* queryString = [NSMutableString stringWithFormat:@"login=%@&mdp=%@&piste=%@&order=%@",[prefs objectForKey:@"username"],[prefs objectForKey:@"password"],_currentSlope,self.orderType];
    
    //Si le joueur ajouté des amis
    int i;
    for (i = 0; i<[[prefs objectForKey:@"friendsList"] count]; i++) {
        [queryString appendFormat:@"&friends[%d]=%@",i,[[prefs objectForKey:@"friendsList"] objectAtIndex:i]];
    }
    [conn postRequest:queryString atURL:[tuxRiderRootServer stringByAppendingString:@"displayRanking.php"] withWaitMessage:NSLocalizedString(@"Refreshing ranking infos...",@"") sendResponseTo:[rankingsTableView delegate] withMethod:@selector(treatData:)];
}

#pragma mark actionSheet delegate
//this is only for the alert view concerning syncronizing
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
            //Yes
        case 0:
            [self syncScores];
            break;
            //No
        case 1:
            [self refreshSlopes:NO];
            break;
        default:
            break;
    }
}

#pragma mark tableView delegate for slopesView

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _currentSlope=[[(TRSlopeInfoCell*)[tableView cellForRowAtIndexPath:indexPath] titleLabel] text];
    [(TRRankingDelegate*)[rankingsTableView delegate] navTitle:_currentSlope];
    
    //On affiche les rankings
    [self displayRankings:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark UITabBarDelegate
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(TRTabBarItem *)item {
    self.orderType=item.orderType;
    [self refreshSlopes:NO];
}

#pragma mark UITableViewDataSource for slopesView
//Pour la première table view, celle qui affiche toutes les pistes
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_listOfCourses count];
}

- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellAccessoryDetailDisclosureButton;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TRSlopeInfoCell *cell = (TRSlopeInfoCell*)[tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if (cell == nil)
    {
        cell = [[[TRSlopeInfoCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"cellID"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    NSArray* data = [[_listOfCourses objectAtIndex:indexPath.row] componentsSeparatedByString:@"|||"];
    [cell setData:data];
    [cell setSelected:NO];
    
    return cell;
}
#pragma mark UITableViewDataSource for rankingsView defined in TRRankingDelegate

@end

