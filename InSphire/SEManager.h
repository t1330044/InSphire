//
//  SEManager.h
//  InSphire
//
//  Created by 児玉研究室 on 2014/12/11.
//  Copyright (c) 2014年 kodamalab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SEManager : NSObject<AVAudioPlayerDelegate>{
    NSMutableArray *soundArray;
}

@property(nonatomic) float soundVolume;

+ (SEManager *)sharedManager;
- (void)playSound:(NSString *)soundName;

@end
