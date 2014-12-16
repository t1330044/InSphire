//
//  ViewController.m
//  InSphire
//
//  Created by 児玉研究室 on 2014/11/06.
//  Copyright (c) 2014年 kodamalab. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SEManager.h"  //音声自動生成 ＆ 再生クラス
#import "TweetGet.h"   //ツイート関連のプロパティ生成

@interface ViewController ()

//インスタンス変数宣言ーーーーーーーーーーーーーー
{
    //マイク用のキュー
    AudioQueueRef queue;
    
    //ツイート管理用の親元クラス
    TweetGet *tweet;
    NSInteger accountIndex;  // クラスでアカウント指定するための引数　これ変更すれば他のアカウントに設定できる　　　★ここ未実装！！
    NSInteger soundMode;     // どの音声を鳴らすかグループを選択
    
    //加速度ハンドラ
    CMMotionManager *motionManager;
    double xac, xac_pre1, xac_pre2;
    double yac, yac_pre1, yac_pre2;
    double zac, zac_pre1, zac_pre2;
}


//音声　個別宣言ーーーーーーーーーーーーーーーーー過去の遺物　イラネ
/*
@property AVAudioPlayer *pianoZC;
*/

@end






@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 加速度CoreMotionマネージャ作る- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -加速度
    if (! motionManager) {
        motionManager = [[CMMotionManager alloc] init];
        motionManager.deviceMotionUpdateInterval = 1/20;
    }
    
    // Twitter関連の初期設定- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -Twitter　と　音声モード初期
    tweet = [[TweetGet alloc] init];
    accountIndex = 0;
    soundMode = 20;
//    [tweet getTimeLine:accountIndex];
    [self tweetRefresh];
    
    /* 音声　読み込み- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -過去の遺物　イラネ
    NSString *passPa = [[NSBundle mainBundle] pathForResource:@"water_small" ofType:@"mp3"];
    NSURL *passPa = [NSURL fileURLWithPath:w1Pass];
    self.pianoA = [[AVAudioPlayer alloc] initWithContentsOfURL:w1Url error:NULL];
    */
    
     // ホーム描画 初期設定- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -画面設定
    CGRect rectHome1 = CGRectMake(10, 10, 500, 500);
    UIImageView *homeView = [[UIImageView alloc]initWithFrame:rectHome1];
    homeView.contentMode = UIViewContentModeCenter;
    // 画像の読み込み
    homeView.image = [UIImage imageNamed:@"ball_bg.png"];
    // UIImageViewのインスタンスをビューに追加
    [self.view addSubview:homeView];
    
   
    // サーチボタン描画 初期設定
    //search
    UIButton *search = [UIButton buttonWithType:UIButtonTypeSystem];
    [search setImage:[UIImage imageNamed:@"heart.png"]
            forState:UIControlStateNormal];
    [search sizeToFit];
    search.center = CGPointMake(self.view.frame.size.width - 40, self.view.frame.size.height - 40);
    [self.view addSubview:search];
//    [search addTarget:self action:@selector(showBrowser) forControlEvents:UIControlEventTouchUpInside];
    
    // twitterボタン描画 初期設定
    /*
     UIButton *twitter = [UIButton buttonWithType:UIButtonTypeSystem];
     [twitter setImage:[UIImage imageNamed:@"twi_tori.png"]
     forState:UIControlStateNormal];
     [twitter sizeToFit];
     twitter.center = CGPointMake(40, self.view.frame.size.height - 40);
     [self.view addSubview:twitter];
     
     [twitter addTarget:self action:@selector(showBrowser) forControlEvents:UIControlEventTouchUpInside];
     */
/*
    [NSTimer scheduledTimerWithTimeInterval:61.0     // 勝手に動くので、unusedエラーは気にしない。と思ったらエラーなくなった。
                                                             target:self
                                                           selector:@selector(tweetRefresh)
                                                           userInfo:nil
                                                            repeats:YES];
 */
    [self setupAccelerometer];  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -加速度計測開始！！　初期設定以上！！
//    [self mikeSetting];
//    [self timerStart];
}



//マイク用初期設定ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー
static void AudioInputCallback(
                               void* inUserData,
                               AudioQueueRef inAQ,
                               AudioQueueBufferRef inBuffer,
                               const AudioTimeStamp *inStartTime,
                               UInt32 inNumberPacketDescriptions,
                               const AudioStreamPacketDescription *inPacketDescs) {
}
- (void)mikeSetting{
    AudioStreamBasicDescription dataFormat;
    dataFormat.mSampleRate = 44100.0f;
    dataFormat.mFormatID = kAudioFormatLinearPCM;
    dataFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    dataFormat.mBytesPerPacket = 2;
    dataFormat.mFramesPerPacket = 1;
    dataFormat.mBytesPerFrame = 2;
    dataFormat.mChannelsPerFrame = 1;
    dataFormat.mBitsPerChannel = 16;
    dataFormat.mReserved = 0;
    
    AudioQueueNewInput(&dataFormat,AudioInputCallback,(__bridge void *)(self),CFRunLoopGetCurrent(),kCFRunLoopCommonModes,0,&queue);
    AudioQueueStart(queue, NULL);
    
    UInt32 enabledLevelMeter = true;
    AudioQueueSetProperty(queue,kAudioQueueProperty_EnableLevelMetering,&enabledLevelMeter,sizeof(UInt32));
}

//ツイッターとマイクの更新開始ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー
- (void)timerStart{
    NSTimer *timerTwitter = [NSTimer timerWithTimeInterval:61.0
                                              target:self
                                            selector:@selector(tweetRefresh)
                                            userInfo:nil
                                             repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timerTwitter forMode:NSDefaultRunLoopMode];
    
    NSTimer *timerMike = [NSTimer timerWithTimeInterval:0.2
                                              target:self
                                            selector:@selector(updateVolume:)
                                            userInfo:nil
                                             repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timerMike forMode:NSDefaultRunLoopMode];
}
//マイク更新　タイマーで勝手に呼ばれるー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー
- (void)updateVolume:(NSTimer *)timer {
    AudioQueueLevelMeterState levelMeter;
    UInt32 levelMeterSize = sizeof(AudioQueueLevelMeterState);
    AudioQueueGetProperty(queue,kAudioQueueProperty_CurrentLevelMeterDB,&levelMeter,&levelMeterSize);
    
    NSLog(@"mPeakPower=%0.9f", levelMeter.mPeakPower);
    //   NSLog(@"mAveragePower=%0.9f", levelMeter.mAveragePower);
    
    if (levelMeter.mPeakPower >= -1.2f) {
        NSLog(@"hi!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    }else{
        NSLog(@"low");
    }
}




//ここからメソッド書き出しー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー▼▼　メソッド　▼▼

//加速度計測- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -ボール挙動用メソッド
//ーーーーーーーーーーーーーーーーーーーーー常に作動、同時にgetBoundも作動
- (void)setupAccelerometer{
    if (motionManager.accelerometerAvailable){
        // センサーの更新間隔の指定、２Hz
        motionManager.accelerometerUpdateInterval = 0.1f;
        
        // ハンドラを設定
        CMAccelerometerHandler handler = ^(CMAccelerometerData *data, NSError *error)  //ここの関数がなんども呼ばれるよ！！
        {
            // 加速度センサー
            xac = data.acceleration.x;
            yac = data.acceleration.y;
            zac = data.acceleration.z;
            
            [self getBownd];
            [self getRolling];
            soundMode = [self soundChange:tweet.tweetText.length];
        };
        
        // 加速度の取得開始
        [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
}


//バウンド計算
//ーーーーーーーーーーーーーーーーーーーーーバウンド監視して再生
- (void)getBownd{
    
    int fil_pre = 0;
    double nowAccel = 0;
    
    
    nowAccel = sqrt(xac*xac + yac*yac + zac*zac);
    
    
    if (nowAccel < 1.6) {
        fil_pre = 0;
        NSLog(@"- - %ld - -", (long)soundMode);
        NSLog(@"%@", tweet.tweetText);
    }
    
    if (nowAccel > 1.6 && nowAccel <= 2.0) {

        //-------------------------------------------------------------------強バウンド　鳴らす音の設定
        
         [[SEManager sharedManager] playSound:@"water_small.mp3"];
        
        NSLog(@"弱：%ld", (long)soundMode);
        //-------------------------------------------------------------------
    }
    if (nowAccel > 2.0 && nowAccel <= 2.4) {
        
        //-------------------------------------------------------------------強バウンド　鳴らす音の設定
        
        [[SEManager sharedManager] playSound:@"water_middle.mp3"];
        
        NSLog(@"中：%ld", (long)soundMode);
        //-------------------------------------------------------------------
    }

    if (nowAccel > 2.4) {
        
        //-------------------------------------------------------------------強バウンド　鳴らす音の設定
        
        [[SEManager sharedManager] playSound:@"water_big.mp3"];
        
        NSLog(@"強：%ld", (long)soundMode);
        //-------------------------------------------------------------------
    }
}
- (void)getRolling{
}


// twitter更新- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -Twitter管理用メソッド
- (void)tweetRefresh{
    [tweet getTimeLine:accountIndex];
//    [self soundChange:tweet.tweetText.length];
    NSLog(@"%@ : %@ : %lu", tweet.userName, tweet.tweetText, (unsigned long)tweet.tweetText.length);   //ログ出力
}

// 音声モード切り替え- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -音声切り替え
- (int)soundChange:(NSUInteger)textNum{
    if (textNum < 10) {
        return 0;
    }else if(textNum < 50){
        return 1;
    }else if(textNum < 100){
        return 2;
    }else{
        return 3;
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
