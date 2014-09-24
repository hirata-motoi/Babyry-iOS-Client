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
#import "Tutorial.h"

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
    PFQuery *query = [PFQuery queryWithClassName:@"PartnerApplyList"];
    [query whereKey:@"familyId" equalTo:[PFUser currentUser][@"familyId"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (objects.count < 1) {
            [self showNoApplyMessage];
        } else {
            NSMutableArray * applyingUserIds = [[NSMutableArray alloc] init];
            for (int i = 0; i < objects.count; i++) {
                NSString *applyingUserId = objects[i][@"applyingUserId"];
                [applyingUserIds addObject:applyingUserId];
                
                // 後からfamilyApplyのレコードを参照できるように保持しておく
                [familyApplys setObject:objects[i] forKey:applyingUserId];
            }
            
            [self setupInviterUsers:applyingUserIds];
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
    cell.emailLabel.text = self.inviterUsers[indexPath.row][@"nickName"];
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
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.labelText = @"データ更新";
    
    // FamilyRoleのchooserにapplyingUserIdを突っ込む
    PFQuery *familyRole = [PFQuery queryWithClassName:@"FamilyRole"];
    [familyRole whereKey:@"familyId" equalTo:[PFUser currentUser][@"familyId"]];
    [familyRole getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (error) {
            // かならず一つが見つかるはず
            // エラーならレコード作るでも良いけど、やり過ぎな気はする
            [Logger writeOneShot:@"cirt" message:[NSString stringWithFormat:@"Error in find familyRole : %@", error]];
            [_hud hide:YES];
            return;
        }
        
        // 自分と逆側に相手をセット
        if ([object[@"chooser"] isEqualToString:[PFUser currentUser][@"userId"]]) {
            object[@"uploader"] = [inviterUsers objectAtIndex:index][@"userId"];
        } else {
            object[@"chooser"] = [inviterUsers objectAtIndex:index][@"userId"];
        }
        [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in update chooser : %@", error]];
                [_hud hide:YES];
                return;
            }
            // PartnerApplyListから削除
            for (id key in [familyApplys keyEnumerator]) {
                [[familyApplys objectForKey:key] deleteInBackground];
            }
            // pincodeListから削除
            PFQuery *pincodeList = [PFQuery queryWithClassName:@"PincodeList"];
            [pincodeList whereKey:@"familyId" equalTo:[PFUser currentUser][@"familyId"]];
            [pincodeList findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
                if (objects) {
                    for (PFObject *object in objects) {
                        [object deleteInBackground];
                    }
                }
            }];
            // パートナーがFamilyRoleを持っていたら削除 (チュートリアルを進んだパートナーを招待した場合)
            if ([inviterUsers objectAtIndex:index][@"familyId"]) {
                PFQuery *partner = [PFQuery queryWithClassName:@"FamilyRole"];
                [partner whereKey:@"familyId" equalTo:[inviterUsers objectAtIndex:index][@"familyId"]];
                [partner findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
                    if (objects) {
                        for (PFObject *object in objects) {
                            [object deleteInBackground];
                        }
                    }
                }];
            }
            
            [Tutorial forwardStageWithNextStage:@"tutorialFinished"];
            [_hud hide:YES];
            [self closeFamilyApplyList];
        }];
    }];
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
