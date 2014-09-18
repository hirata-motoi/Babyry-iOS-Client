//
//  PartnerInviteViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PartnerInviteViewController.h"
#import "Navigation.h"
#import "Config.h"
#import "PartnerApply.h"
#import "Logger.h"
#import "PartnerApplyEntity.h"
#import "DateUtils.h"

@interface PartnerInviteViewController ()

@end

@implementation PartnerInviteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [Navigation setTitle:self.navigationItem withTitle:@"パートナー招待" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
    
    UITapGestureRecognizer *inviteByLineGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(inviteByLineGesture)];
    inviteByLineGesture.numberOfTapsRequired = 1;
    [_inviteByLine addGestureRecognizer:inviteByLineGesture];
    
    UITapGestureRecognizer *inviteByMailGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(inviteByMailGesture)];
    inviteByMailGesture.numberOfTapsRequired = 1;
    [_inviteByMail addGestureRecognizer:inviteByMailGesture];
    
    _pinCodeSaveRetryMaxCount = 2;
    _pinCodeSaveRetryCount = 0;
    
    // pinCodeのロジック
    // 招待ボタンを押した時に、pinCode発行 -> 招待メッセージ送信、という流れにすると他アプリ(LINE, Mailer)とのトランザクションは書けないので、pinCode発行したのに招待を送らない状況が起きる。
    // その為、基本的にはしょっぱなでpinCodeを発行 & PartnerApply(Parse)にレコード追加しておく (つまり、最初は1ユーザーに必ず1レコードが出来る)
    // パートナーひも付けが完了した場合にこのレコードは削除する
    // PartnerApplyに書き込んだらCoreDataに、消したらCoreDataに書き込んでおく
    NSString *PartnerApplyEntityKeyName = [Config config][@"PartnerApplyEntityKeyName"];
    PartnerApplyEntity *pae = [PartnerApplyEntity MR_findFirstByAttribute:@"name" withValue:PartnerApplyEntityKeyName];
    if (!pae || !pae.pinCode || [pae.pinCode isEqualToNumber:[NSNumber numberWithInt:0]]) {
        [self issuePinCode];
    } else {
        _pinCode = pae.pinCode;
        _displayedPinCode.text = [NSString stringWithFormat:@"%@", _pinCode];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)inviteByLineGesture
{
    NSDictionary *mailInfo = [self makeInviteBody:@"line"];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"line://msg/text/%@", mailInfo[@"text"]]]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"line://msg/text/%@", mailInfo[@"text"]]]];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"LINEを起動できません"
                              message:@"LINEがインストールされていないか、LINEを開けない状態です。\nメールで招待頂くか、\n下記の招待コードを直接パートナーにお伝えください。"
                              delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
    }
}

- (void)inviteByMailGesture
{
    NSDictionary *mailInfo = [self makeInviteBody:@"mail"];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:?Subject=%@&body=%@", mailInfo[@"title"], mailInfo[@"text"]]]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:?Subject=%@&body=%@", mailInfo[@"title"], mailInfo[@"text"]]]];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"メーラーを起動できません"
                              message:@"LINEで招待頂くか、\n下記の招待コードを直接パートナーにお伝えください。"
                              delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
    }
}

- (NSDictionary *) makeInviteBody:(NSString *)type
{
    NSMutableDictionary *mailDic = [[NSMutableDictionary alloc] init];
    NSString *inviteTitle = [Config config][@"InviteMailTitle"];
    NSString *inviteText = [[NSString alloc] init];
    if ([type isEqualToString:@"line"]) {
        inviteText = [Config config][@"InviteLineTextWithPinCode"];
    } else if ([type isEqualToString:@"mail"]) {
        inviteText = [Config config][@"InviteMailTextWithPinCode"];
    }
    NSString *inviteReplacedText = [inviteText stringByReplacingOccurrencesOfString:@"%pinCode" withString:[NSString stringWithFormat:@"%@", _pinCode]];
    mailDic[@"title"] = [inviteTitle stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    mailDic[@"text"] = [inviteReplacedText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return [[NSDictionary alloc] initWithDictionary:mailDic];
}

- (void) issuePinCode
{
    _pinCode = [[NSNumber alloc] init];
    _pinCode = [PartnerApply issuePinCode];
    _displayedPinCode.text = [NSString stringWithFormat:@"%@", _pinCode];
    [self checkDuplicatePinCode];
}

- (void) checkDuplicatePinCode
{
    PFQuery *partnerApply = [PFQuery queryWithClassName:@"PartnerApply"];
    [partnerApply whereKey:@"pinCode" equalTo:_pinCode];
    [partnerApply findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"エラーが発生しました"
                                  message:@"招待コードの発行に失敗しました。\n申し訳ありませんが再度お試しください。"
                                  delegate:nil
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
            _pinCode = 0;
            [self.navigationController popViewControllerAnimated:YES];
        }
        if ([objects count] > 0) {
            // 再帰でPinCode発行
            [self issuePinCode];
            [self checkDuplicatePinCode];
        } else {
            [self savePinCodeToParse];
        }
    }];
}

- (void) savePinCodeToParse
{
    PFObject *partnerApply = [PFObject objectWithClassName:@"PartnerApply"];
    partnerApply[@"inviterUserId"] = [PFUser currentUser][@"userId"];
    partnerApply[@"pinCode"] = _pinCode;
    [partnerApply saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in savePinCodeToParse : %@", error]];
            if (_pinCodeSaveRetryCount < _pinCodeSaveRetryMaxCount) {
                _pinCodeSaveRetryCount++;
                [self savePinCodeToParse];
            }
        }
        
        PartnerApplyEntity *pae = [PartnerApplyEntity MR_createEntity];
        pae.name = [Config config][@"PartnerApplyEntityKeyName"];
        pae.pinCode = _pinCode;
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    }];
}

@end
