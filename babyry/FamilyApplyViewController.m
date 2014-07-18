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
@synthesize searchForm;

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
    NSLog(@"viewDidLoad start");
    self.searchContainerView.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0];
    NSLog(@"selUserIdContainer start");
    self.selfUserIdContainer.backgroundColor = [UIColor whiteColor];
    NSLog(@"closeFamilyApplyButton start");
    [self.closeFamilyApplyButton initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeFamilyApply)];
    NSLog(@"showSelfUserId start");
    [self showSelfUserId];
    
//    UIImage *btnImage = [UIImage imageNamed:@"ecalbt008_005.png"];
    [self setupSearchForm];
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
    NSString * inputtedUserId = [searchForm.text mutableCopy];
    // search用APIを叩いてユーザを検索
    PFQuery * query = [PFQuery queryWithClassName:@"_User"];
    
    [query whereKey:@"userId" equalTo:inputtedUserId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error){
            [self deleteSearchResult];
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
    UIView *result = [[UIView alloc]initWithFrame:CGRectMake(0, 10, 250, 60)];
    UILabel * labelNoResult = [[UILabel alloc]initWithFrame:CGRectMake(10, 10, 230, 40)];
    labelNoResult.text = @"ユーザがみつかりません";
    labelNoResult.textAlignment = NSTextAlignmentCenter;
    [result addSubview:labelNoResult];
    [self.searchResultContainer addSubview:result];
}

- (void)showSearchResult:(PFObject *)searchedUser
{
    UIView *result = [[UIView alloc]initWithFrame:CGRectMake(0, 10, 250, 60)];
    
    // 結果を表示 user_nameと申請ボタンを表示する
    // image
    UIImage *userImage = [UIImage imageNamed:@"NoImage"];
    UIImageView *userImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    userImageView.image = userImage;
    
    // username
    UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(70, 10, 140, 60)];
    label.text = searchedUser[@"username"];

    
    // 対象ユーザのPFObjectを保持
    NSLog(@"%@", searchedUser);
    searchedUserObject = searchedUser;

    [result addSubview:userImageView];
    [result addSubview:label];
    
    // button
    // 自分あるいは相手がfamilyIdを既に持ってたら申請はできない
    if (searchedUser[@"familyId"] == nil && [PFUser currentUser][@"familyid"] == nil) {
        // button
        UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(220, 25, 30, 25);
        [button setTitle:@"申請" forState:UIControlStateNormal];
        // ボタンを押したときのイベント
        [button addTarget:self action:@selector(apply) forControlEvents:UIControlEventTouchUpInside];
        [result addSubview:button];
    }
    
    [self.searchResultContainer addSubview:result];
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
    familyApply[@"role"] = [self getSelectedRole];

    [familyApply save];
    // そのうちpush通知送る
    
    [self closeFamilyApply];
}

- (void)showErrorMessage:(NSString*)message
{
    // 受け取ったmessageを表示する
}

- (void)setupSearchForm
{
    UIImage *formImage = [UIImage imageNamed:@"FormRounded.png"];
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, 250, 30)];
    imageView.image = formImage;
    [self.searchContainerView addSubview:imageView];

    UIButton *searchSubmitButton = [[UIButton alloc]init];
    searchSubmitButton.frame = CGRectMake(225, 10, 35, 30);
    UIImage *searchSubmitImage = [UIImage imageNamed:@"SearchButton.png"];
    [searchSubmitButton setImage:searchSubmitImage forState:UIControlStateNormal];
    [searchSubmitButton addTarget:self action:@selector(executeSearch) forControlEvents:UIControlEventTouchUpInside];
    [self.searchContainerView addSubview:searchSubmitButton];
    
    // 透明のform
    searchForm = [[UITextField alloc]initWithFrame:CGRectMake(12, 10, 215, 30)];
    searchForm.clearButtonMode = UITextFieldViewModeAlways;
    searchForm.placeholder = @"ユーザ検索";
    searchForm.keyboardType = UIKeyboardTypeASCIICapable;
    searchForm.opaque = NO;
    searchForm.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
    [self.searchContainerView addSubview:searchForm];
}

- (void)deleteSearchResult
{
    for (UIView *view in [self.searchResultContainer subviews]) {
        [view removeFromSuperview];
    }
}

- (NSString *)getSelectedRole
{
    NSString *role;
    switch(self.roleControl.selectedSegmentIndex) {
        case 0:
            // uploader
            role = @"uploader";
            break;
        case 1:
            role = @"chooser";
            break;
        default:
            role = @"uploader";
            break;
    }
    return role;
}

@end
