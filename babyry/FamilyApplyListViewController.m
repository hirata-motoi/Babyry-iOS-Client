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
#import "PushNotification.h"
#import "ChildFilterViewController.h"

@interface FamilyApplyListViewController ()

@end

@implementation FamilyApplyListViewController {
    NSMutableDictionary *childInfoByFamily;
    MBProgressHUD *hud;
}

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
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"申請データ確認";
    
    familyApplys = [[NSMutableDictionary alloc]init];
    PFQuery *query = [PFQuery queryWithClassName:@"PartnerApplyList"];
    [query whereKey:@"familyId" equalTo:[PFUser currentUser][@"familyId"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (objects.count < 1) {
            [self showNoApplyMessage];
            [hud hide:YES];
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
            [self showErrorAlert];
            [self disableAdmitButton];
            [hud hide:YES];
        }
        
    }];
}

- (void)setupInviterUsers: (NSMutableArray *)inviterUserIds
{
    PFQuery *query = [PFQuery queryWithClassName:@"_User"];
    [query whereKey:@"userId" containedIn:inviterUserIds];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in setupInviterUsers : %@", error]];
            [hud hide:YES];
            [self showErrorAlert];
            [self disableAdmitButton];
            return;
        }
        if (!objects || [objects count] < 1) {
            [Logger writeOneShot:@"crit" message:@"Error in setupInviterUsers : There is no Inviter"];
            [hud hide:YES];
            return;
        }
        inviterUsers = objects;
        [_familyApplyList reloadData];
        
        [self setupChildInfo];
    }];
}

- (void)setupChildInfo
{
    NSMutableArray *familyIds = [[NSMutableArray alloc]init];
    for (PFObject *inviterUser in inviterUsers) {
        if (inviterUser[@"familyId"]) {
            [familyIds addObject:inviterUser[@"familyId"]];
        }
    }
    
    // self familyId
    [familyIds addObject:[PFUser currentUser][@"familyId"] ];
   
    childInfoByFamily = [[NSMutableDictionary alloc]init];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    [query whereKey:@"familyId" containedIn:familyIds];
    [query findObjectsInBackgroundWithBlock:^(NSArray *childObjectList, NSError *error){
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to get Child familyIds:%@ error:%@", familyIds, error]];
            [hud hide:YES];
            [self showErrorAlert];
            [self disableAdmitButton];
            return;
        }
        
        if (childObjectList.count < 1) {
            [hud hide:YES];
            return;
        }

        for (PFObject *child in childObjectList) {
            if (!childInfoByFamily[ child[@"familyId"] ]) {
                childInfoByFamily[ child[@"familyId"] ] = [[NSMutableDictionary alloc]init];
            }
            childInfoByFamily[ child[@"familyId"] ][child.objectId] = [[NSMutableDictionary alloc]init];
            childInfoByFamily[ child[@"familyId"] ][child.objectId][@"object"] = child;
            
            // 写真アップ枚数
            [self setupImageCount:child];
        }
    }];
}

- (void)setupImageCount:(PFObject *)child
{
    NSInteger childImageShardIndex = [child[@"childImageShardIndex"] integerValue];
    PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%d", childImageShardIndex]];
    [query whereKey:@"imageOf" equalTo:child.objectId];
    [query whereKey:@"bestFlag" notEqualTo:@"removed"];
    query.limit = 1000;
    [query countObjectsInBackgroundWithBlock:^(int count, NSError *error){
        childInfoByFamily[ child[@"familyId"] ][child.objectId][@"imageCount"] = [NSNumber numberWithInt:count];
        // ぐるぐるを隠す
        [hud hide:YES];
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
    FamilyApplyListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
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

- (void)admit: (NSInteger)index
{
    NSString *inviterFamilyId = inviterUsers[index][@"familyId"];
    // 相手が「招待された人」からはじめた場合
    if (!inviterFamilyId) {
        [self executeAdmit:[NSNumber numberWithInteger:index] withChildFamilyMap:nil];
        return;
    }
    
    ChildFilterViewController *childFilterViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChildFilterViewController"];
    childFilterViewController.delegate = self;
    childFilterViewController.indexNumber = [NSNumber numberWithInteger:index];
    childFilterViewController.childList = [self createChildListForFilter:inviterUsers[index]];
    [self addChildViewController:childFilterViewController];
    [self.view addSubview:childFilterViewController.view];
}

- (NSMutableArray *)createChildListForFilter:(PFObject *)inviter
{
    NSMutableDictionary *childList = [[NSMutableDictionary alloc]init];
    NSString *selfFamilyId = [PFUser currentUser][@"familyId"];
    NSString *inviterFamilyId = inviter[@"familyId"];

    // 自分
    if (!childList[selfFamilyId]) {
        childList[selfFamilyId] = [[NSMutableDictionary alloc]init];
    }
    childList[selfFamilyId][@"childList"] = [[NSMutableArray alloc]init];
    childList[selfFamilyId][@"index"] = [NSNumber numberWithInt:1]; // 自分のこどもは基本残すはずなので下に表示
    childList[selfFamilyId][@"nameOfCreatedBy"] = [PFUser currentUser][@"nickName"];
    for (NSString *childObjectId in childInfoByFamily[selfFamilyId]) {
        PFObject *childObject = childInfoByFamily[selfFamilyId][childObjectId][@"object"];
        NSNumber *imageCount = childInfoByFamily[selfFamilyId][childObjectId][@"imageCount"];
        
        [childList[selfFamilyId][@"childList"] addObject:[NSMutableDictionary
                                                     dictionaryWithObjects:@[childObject[@"name"], childObjectId, childObject[@"childImageShardIndex"], [NSNumber numberWithBool:YES], imageCount]
                                         forKeys:@[@"name", @"childObjectId", @"childImageShardIndex", @"selected", @"imageCount"]]];
    }
    
    // 申請者
    if (!childList[inviterFamilyId]) {
        childList[inviterFamilyId] = [[NSMutableDictionary alloc]init];
    }
    childList[inviterFamilyId][@"childList"] = [[NSMutableArray alloc]init];
    childList[inviterFamilyId][@"index"] = [NSNumber numberWithInt:0];
    childList[inviterFamilyId][@"nameOfCreatedBy"] = inviter[@"nickName"];
    for (NSString *childObjectId in childInfoByFamily[inviterFamilyId]) {
        PFObject *childObject = childInfoByFamily[inviterFamilyId][childObjectId][@"object"];
        NSNumber *imageCount = childInfoByFamily[inviterFamilyId][childObjectId][@"imageCount"];
        
        [childList[inviterFamilyId][@"childList"] addObject:[NSMutableDictionary
                                                     dictionaryWithObjects:@[childObject[@"name"], childObjectId, childObject[@"childImageShardIndex"], [NSNumber numberWithBool:YES], imageCount]
                                         forKeys:@[@"name", @"childObjectId", @"childImageShardIndex", @"selected", @"imageCount"]]];
    }
    
    // 自分のこどもが後になるようにsort
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
    NSMutableArray *sortedChildren = [[childList allValues] sortedArrayUsingDescriptors:@[sortDescriptor]];
    return sortedChildren;
}

- (void)executeAdmit:(NSNumber *)indexNumber withChildFamilyMap:(NSMutableDictionary *)childFamilyMap
{
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"データ更新";
    
    NSInteger index = [indexNumber integerValue];
    // FamilyRoleのchooserにapplyingUserIdを突っ込む
    PFQuery *familyRole = [PFQuery queryWithClassName:@"FamilyRole"];
    [familyRole whereKey:@"familyId" equalTo:[PFUser currentUser][@"familyId"]];
    [familyRole getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (error) {
            // かならず一つが見つかるはず
            // エラーならレコード作るでも良いけど、やり過ぎな気はする
            [Logger writeOneShot:@"cirt" message:[NSString stringWithFormat:@"Error in find familyRole : %@", error]];
            [hud hide:YES];
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
                [hud hide:YES];
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
            
            [self updateFamilyIdOfChild:childFamilyMap];
            
            [Tutorial forwardStageWithNextStage:@"tutorialFinished"];
            [hud hide:YES];
            
            // push通知
            NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
            transitionInfoDic[@"event"] = @"admitApply";
            NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
            options[@"formatArgs"] = [NSArray arrayWithObject:[PFUser currentUser][@"nickName"]];
            NSMutableDictionary *data = [[NSMutableDictionary alloc]init];
            options[@"data"] = data;
            data[@"transitionInfo"] = transitionInfoDic;
            [PushNotification sendToSpecificUserInBackground:@"admitApply" withOptions:options targetUserId:[inviterUsers objectAtIndex:index][@"userId"]];
            
            NSNotification *n = [NSNotification notificationWithName:@"didAdmittedPartnerApply" object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:n];
            
            [self closeFamilyApplyList];
        }];
    }];
}

- (void)showNoApplyMessage
{
    _noApplyMessageView.hidden = NO;
}

- (void)updateFamilyIdOfChild:(NSMutableDictionary *)childFamilyMap
{
    NSArray *childObjectIdList = [childFamilyMap allKeys];
    if (childObjectIdList.count < 1) {
        return;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    [query whereKey:@"objectId" containedIn:childObjectIdList];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to get child:%@ error:%@", childObjectIdList, error]];
            return;
        }
        
        if (objects.count < 1) {
            [Logger writeOneShot:@"warn" message:[NSString stringWithFormat:@"Child not found :%@", childObjectIdList]];
            return;
        }
        
        for (PFObject *child in objects) {
            child[@"familyId"] = childFamilyMap[child.objectId];
            [child saveInBackground];
        }
    }];
}

- (void)showErrorAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ネットワークエラー"
                                                    message:@"ネットワークエラーが発生しました。\n再度お試しください。"
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil
                          ];
    [alert show];
}

- (void)disableAdmitButton
{
    for (FamilyApplyListCell *cell in [_familyApplyList visibleCells]) {
        cell.admitButton.enabled = NO;
    }
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
