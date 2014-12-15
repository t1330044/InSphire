//
//  TweetGet.m
//  InSphire
//
//  Created by 児玉研究室 on 2014/12/14.
//  Copyright (c) 2014年 kodamalab. All rights reserved.
//

#import "TweetGet.h"

@implementation TweetGet

//　▼　ツイート取得のメイン処理
- (void)getTimeLine:(NSInteger)accountIndex{
    
//　▼　Twitter APIのURLを準備&叩く　ピコッてな具合に
    NSString *apiURL = @"https://api.twitter.com/1.1/statuses/user_timeline.json";     //GET api
    //NSString *apiURL = @"https://api.twitter.com/1.1/statuses/home_timeline.json";     デフォルトTL取得
    
//　▼　iOS内に保存されているTwitterのアカウント情報を取得
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType =
    [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
//　▼　ユーザーにTwitterの認証情報を使うことを確認　&　取得開始
    [store requestAccessToAccountsWithType:twitterAccountType
                                   options:nil
                                completion:^(BOOL granted, NSError *error) {
                                    
                                    //①ユーザーが拒否した場合　--------★
                                    if (!granted) {
                                        NSLog(@"Twitterへの認証が拒否されました。");
                                        [self alertAccountProblem];
                                        
                                        //ユーザーの了解が取れた場合　→　取得開始　--------★
                                    } else {
                                        //デバイスに保存されているTwitterのアカウント情報をすべて取得
                                        NSArray *twitterAccounts = [store accountsWithAccountType:twitterAccountType];
                                        
                                        if ([twitterAccounts count] > 0) { // (1)アカウントが登録されていればこの処理を開始　--------＊
                                            
            //重要 - - - - - - - - - - - -アカウント数をここで出力
                                            _accountNum = [twitterAccounts count];
                                            
                                            //0番目のアカウントを使用
                                            ACAccount *account = [twitterAccounts objectAtIndex:accountIndex];
                                            //認証が必要な要求に関する設定
                                            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
                                            [params setObject:@"1" forKey:@"include_entities"];
                                            //リクエストを生成
                                            NSURL *url = [NSURL URLWithString:apiURL];
                                            SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                                                    requestMethod:SLRequestMethodGET
                                                                                              URL:url parameters:params];
                                            //リクエストに認証情報を付加
                                            [request setAccount:account];
                                            
                                            //ステータスバーのActivity Indicatorを開始
                                            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                                            
                                            //リクエストを発行
                                            [request performRequestWithHandler:^(
                                                                                 NSData *responseData,
                                                                                 NSHTTPURLResponse *urlResponse,
                                                                                 NSError *error) {
                                                //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -Twitterからの応答がないエラー
                                                if (!responseData) {
                                                    // inspect the contents of error
                                                    NSLog(@"response error: %@", error);
                                                    
                                                //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -Twitterからの返答があった場合に全ての処理
                                                } else {
                                                    //JSONの配列を解析し、TweetをNSArrayの配列に入れる
                                                    NSError *jsonError;
                                                    tweets = [NSJSONSerialization JSONObjectWithData:responseData
                                                                                             options: NSJSONReadingMutableLeaves error:&jsonError];
           //- - -重要！！- - - - - - - - - -ここでTweet取得完了に伴い、プロパティを全て出力する- - - - - - - - - -
                                                    [self tweetTextSet];
                                                }
                                            }];
                                        } else { // (2)アカウントが登録されてないぜエラー　--------＊
                                            [self alertAccountProblem];
                                        }
                                    }
                                }];
}


//　▼　分岐（２）アカウントが登録されてないぜエラーに対応
-(void)alertAccountProblem {
    // メインスレッドで表示させる
    dispatch_async(dispatch_get_main_queue(), ^{
        //メッセージを表示
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Twitterアカウント"
                              message:@"アカウントに問題があります。今すぐ「設定」でアカウント情報を確認してください"
                              delegate:self
                              cancelButtonTitle:nil
                              otherButtonTitles:@"はい",
                              nil
                              ];
        [alert show];
    });
}

//　▼　プロパティ全て出力　&　ログで最新ツイート出力
-(void)tweetTextSet{
//セルに表示するtweetのJSONを解析し、NSDictionaryに
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
    NSDictionary *tweetMessage = [tweets objectAtIndex:[path row]];
    
//ユーザ情報を格納するJSONを解析し、NSDictionaryに
    NSDictionary *userInfo = [tweetMessage objectForKey:@"user"];
    
//テキスト抽出　&　いちおうログ出す
    _tweetText = [tweetMessage objectForKey:@"text"];                  //ツイート文抽出
    _userName = [userInfo objectForKey:@"screen_name"];                //ユーザー名出力
    
//画像セットしてみる　http://www.paper-glasses.com/api/twipi/{screen_name}/bigger
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://furyu.nazo.cc/twicon/%@/normal", _userName]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    _userPic = [UIImage imageWithData:data];                           //ユーザーアイコン出力
    
//    NSLog(@"%ld / %ld", (long)accountIndex + 1, (long)accountNum);
//    NSLog(@"%@, %lu", _tweetText, (unsigned long)_tweetText.length);
}




@end
