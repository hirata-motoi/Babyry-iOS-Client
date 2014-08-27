//
//  FamilyApplyListViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/02.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "FamilyApplyListViewController.h"
#import "FamilyRole.h"
#import "Navigation.h"
#import "FamilyApplyListCell.h"
#import "Logger.h"

@interface FamilyApplyListViewController ()

@end

@implementation FamilyApplyListViewController

@synthesize inviterUsers;
@synthesize familyApplys;

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
    
    _noApplyMessageView.hidden = YES;
    
    // デリゲートメソッドをこのクラスで実装する
    self.familyApplyList.delegate = self;
    self.familyApplyList.dataSource = self;
    self.familyApplyList.tableFooterView = [[UIView alloc]init];
    
    [self showFamilyApplyList];
    [Navigation setTitle:self.navigationItem withTitle:@"パートナーからの申請" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
    
    UINib *nib = [UINib nibWithNibName:@"FamilyApplyListCell" bundle:nil];
    [_familyApplyList registerNib:nib forCellReuseIdentifier:@"Cell"];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showFamilyApplyList
{
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.labelText = @"申請データ確認";
    familyApplys = [[NSMutableDictionary alloc]init];
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyApply"];
    [query whereKey:@"inviteeUserId" equalTo:[PFUser currentUser][@"userId"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (objects.count < 1) {
            [self showNoApplyMessage];
        } else {
            NSMutableArray * inviterUserIds = [[NSMutableArray alloc] init];
            for (int i = 0; i < objects.count; i++) {
                NSString *inviterUserId = objects[i][@"userId"];
                [inviterUserIds addObject:inviterUserId];
                
                // 後からfamilyApplyのレコードを参照できるように保持しておく
                [familyApplys setObject:objects[i] forKey:inviterUserId];
            }
            
            [self setupInviterUsers:inviterUserIds];
        }
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in showFamilyApplyList : %@", error]];
        }
        
        [_hud hide:YES];
    }];
}

- (void)setupInviterUsers: (NSMutableArray *)inviterUserIds
{
    PFQuery *query = [PFQuery queryWithClassName:@"_User"];
    [query whereKey:@"userId" containedIn:inviterUserIds];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in setupInviterUsers : %@", error]];
            return;
        }
        if (!objects || [objects count] < 1) {
            [Logger writeOneShot:@"crit" message:@"Error in setupInviterUsers : There is no Inviter"];
            return;
        }
        inviterUsers = objects;
        [_familyApplyList reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // テーブルに表示するデータ件数を返す;
    return inviterUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    // 再利用できるセルがあれば再利用する
    FamilyApplyListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        // 再利用できない場合は新規で作成
        cell = [[FamilyApplyListCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
    }
    cell.emailLabel.text = self.inviterUsers[indexPath.row][@"emailCommon"];
    cell.emailLabel.font = [UIFont systemFontOfSize:18];
    cell.emailLabel.numberOfLines = 0;
    CGSize bounds = CGSizeMake(cell.emailLabel.frame.size.width, tableView.frame.size.height);
    CGSize sizeEmailLabel = [cell.emailLabel.text
                   boundingRectWithSize:bounds
                   options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                   attributes:[NSDictionary dictionaryWithObject:cell.emailLabel.font forKey:NSFontAttributeName]
                   context:nil].size;
    
    CGRect rect = cell.emailLabel.frame;
    rect.size.height = sizeEmailLabel.height;
    cell.emailLabel.frame = rect;
    cell.index = indexPath.row;
    
    cell.delegate = self;
    
    return cell;
};

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// セルの高さをtextの高さに合わせる
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FamilyApplyListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.emailLabel.text = self.inviterUsers[indexPath.row][@"emailCommon"];
    cell.emailLabel.font = [UIFont systemFontOfSize:18];
    
    // get cell height
    cell.emailLabel.numberOfLines = 0;
    CGSize bounds = CGSizeMake(cell.emailLabel.frame.size.width, tableView.frame.size.height);
    CGSize sizeEmailLabel = [cell.emailLabel.text
                              boundingRectWithSize:bounds
                              options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                              attributes:[NSDictionary dictionaryWithObject:cell.emailLabel.font forKey:NSFontAttributeName]
                              context:nil].size;
    
    return sizeEmailLabel.height + 30; // 余白30
}


- (void)closeFamilyApplyList
{
    [self.navigationController popViewControllerAnimated:YES];
}

//- (void)admit: (UIButton *)sender event:(UIEvent *)event
- (void)admit: (NSInteger)index
{
    // TODO 以下の処理がforegrandなのでくるくるが出ない。。。
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.labelText = @"データ更新";
    
    // 自分の行のfamilyIdを更新
    PFObject *inviterUser = [inviterUsers objectAtIndex:index];
    NSString *familyId = inviterUser[@"familyId"];

    // そのうちこの辺りの処理はすべてFamilyRole classに隠蔽したい
    NSString *inviterRole = [familyApplys objectForKey:inviterUser[@"userId"]][@"role"];
    NSString *uploader;
    NSString *chooser;
    if ([inviterRole isEqualToString:@"uploader"]) {
        uploader = inviterUser[@"userId"];
        chooser  = [PFUser currentUser][@"userId"];
    } else {
        uploader  = [PFUser currentUser][@"userId"];
        chooser = inviterUser[@"userId"];
    }
    
    PFUser *selfUser = [PFUser currentUser];
    selfUser[@"familyId"] = familyId;
    [selfUser save];
    
    // FamilyRoleにinsert
    NSArray *objects = [[NSArray alloc]initWithObjects:familyId, uploader, chooser , nil];
    NSArray *keys    = [[NSArray alloc]initWithObjects:@"familyId", @"uploader", @"chooser", nil];
    NSMutableDictionary *familyRoleData = [[NSMutableDictionary alloc]initWithObjects:objects forKeys:keys];
    [FamilyRole createFamilyRole:familyRoleData];
    [FamilyRole updateCache]; // 非同期でキャッシュを更新しておく
    
    // FamilyApplyから消す TODO FamilyApply classへの委譲
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyApply"];
    [query whereKey:@"inviteeUserId" equalTo:selfUser[@"userId"]];
    NSArray *familyApplyRows = [query findObjects];
    for (int i = 0; i < familyApplyRows.count; i++) {
        PFObject *row = [familyApplyRows objectAtIndex:i];
        [row delete];
    }
    [_hud hide:YES];
    [self closeFamilyApplyList];
}

- (void)showNoApplyMessage
{
    _noApplyMessageView.hidden = NO;
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
