//
//  ViewController.m
//  InSphire
//
//  Created by 児玉研究室 on 2014/11/06.
//  Copyright (c) 2014年 kodamalab. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "SEManager.h"
#import "TweetGet.h"

@interface ViewController ()

//インスタンス変数宣言ーーーーーーーーーーーーーー
{
    //ツイート管理用の親元クラス
    TweetGet *tweet;
    NSInteger accountIndex;  // クラスでアカウント指定するための引数　これ変更すれば他のアカウントに設定できる
    
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
    
    // Twitter関連の初期設定- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -Twitter
    tweet = [[TweetGet alloc] init];
    accountIndex = 0;
    [tweet getTimeLine:accountIndex];
    
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
    
    NSTimer *refresh = [NSTimer scheduledTimerWithTimeInterval:61.0     // 勝手に動くので、unusedエラーは気にしない。
                                                             target:self
                                                           selector:@selector(tweetRefresh)
                                                           userInfo:nil
                                                            repeats:YES];
    [self setupAccelerometer];  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -加速度計測開始！！　初期設定以上！！
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
        NSLog(@"- - - -");
    }
    
    if (nowAccel > 1.6 && nowAccel <= 2.0) {

        //-------------------------------------------------------------------強バウンド　鳴らす音の設定
        
         [[SEManager sharedManager] playSound:@"water_small.mp3"];
        
        NSLog(@"弱");
        //-------------------------------------------------------------------
    }
    if (nowAccel > 2.0 && nowAccel <= 2.4) {
        
        //-------------------------------------------------------------------強バウンド　鳴らす音の設定
        
        [[SEManager sharedManager] playSound:@"water_middle.mp3"];
        
        NSLog(@"中");
        //-------------------------------------------------------------------
    }

    if (nowAccel > 2.4) {
        
        //-------------------------------------------------------------------強バウンド　鳴らす音の設定
        
        [[SEManager sharedManager] playSound:@"water_big.mp3"];
        
        NSLog(@"強");
        //-------------------------------------------------------------------
    }
}
- (void)getRolling{
}


//加速度計測- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -Twitter管理用メソッド
- (void)tweetRefresh{
    [tweet getTimeLine:accountIndex];
}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
