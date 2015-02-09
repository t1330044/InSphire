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
//    NSInteger soundMode;     // どの音声を鳴らすかグループを選択
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
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *soundModeLabel;


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
    NSLog(@"%@を先頭に音配列生成", [[soundNames objectAtIndex:0] objectAtIndex:0]);//確認
    
    // 加速度CoreMotionマネージャ作る- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -加速度
    if (! motionManager) {
        motionManager = [[CMMotionManager alloc] init];
        motionManager.deviceMotionUpdateInterval = 1/20;
    }
    
    // Twitter関連の初期設定- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -Twitter　と　音声モード初期
    tweet = [[TweetGet alloc] init];
    accountIndex = 3;
//    soundMode = 20;
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

    /*
    // サーチボタン描画 初期設定
    //search
    UIButton *search = [UIButton buttonWithType:UIButtonTypeSystem];
    [search setImage:[UIImage imageNamed:@"heart.png"]
            forState:UIControlStateNormal];
    [search sizeToFit];
    search.center = CGPointMake(self.view.frame.size.width - 40, self.view.frame.size.height - 40);
    [self.view addSubview:search];
//    [search addTarget:self action:@selector(showBrowser) forControlEvents:UIControlEventTouchUpInside];
     */
    
     
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
    [soundNames addObject:@[@"pianoC.wav", @"pianoE.wav", @"pianoG.wav"]];//いれとくけど使わない！
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
    
    NSTimer *timerMike = [NSTimer timerWithTimeInterval:0.1
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
    
//    NSLog(@"----------------------音量：%0.6f", levelMeter.mPeakPower);
    //   NSLog(@"mAveragePower=%0.9f", levelMeter.mAveragePower);
    
    if (levelMeter.mPeakPower >= -1.4f) {
//        NSLog(@"：：：：： hi ：：：：：");
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
//音インデックス ０投げ １バウンド ２キャッチ

//０デフォ(piano)
//１ポジ(piano_posi)
//２ネガ(piano_nega)
//３おとなしい(water)
//４うるせえ！ の５種類

//[[SEManager sharedManager] playSound:[[soundNames objectAtIndex: ( tweet.forSoundMode：自動 ) ] objectAtIndex:（ 0 1 2 強弱選択いじるのここ）]];

- (void)getBownd{

    NSLog(@"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ");
    //それぞれ前回との差を取って比較する
//    double x_gap1 = fabs(xac - xac_pre1);
//    double y_gap1 = fabs(yac - yac_pre1);
//    double z_gap1 = fabs(zac - zac_pre1);
//    double gap = x_gap1 + y_gap1 + z_gap1;
//    NSLog(@"X = %f", xac);
//    NSLog(@"Y = %f", yac);
//    NSLog(@"Z = %f", zac);
//    NSLog(@"-------------------加速度 瞬間差 : %f", gap);
    double nowAccel = sqrt(xac*xac + yac*yac + zac*zac);    NSLog(@"----------------------２乗平均値 : %f", nowAccel);



//フラグ処理
    if (nowAccel < 1.9) {//------------------------------------------------------------------------ 静止に近いなら、連続再生防止フラグリセット
        soundFlag = 0;
    }
    
    
    

    if (natureFallinFlag > 2) {                    // - - - - - - - 無重力から、キャッチとバウンドを検出 - - - - - - - - - -

//無重力ーーーーーーーー▼
        if (nowAccel < 0.5) {
            NSLog(@"　滞 空 中 ）））");
            NSLog(@"No grabity times:%d", natureFallinFlag);
            natureFallinFlag ++;
        }
        
//バウンドーーーーーーーー▼
        if (nowAccel >= 0.5 && nowAccel < 2.1 && soundFlag == 0) {
            NSLog(@"　Σ　バウンド！！");
            if (tweet.forSoundMode == 0) {
                [[SEManager sharedManager] playSound:[self printnum]];
                NSLog(@"ニュートラルモードで音鳴らすよ！：ランダム生成 %@", [self printnum]);
            }else{
                [[SEManager sharedManager] playSound:[[soundNames objectAtIndex:tweet.forSoundMode] objectAtIndex:1]];
                NSLog(@"ポジネガ静賑モードで音鳴らすよ！");
            }
            natureFallinFlag = 0;
            soundFlag = 1;
        }
        
//キャッチーーーーーーーー▼
        if (nowAccel >= 2.1 && soundFlag == 0) {
            if (tweet.forSoundMode == 0) {
                [[SEManager sharedManager] playSound:[self printnum]];
                NSLog(@"ニュートラルモードで音鳴らすよ！：ランダム生成 %@", [self printnum]);
            }else{
                [[SEManager sharedManager] playSound:[[soundNames objectAtIndex:tweet.forSoundMode] objectAtIndex:2]];
                NSLog(@"ポジネガ静賑モードで音鳴らすよ！");
            }
            NSLog(@"　Σ　キャッチ！！");
            natureFallinFlag = 0;
            soundFlag = 1;
        }
        
    }else{
//無重力ーーーーーーーー▼
        if (nowAccel < 0.5) {
            NSLog(@"　滞 空 中 ）））");
            NSLog(@"No grabity times:%d", natureFallinFlag);
            if (natureFallinFlag == 1) {
                [[SEManager sharedManager] playSound:@"hyun.wav"];
            }
            natureFallinFlag ++;
        }
        
//なんでもねえーーーーーーーー▼
        if (nowAccel >= 0.5 && nowAccel < 1.9 && soundFlag == 0) {
            NSLog(@"　ー ー ー ー ー");
            natureFallinFlag = 0;
        }

//投げた！ーーーーーーーー▼
        if (nowAccel >= 1.9 && soundFlag == 0) {
            NSLog(@"　Σ　投げた！！");
            if (tweet.forSoundMode == 0) {
                [[SEManager sharedManager] playSound:[self printnum]];
                NSLog(@"ニュートラルモードで音鳴らすよ！：ランダム生成 %@", [self printnum]);
            }else{
                [[SEManager sharedManager] playSound:[[soundNames objectAtIndex:tweet.forSoundMode] objectAtIndex:0]];
                NSLog(@"ポジネガ静賑モードで音鳴らすよ！");
            }
            natureFallinFlag = 0;
            soundFlag = 1;
        }
        
    }
    //過去の値を更新
    xac_pre1 = xac;
    yac_pre1 = yac;
    zac_pre1 = zac;

}



// ランダムでニュートラルピアノ- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSString *)printnum{
    int random_number = arc4random() % 13;//0～12の数値をランダムに取得
    NSString *piano_randum = [[NSString alloc]initWithFormat:@"piano%d.wav", random_number];
    return piano_randum;
}

// 音声モード記述切り替え- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -ラベル用
- (NSString *)change:(NSInteger)soundModeNum{
    NSString *soundModeName;
    switch (soundModeNum) {
        case 0:
        {
            soundModeName = [[NSString alloc]initWithFormat:@"NEUTRAL"];
            break;
        }
        case 1:
        {
            soundModeName = [[NSString alloc]initWithFormat:@"POSITIVE"];
            break;
        }
        case 2:
        {
            soundModeName = [[NSString alloc]initWithFormat:@"NEGATIVE"];
            break;
        }
        case 3:
        {
            soundModeName = [[NSString alloc]initWithFormat:@"CALM..."];
            break;
        }
        case 4:
        {
            soundModeName = [[NSString alloc]initWithFormat:@"LIVELY"];
            break;
        }
        default:
        {
            break;
        }
    }
    
    return soundModeName;
}



// twitter更新- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -Twitter管理用メソッド
- (void)tweetRefresh{
    [tweet getTimeLine:accountIndex];
    [NSThread sleepForTimeInterval:2.5];//読み込み待ち２秒
//    self.userNameLabel.text = tweet.userName;//---------------user name更新
    self.userNameLabel.text = [[NSString alloc]initWithFormat:@"『%@』Ball", tweet.userName];;//ボール付きのタグ
    self.tweetTextView.text = tweet.tweetText;//--------------ツイート表示更新
    self.tweetTextView.font = [UIFont systemFontOfSize:16];
    self.soundModeLabel.text = [self change:tweet.forSoundMode];

}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
