//
//  AudioManager.m
//  tuxracer
//
//  Created by emmanuel de roux on 26/10/08.
//  Copyright 2008 école Centrale de Lyon. All rights reserved.
//

#import "AudioManager.h"
#import "AudioToolbox/AudioServices.h"
#import "prefsController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

static AudioManager* sharedAudioManager=nil;


void playIphoneMusic(const char* context, int mustLoop){
	[[AudioManager sharedAudioManager] playMusicForContext:[NSString stringWithUTF8String:context] andLoop:mustLoop];
}

void playIphoneSound(const char* context, int isSystemSound){
	[[AudioManager sharedAudioManager] playSoundForContext:[NSString stringWithUTF8String:context] isSystemSound:isSystemSound];
}

void adjustSoundGain(const char* context, int volume){
	[[AudioManager sharedAudioManager] setVolume:volume forContext:[NSString stringWithUTF8String:context]];
}

void haltSound(const char* context){
	[[AudioManager sharedAudioManager] haltSoundForContext:[NSString stringWithUTF8String:context]];
}

void stopMusic(void){
	[[AudioManager sharedAudioManager] stopMusic];
}

#ifdef DEBUG_AUDIO
# define DBG_LOG() printf("%s %s\n", __func__, [context UTF8String])
#else
# define DBG_LOG()
#endif

@implementation AudioManager
@synthesize _currentContext;
+ (AudioManager *)sharedAudioManager
{
    if(!sharedAudioManager)
        sharedAudioManager = [[self alloc] init];
    return sharedAudioManager;
}

- (id)init
{
    self = [super init];
    if(!self) return nil;
    
	//PAS sur de ca
	AudioSessionInitialize( CFRunLoopGetCurrent(), 
                           NULL, 
                           NULL, 
                           NULL);
	sharedAudioManager=self;
    
    _playingSoundContextStack = [[NSMutableArray array] retain];
    _audioPlayersForContext = [[NSMutableDictionary dictionary] retain];
    _musicURLForContext = [[NSMutableDictionary dictionary] retain];
    _soundAudioPlayers = [[NSMutableArray array] retain];
    
	NSString* dataDir = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TRWC-data"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString* soundsDir = [dataDir stringByAppendingPathComponent:@"iPhone_sounds"];
	NSString* musicsDir = [dataDir stringByAppendingPathComponent:@"iPhone_music"];
    
    //sets defaults if no prefs exists
    [prefsController setDefaults];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString * soundsName[] = {@"tux_on_snow1.aif", @"tux_on_ice1.aif", @"tux_on_rock1.aif", @"tux_in_air1.aif" };
    NSString * soundContexts[] = { @"snow_sound",       @"ice_sound",       @"rock_sound",       @"flying_sound" };
    int i;
    for(i = 0; i < sizeof(soundsName)/sizeof(*soundsName); i++) {
        AVAudioPlayer* audioPlayer =[[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:[soundsDir stringByAppendingPathComponent:soundsName[i]]] error:NULL];
        //audioPlayer.volume = [prefs floatForKey:@"soundsVolume"];
        audioPlayer.numberOfLoops = -1;
        [_audioPlayersForContext setObject:audioPlayer forKey:soundContexts[i]];
        [_soundAudioPlayers addObject:audioPlayer];
        [audioPlayer release];
	}
    
    NSString * musicName[] = { @"start1_loop.aif", @"loading-ad_loop.aif", @"race1-rlb.aif", @"race2-jt.aif", @"wonrace1-jt.aif", @"options1-jt_loop.aif" };
    NSString * musicContexts[] = { @"start_screen",@"credits_screen",      @"racing",        @"racing2",      @"game_over" ,      @"loading"};
    
    
    for(i = 0; i < sizeof(musicName)/sizeof(*musicName); i++) {
        NSURL *musicURL = [NSURL URLWithString:[musicsDir stringByAppendingPathComponent:musicName[i]]];
        [_musicURLForContext setObject:musicURL forKey:musicContexts[i]];
	}
    
    
    
	_systemSoundIDForContext = [[NSMutableDictionary dictionary] retain];
    NSURL* soundUrl;
    SystemSoundID soundID;
    
    soundUrl = [NSURL URLWithString:[soundsDir stringByAppendingPathComponent:@"fish_pickup1.aif"]];
    AudioServicesCreateSystemSoundID ((CFURLRef)soundUrl, &soundID);
	[_systemSoundIDForContext setObject:[NSNumber numberWithInt:soundID] forKey:@"item_collect"];
    
    soundUrl = [NSURL URLWithString:[soundsDir stringByAppendingPathComponent:@"tux_hit_tree1.aif"]];
    AudioServicesCreateSystemSoundID ((CFURLRef)soundUrl, &soundID);
	[_systemSoundIDForContext setObject:[NSNumber numberWithInt:soundID] forKey:@"hit_tree"];
    
	return self;
}

- (void)dealloc
{
    [_soundAudioPlayers release];
    [_musicURLForContext release];
    for(NSNumber * num in _systemSoundIDForContext) {
        SystemSoundID soundID = [num intValue];
        AudioServicesDisposeSystemSoundID (soundID);
    }
    [_systemSoundIDForContext release];
    [_audioPlayersForContext release];
    [_currentContext release];
    [super dealloc];
}

- (void)playSoundForContext:(NSString*)context isSystemSound:(BOOL)isSS
{
    DBG_LOG();
	if (isSS)
	{
		SystemSoundID soundID = [[_systemSoundIDForContext objectForKey:context] intValue];
		AudioServicesPlaySystemSound(soundID);
	}
	else
	{
        AVAudioPlayer *audioPlayer = [_audioPlayersForContext objectForKey:context];
        assert(audioPlayer);
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        audioPlayer.volume = [prefs floatForKey:@"soundsVolume"];
        [audioPlayer play];
	}
}

- (void)haltSoundForContext:(NSString*)context
{
    DBG_LOG();
    AVAudioPlayer *audioPlayer = [_audioPlayersForContext objectForKey:context];
    assert(audioPlayer);
    [audioPlayer stop];
}

- (void)stopMusic
{
    if (_musicPlayer) {
        [_musicPlayer stop];
        [_musicPlayer release];
        _musicPlayer = nil;
    }
    
}

- (void)playMusicForContext:(NSString*)context andLoop:(BOOL)mustLoop
{
    DBG_LOG();
    
    // Change the racing music randomly
    if([context isEqualToString:@"racing"])
    {
        //Merge la musique d'intro et de race
        //Si l'intro joue déjà une des deux musiques, on n'en change pas
        if ([_currentContext isEqualToString:@"racing"]||[_currentContext isEqualToString:@"racing2"]||[_currentContext isEqualToString:@"racing3"]||[_currentContext isEqualToString:@"racing4"]||[_currentContext isEqualToString:@"racing5"]||[_currentContext isEqualToString:@"racing6"])
        {
            context=[NSString stringWithString:_currentContext];
        }
        else
        {
            //FJFJ
            /*int r = rand() % 6;
             
             switch (r) {
             case 1:
             context = @"racing";
             break;
             case 2:
             context = @"racing2";
             break;
             case 3:
             context = @"racing3";
             break;
             case 4:
             context = @"racing4";
             break;
             case 5:
             context = @"racing4";
             break;
             default:
             context = @"racing6";
             break;
             }
             */
            
            int r = rand() % 2;
            switch (r) {
                case 0:
                    context = @"racing";
                    break;
                case 1:
                    context = @"racing2";
                    break;
                default:
                    context = @"racing";
                    break;
            }
            
        }
    }
    
    if ([_currentContext isEqualToString:context]) 
        return;
    
    [_currentContext release];
    _currentContext=[[NSString stringWithString:context] retain];
    
    if (_musicPlayer) {
        [_musicPlayer stop];
        [_musicPlayer release];
        _musicPlayer = nil;
    }
    
    _musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[_musicURLForContext objectForKey:_currentContext] error:NULL];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    _musicPlayer.volume = [prefs floatForKey:@"musicVolume"];
    _musicPlayer.numberOfLoops = mustLoop ? -1 : 0;
    [_musicPlayer play];
}

- (void)setVolume:(int)volume forContext:(NSString*)context
{
    Float32 maxVolume = 128.0;
    
    AVAudioPlayer * audioPlayer = [_audioPlayersForContext objectForKey:context];
    assert(audioPlayer);
    
    DBG_LOG();
	audioPlayer.volume = (Float32)volume/maxVolume;
}


//TODO: Delete deprecated methods below
- (void)setSoundGainFactor:(Float32)gain
{
    for(AVAudioPlayer *audioPlayer in _soundAudioPlayers)
    {
        audioPlayer.volume = gain;
    }
}

- (void)setMusicGainFactor:(Float32)gain
{
    if (_musicPlayer) {
        _musicPlayer.volume = gain;
    }
}
@end
