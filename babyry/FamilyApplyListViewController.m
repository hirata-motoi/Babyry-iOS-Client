//
//  FamilyApplyListViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/02.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "FamilyApplyListViewController.h"

@interface FamilyApplyListViewController ()

@end

@implementation FamilyApplyListViewController

@synthesize inviterUsers;

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
    
    // デリゲートメソッドをこのクラスで実装する
    self.familyApplyList.delegate = self;
    self.familyApplyList.dataSource = self;
    
    [self showFamilyApplyList];
    
    [self.closeFamilyApplyListButton addTarget:self action:@selector(closeFamilyApplyList) forControlEvents:UIControlEventTouchUpInside];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showFamilyApplyList
{
    NSLog(@"inviteeUserId : %@", [PFUser currentUser][@"userId"]);
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyApply"];
    [query whereKey:@"inviteeUserId" equalTo:[PFUser currentUser][@"userId"]];
    NSArray * objects = [query findObjects];
    if (objects.count < 1) {
        NSLog(@"招待したユーザが存在しない");
    } else {
        NSLog(@"found invite user");
        NSString *inviterUserId = objects[0][@"userId"];
        NSMutableArray * inviterUserIds = [[NSMutableArray alloc] init];
        for (int i = 0; i < objects.count; i++) {
            NSString *inviterUserId = objects[i][@"userId"];
            [inviterUserIds addObject:inviterUserId];
        }
        
        [self setupInviterUsers:inviterUserIds];
    }
}

- (void)setupInviterUsers: (NSMutableArray *)inviterUserIds
{
    PFQuery *query = [PFQuery queryWithClassName:@"_User"];
    [query whereKey:@"userId" containedIn:inviterUserIds];
    NSArray *objects = [query findObjects];
    inviterUsers = objects;
    NSLog(@"inviterUsers : %@", objects);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // テーブルに表示するデータ件数を返す;
    return inviterUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"tableView");
    static NSString *CellIdentifier = @"Cell";
    // 再利用できるセルがあれば再利用する
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        // 再利用できない場合は新規で作成
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = self.inviterUsers[indexPath.row][@"username"];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame = CGRectMake(250, 10, 50, 30);
    [btn setTitle:@"承認" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(admit:event:) forControlEvents:UIControlEventTouchDown];
    [cell.contentView addSubview:btn];
    
    UIButton *rejectBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    rejectBtn.frame = CGRectMake(190, 10, 50, 30);
    [rejectBtn setTitle:@"保留" forState:UIControlStateNormal];
    [rejectBtn addTarget:self action:@selector(reject:event:) forControlEvents:UIControlEventTouchDown];
    [cell.contentView addSubview:rejectBtn];
    
    return cell;
};

- (void)closeFamilyApplyList
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)admit: (UIButton *)sender event:(UIEvent *)event
{
    NSLog(@"admit");
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint point = [touch locationInView:_familyApplyList];
    NSIndexPath *indexPath = [_familyApplyList indexPathForRowAtPoint:point];
    
    NSLog(@"update start");
    
    // 自分の行のfamilyIdを更新
    PFObject *inviterUser = [inviterUsers objectAtIndex:indexPath.row];
    NSLog(@"inviterUser : %@", inviterUser);
    NSString *familyId = inviterUser[@"familyId"];

    PFUser *selfUser = [PFUser currentUser];
    selfUser[@"familyId"] = familyId;
    NSLog(@"save user");
    [selfUser save];
    
    // FamilyApplyから消す
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyApply"];
    [query whereKey:@"inviteeUserId" equalTo:selfUser[@"userId"]];
    [query whereKey:@"familyId" equalTo:familyId];
    NSArray *familyApplyRows = [query findObjects];
    NSLog(@"delete familyApply : %@", familyApplyRows);
    for (int i = 0; i < familyApplyRows.count; i++) {
        PFObject *row = [familyApplyRows objectAtIndex:i];
        [row delete];
    }
    NSLog(@"delete FamilyApply succeeded");
    [self closeFamilyApplyList];
}

- (void)reject: (UIButton *)sender event:(UIEvent *)event
{
    NSLog(@"reject");
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint point = [touch locationInView:_familyApplyList];
    NSIndexPath *indexPath = [_familyApplyList indexPathForRowAtPoint:point];

    // 自分の行のfamilyIdを更新
    PFObject *inviterUser = [inviterUsers objectAtIndex:indexPath.row];
    NSString *familyId = inviterUser[@"familyId"];
    PFUser *selfUser = [PFUser currentUser];
    
    NSLog(@"delete family apply start");
    
    // FamilyApplyから消す
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyApply"];
    [query whereKey:@"inviteeUserId" equalTo:selfUser[@"userId"]];
    [query whereKey:@"familyId" equalTo:familyId];
    [query whereKey:@"userId" equalTo:inviterUser[@"userId"]];
    PFObject *familyApplyRow = [query getFirstObject];
    [familyApplyRow delete];
    NSLog(@"rejecte && delete familyApply: %@", familyApplyRow);
    [self closeFamilyApplyList];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
