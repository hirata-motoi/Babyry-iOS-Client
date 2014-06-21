//
//  FamilyApplyViewController.m
//  babyry
//
//  Created by Motoi Hirata on 2014/06/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "FamilyApplyViewController.h"
#import "Sequence.h"

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
    self.selfUserId.text = @"12345678";
}

- (void)executeSearch
{
    NSString * inputtedUserId = [self.searchForm.text mutableCopy];
    // search用APIを叩いてユーザを検索
    NSNumber * userIdNumber = [NSNumber numberWithInt:[inputtedUserId intValue]];

    // デフォルトのテーブルは_が必要！？
    PFQuery * query = [PFQuery queryWithClassName:@"_User"];
    
    [query whereKey:@"userId" equalTo:userIdNumber];
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

// family申請を出す 現時点では申請した時点で承認までしちゃってる
- (void)apply
{
    NSLog(@"apply start");
    NSString *familyId = searchedUserObject[@"familyId"];
    NSLog(@"%@", searchedUserObject[@"familyId"]);
    if (familyId != NULL) {
        NSLog(@"not null");
        Sequence *sequence = [[Sequence alloc]init];
        NSString *familyIdString = [sequence issueSequenceId:@"family_id"];
        
        NSLog(@"familyId : %@", familyIdString);
        
        NSNumber *familyIdNumber = [NSNumber numberWithInt:[familyIdString intValue]];
        searchedUserObject[@"familyId"] = familyIdNumber;
        
        // ほんとは1transaction内で完結させたい
        
        // あかん！！userテーブルは自分のレコードしか更新できない
        // なので、別途family_mapみたいなテーブルを作る必要がある
        [searchedUserObject saveInBackground];
        PFUser *currentUser = [PFUser currentUser];
        currentUser[@"familyId"] = familyIdNumber;
        [currentUser saveInBackground];
        
    } else {
        NSLog(@"null");
    }
}

@end
