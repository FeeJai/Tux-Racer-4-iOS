//
//  AudioManager.h
//  tuxracer
//
//  Created by emmanuel de roux on 26/10/08.
//  Copyright 2008 école Centrale de Lyon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "sharedAudioFunctions.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioManager : NSObject {
    NSMutableArray * _playingSoundContextStack;
    NSMutableArray * _soundAudioPlayers;
    NSMutableDictionary * _systemSoundIDForContext;
    NSMutableDictionary * _audioPlayersForContext;
    NSMutableDictionary * _musicURLForContext;
    AVAudioPlayer *_musicPlayer;
    NSString* _currentContext;
}

@property(nonatomic,retain) NSString* _currentContext;

+ (AudioManager *)sharedAudioManager;

- (void)setSoundGainFactor:(Float32)gain;
- (void)setMusicGainFactor:(Float32)gain;

- (void)stopMusic;

- (void)playSoundForContext:(NSString*)context isSystemSound:(BOOL)isSS;
- (void)playMusicForContext:(NSString*)context andLoop:(BOOL)mustLoop;
- (void)haltSoundForContext:(NSString*)context;
- (void)setVolume:(int)volume forContext:(NSString*)context;
@end
