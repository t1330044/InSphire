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
    NSMutableArray *soundNames; //使うサウンド名を収録
    
    //加速度ハンドラ
    CMMotionManager *motionManager;
    double xac, xac_pre1, xac_pre2;
    double yac, yac_pre1, yac_pre2;
    double zac, zac_pre1, zac_pre2;

    //マイク音量でかいときのフラグ
    int volumeBig;
    
    //各種フラグ
    int soundFlag;   //連続再生阻止　バウンドで１化、静止で０＝鳴らしていい
    int natureFallinFlag;  //自然落下状態検出　常に０、　無重力でカウントアップ＝５回で自然バウンド、キャッチ検出に使用
}

@property (weak, nonatomic) IBOutlet UITextView *tweetTextView;


//音声　個別宣言ーーーーーーーーーーーーーーーーー過去の遺物　イラネ
/*
@property AVAudioPlayer *pianoZC;
*/

@end






@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //音の配列を作る
    [self soundSet];
    NSLog(@"%@", [[soundNames objectAtIndex:0] objectAtIndex:0]);//確認
    
    // 加速度CoreMotionマネージャ作る- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -加速度
    if (! motionManager) {
        motionManager = [[CMMotionManager alloc] init];
        motionManager.deviceMotionUpdateInterval = 1/20;
    }
    
    // Twitter関連の初期設定- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -Twitter　と　音声モード初期
    tweet = [[TweetGet alloc] init];
    accountIndex = 3;
    soundMode = 20;
    [self tweetRefresh];
    
    /* 音声　読み込み- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -過去の遺物　イラネ
    NSString *passPa = [[NSBundle mainBundle] pathForResource:@"water_small" ofType:@"mp3"];
    NSURL *passPa = [NSURL fileURLWithPath:w1Pass];
    self.pianoA = [[AVAudioPlayer alloc] initWithContentsOfURL:w1Url error:NULL];
    */
    
     // ホーム描画 初期設定- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -画面設定
    
/*    CGRect rectHome1 = CGRectMake(10, 10, 500, 500);
    UIImageView *homeView = [[UIImageView alloc]initWithFrame:rectHome1];
    homeView.contentMode = UIViewContentModeCenter;
    // 画像の読み込み
    homeView.image = [UIImage imageNamed:@"ball_bg.png"];
    // UIImageViewのインスタンスをビューに追加
    [self.view addSubview:homeView];
*/
   
    // サーチボタン描画 初期設定
    //search
    UIButton *search = [UIButton buttonWithType:UIButtonTypeSystem];
    [search setImage:[UIImage imageNamed:@"heart.png"]
            forState:UIControlStateNormal];
    [search sizeToFit];
    search.center = CGPointMake(self.view.frame.size.width - 40, self.view.frame.size.height - 40);
    [self.view addSubview:search];
//    [search addTarget:self action:@selector(showBrowser) forControlEvents:UIControlEventTouchUpInside];
    
     
    //ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー再生とマイクの競合を解除、スピーカー使用に設定！！
    AVAudioSession *audiosession = [AVAudioSession sharedInstance];
//    NSString *const AVAudioSessionCategoryPlayAndRecord;
    [audiosession setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                        error:nil];
    [audiosession setActive:YES error:nil];
    
    soundFlag = 0;
    natureFallinFlag = 0;                                    //- - - - - - - - - - - - - - - - - - -フラグの初期化
    [self setupAccelerometer];  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -加速度計測開始！！　初期設定以上！！
    
    //マイクの取得開始
    [self mikeSetting];
    
    //マイク、ツイッターのタイマー回すよ！！
    [self timerStart];
}


//音の配列作るメソッドーーーーーーーーーーーーーーーーーーー！！　ここで音の名前設定してね　！！
- (void)soundSet{
    soundNames = [NSMutableArray arrayWithCapacity:5];
//piano ０：ノーマル
    [soundNames addObject:@[@"pianoC.wav", @"pianoE.wav", @"pianoG.wav"]];
//posi  １：ポジティブ
    [soundNames addObject:@[@"posi_piano0.wav", @"posi_piano1.wav", @"posi_piano2.wav"]];
//nega  ２：ネガティブ
    [soundNames addObject:@[@"nega_piano1.wav", @"nega_piano2.wav", @"Nega_gaaan.wav"]];
//water ３：静か
    [soundNames addObject:@[@"water_small.wav", @"water_middle.wav", @"water_big.wav"]];
//piamo-2 ４：うるさい
    [soundNames addObject:@[@"xp_teren.wav", @"xp_den.wav", @"xp_dede-n.wav"]];
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

//ツイッターとマイクの更新開始ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー タイマー
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

//マイク更新　タイマーで勝手に呼ばれるー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ラベル更新あり ー ー ー ー ー ー volumeBigフラグ更新
- (void)updateVolume:(NSTimer *)timer {
    AudioQueueLevelMeterState levelMeter;
    UInt32 levelMeterSize = sizeof(AudioQueueLevelMeterState);
    AudioQueueGetProperty(queue,kAudioQueueProperty_CurrentLevelMeterDB,&levelMeter,&levelMeterSize);
    
    NSLog(@"----------------------音量：%0.6f", levelMeter.mPeakPower);
    //   NSLog(@"mAveragePower=%0.9f", levelMeter.mAveragePower);
    
    if (levelMeter.mPeakPower >= -1.4f) {
        NSLog(@"：：：：： hi ：：：：：");
        volumeBig = 1;
    }else{
//        NSLog(@"low");
        volumeBig = 0;
    }

}




//ここからメソッド書き出しー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー ー▼▼　メソッド　▼▼

//加速度計測- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -ボール挙動用メソッド
//ーーーーーーーーーーーーーーーーーーーーー常に作動、同時にgetBoundも作動 なんとsoundChangeの変数も更新
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

//            soundMode = [self soundChange:tweet.tweetText.length]; サウンドモードチェンジ
  //          self.tweetTextView.text = tweet.tweetText;//--------------ラベル表示更新
  //          self.tweetTextView.font = [UIFont systemFontOfSize:16];
            
        };
        
        // 加速度の取得開始
        [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
}



//バウンド計算
//ーーーーーーーーーーーーーーーーーーーーーバウンド監視して再生
//音インデックス ０弱 １中 ２強

//０デフォ(piano)
//１ポジ(piano_posi)
//２ネガ(piano_nega)
//３おとなしい(water)
//４うるせえ！ の５種類

//[[SEManager sharedManager] playSound:[[soundNames objectAtIndex: ( tweet.forSoundMode：自動 ) ] objectAtIndex:（ 0 1 2 強弱選択いじるのここ）]];

- (void)getBownd{


    //それぞれ前回との差を取って比較する
    double x_gap1 = fabs(xac - xac_pre1);
    double y_gap1 = fabs(yac - yac_pre1);
    double z_gap1 = fabs(zac - zac_pre1);
    double gap = x_gap1 + y_gap1 + z_gap1;
    NSLog(@"-------------------加速度 瞬間差 : %f", gap);
    //単純に二乗平均
    double nowAccel = sqrt(xac*xac + yac*yac + zac*zac);
    NSLog(@"----------------------２乗平均値 : %f", nowAccel);
    
//    NSLog(@"X = %f", xac);
//    NSLog(@"Y = %f", yac);
//    NSLog(@"Z = %f", zac);
    
    
    if(nowAccel < 0.15) {//------------------------------------------------------------------- 無重力を検出
        natureFallinFlag ++;
        NSLog(@"%d", natureFallinFlag);
    }
    
    if (gap < 1.8) {//------------------------------------------------------------------------ 静止に近いなら、連続再生防止フラグリセット
        soundFlag = 0;
        NSLog(@"%d", soundFlag);
    }
    
    
//無重力から、キャッチとバウンドを検出
    if (natureFallinFlag > 4) {
        if (gap > 2) {
            [[SEManager sharedManager] playSound:[[soundNames objectAtIndex:tweet.forSoundMode] objectAtIndex:2]];
            NSLog(@"　Σ　キャッチ！！");
            natureFallinFlag = 0;
        }
    }else{
        if (volumeBig == 0) {
            if (nowAccel > 2.0) {
                NSLog(@"--------------------------バウンド ((中))：サウンドモード：%ld", (long)tweet.forSoundMode);
            }
        }else{
            if (nowAccel > 2.0) {
                NSLog(@"--------------------------バウンド(((強)))：サウンドモード：%ld", (long)tweet.forSoundMode);
            }
        }
    }
    

/*
    if (gap > 1.8 && soundFlag == 0 && natureFallinFlag < 5) {
        //------------------------------------------------------------------- バウンド　鳴らす音の設定
        if (volumeBig == 0) {
            [[SEManager sharedManager] playSound:[[soundNames objectAtIndex:tweet.forSoundMode] objectAtIndex:1]];
            NSLog(@"--------------------------バウンド((中))：サウンドモード：%ld", (long)tweet.forSoundMode);
            NSLog(@"%d", soundFlag);
        }else{
            [[SEManager sharedManager] playSound:[[soundNames objectAtIndex:tweet.forSoundMode] objectAtIndex:2]];
            NSLog(@"--------------------------バウンド(((強)))：サウンドモード：%ld", (long)tweet.forSoundMode);
            NSLog(@"%d", soundFlag);
        }
        soundFlag = 1;
//        NSLog(@"soundFlag:%d change!", soundFlag);
    }
*/
    
    
    
    
    //過去の値を更新
    xac_pre1 = xac;
    yac_pre1 = yac;
    zac_pre1 = zac;

}
- (void)getRolling{
}


// twitter更新- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -Twitter管理用メソッド
- (void)tweetRefresh{
    [tweet getTimeLine:accountIndex];
    [NSThread sleepForTimeInterval:2.5];//読み込み待ち２秒
    self.tweetTextView.text = tweet.tweetText;//--------------ラベル表示更新
    self.tweetTextView.font = [UIFont systemFontOfSize:16];

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
