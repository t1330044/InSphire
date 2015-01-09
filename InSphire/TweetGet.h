//
//  TweetGet.h
//  InSphire
//
//  Created by 児玉研究室 on 2014/12/14.
//  Copyright (c) 2014年 kodamalab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@interface TweetGet : NSObject{
    NSArray *tweets;
}

@property NSInteger accountNum;   //アカウント数
@property NSString *tweetText;    //ツイート文の抽出
@property NSString *userName;     //ユーザー名の出力
@property UIImage *userPic;       //ユーザーのアイコン出力
@property NSInteger forSoundMode; //０デフォ・１ポジ・２ネガ・３おとなしい・４うるせえ！ の５種類

- (void)getTimeLine:(NSInteger)accountIndex;

@end
