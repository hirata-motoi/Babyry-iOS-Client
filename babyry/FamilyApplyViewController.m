//
//  FamilyApplyViewController.m
//  babyry
//
//  Created by Motoi Hirata on 2014/06/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "FamilyApplyViewController.h"
#import "IdIssue.h"

@interface FamilyApplyViewController ()

@end

@implementation FamilyApplyViewController
@synthesize searchedUserObject;

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
    
    [self.closeFamilyApplyModal addTarget:self action:@selector(closeFamilyApply) forControlEvents:UIControlEventTouchUpInside];
    [self showSelfUserId];
    [self.searchButton addTarget:self action:@selector(executeSearch) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)closeFamilyApply
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showSelfUserId
{
    self.selfUserId.text = [PFUser currentUser][@"userId"];
}

- (void)executeSearch
{
    NSString * inputtedUserId = [self.searchForm.text mutableCopy];
    // search用APIを叩いてユーザを検索
    //NSNumber * userIdNumber = [NSNumber numberWithInt:[inputtedUserId intValue]];

    // デフォルトのテーブルは_が必要！？
    PFQuery * query = [PFQuery queryWithClassName:@"_User"];
    
    [query whereKey:@"userId" equalTo:inputtedUserId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error){
            NSLog(@"Successfully searched %@", objects);
            if (objects.count < 1) {
                NSLog(@"no result");
                [self showSearchNoResult];
            } else {
                NSLog(@"found");
                [self showSearchResult:[objects objectAtIndex:0]];
            }
        } else {
            NSLog(@"error occured %@", error);
        }
    }];
}

- (void)showSearchNoResult
{
//    self.searchedResultCell.textLabel.text = @"no result";
    UILabel * labelNoResult = [[UILabel alloc]initWithFrame:CGRectMake(40, 250, 200, 40)];
    labelNoResult.text = @"no result";
    [self.view addSubview:labelNoResult];
}

- (void)showSearchResult:(PFObject *)searchedUser
{
    // 結果を表示 user_nameと申請ボタンを表示する
    UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(10, 250, 200, 40)];
    label.text = searchedUser[@"username"];
    
    UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(230, 250, 50, 40);
    [button setTitle:@"申請" forState:UIControlStateNormal];
    
    // 対象ユーザのPFObjectを保持
    NSLog(@"%@", searchedUser);
    searchedUserObject = searchedUser;
    
    // ボタンを押したときのイベント
    [button addTarget:self action:@selector(apply) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:button];
    [self.view addSubview:label];
}

// family申請を出す
- (void)apply
{
    NSLog(@"apply start");
        
    // 相手が既にfamilyになっているかを確認
    PFQuery *query = [PFQuery queryWithClassName:@"_User"];
    [query whereKey:@"userId" equalTo:searchedUserObject[@"userId"]];
    NSLog(@"query : %@", query);
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error){
            NSLog(@"Successfully searched FamilyApply %@", objects);
            NSLog(@"objects.count : %d", objects.count);
            if (objects.count < 1) {
                NSLog(@"ユーザがいないよ");
            } else if ([objects objectAtIndex:0][@"familyId"] == NULL) {
                // familyになっていないので申請を送ってOK
                [self sendApply];
            } else {
                NSLog(@"すでにfamilyIdをもってるので申請できない");
                // 既にfamilyになっているので申請をおくっちゃダメ
                [self showErrorMessage:@"このユーザに申請を送ることはできません"];
            }
        } else {
            // 何らかのエラーが出たので、「エラーですぞ！」とユーザに教えてあげる
            NSLog(@"error occured %@", error);
            [self showErrorMessage:@"エラーが発生しました"];
        }
    }];
}

- (NSString*) createFamilyId
{
    IdIssue *idIssue = [[IdIssue alloc]init];
    return [idIssue issue:@"family"];
}

- (void)sendApply
{
    NSString *familyId = [self createFamilyId];
    
    NSLog(@"familyId : %@", familyId);
    
    searchedUserObject[@"familyId"] = familyId;
    
    PFObject *currentUser = [PFUser currentUser];
    // userテーブルの自分のレコードを更新
    currentUser[@"familyId"] = familyId;
    [currentUser save];
    // OKだったらfamilyApplyへinesrt
    PFObject *familyApply = [PFObject objectWithClassName:@"FamilyApply"];
    familyApply[@"userId"] = currentUser[@"userId"];
    familyApply[@"inviteeUserId"] = searchedUserObject[@"userId"];
    familyApply[@"status"] = @"applying"; // 申請中
    familyApply[@"familyId"] = familyId;
    NSLog(@"familyApply : %@", familyApply);
    [familyApply save];
    // そのうちpush通知送る
    
    [self closeFamilyApply];
}

- (void)showErrorMessage:(NSString*)message
{
    // 受け取ったmessageを表示する
}

@end
