//
//  GlobalSettingViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "GlobalSettingViewController.h"
#import "FamilyApplyViewController.h"
#import "FamilyApplyListViewController.h"
#import "FamilyRole.h"
#import "ImageCache.h"
#import "ProfileViewController.h"
#import "ViewController.h"
#import "IntroChildNameViewController.h"
#import "PushNotification.h"
#import "Navigation.h"

@interface GlobalSettingViewController ()

@end

@implementation GlobalSettingViewController

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
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithTitle:@""
                                             style:UIBarButtonItemStylePlain
                                             target:nil
                                             action:nil];
    _settingTableView.delegate = self;
    _settingTableView.dataSource = self;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self.closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self setupChildList];
    [self setupPartnerInfo];
    [Navigation setTitle:self.navigationItem withTitle:@"設定" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 1;
//}

- (void)close
{
    CGRect rect = self.view.frame;
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.view.frame = CGRectMake(rect.size.width, rect.origin.y, rect.size.width, rect.size.height);
                     }
                     completion:^(BOOL finished){
                         [self.view removeFromSuperview];
                         [self dismissViewControllerAnimated:YES completion:nil];
                     }];
}

- (void)logout
{
    [self.navigationController popViewControllerAnimated:YES];
    [ImageCache removeAllCache];
    [PushNotification removeSelfUserIdFromChannels:^(){
        [PFUser logOut];
        [_viewController viewDidAppear:YES];
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.textLabel.numberOfLines = 0;
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"プロフィール";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case 1:
                    cell.textLabel.text = @"あなたのパート";
                    _roleControl = [self createRoleSwitchSegmentControl];
                    [cell addSubview:_roleControl];
                    break;
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"ログアウト";
                    break;
                default:
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"パートナー検索";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case 1:
                    cell.textLabel.text = @"パートナーからの申請";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                default:
                    break;
            }
            break;
        case 3:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"こどもを追加";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount;
    switch (section) {
        case 0:
            rowCount = 2;
            break;
        case 1:
            rowCount = 1;
            break;
        case 2:
            rowCount = 2;
            break;
        case 3:
            rowCount = 1;
            break;
        default:
            break;
    }
    return rowCount;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; // 選択状態の解除
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    [self openProfileEdit];
                    break;
                case 1:
                    break;
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    [self logout];
                    [self close];
                    break;
                default:
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    [self openFamilyApply];
                    break;
                case 1:
                    [self openFamilyApplyList];
                    break;
                default:
                    break;
            }
            break;
        case 3:
            switch (indexPath.row) {
                case 0:
                    [self openAddChildAddView];
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (void)openFamilyApply
{
    FamilyApplyViewController * familyApplyViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FamilyApplyViewController"];
    //[self presentViewController:familyApplyViewController animated:true completion:nil];
    [self.navigationController pushViewController:familyApplyViewController animated:YES];
}

- (void)openFamilyApplyList
{
    FamilyApplyListViewController *familyApplyListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FamilyApplyListViewController"];
    //[self presentViewController:familyApplyListViewController animated:true completion:nil];
    [self.navigationController pushViewController:familyApplyListViewController animated:YES];
}

- (void)openAddChildAddView
{
    IntroChildNameViewController *icnvc = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroChildNameViewController"];
    icnvc.isNotFirstTime = YES;
    icnvc.currentChildNum = [[NSNumber numberWithInteger:[_childList count]] intValue];
    //[self presentViewController:icnvc animated:YES completion:NULL];
    [self.navigationController pushViewController:icnvc animated:YES];
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

- (void)switchRole
{
    NSString *role = [self getSelectedRole];
    PFObject *familyRole = [FamilyRole getFamilyRole];
    NSString *uploaderUserId = familyRole[@"uploader"];
    NSString *chooserUserId  = familyRole[@"chooser"];
    NSString *partnerUserId  = ([uploaderUserId isEqualToString:[PFUser currentUser][@"userId"]]) ? chooserUserId : uploaderUserId;

    // 連打された時に単なるtoggleだとおかしくなりそうなのでまじめにやる
    if ([role isEqualToString:@"uploader"]) {
        familyRole[@"uploader"] = [PFUser currentUser][@"userId"];
        familyRole[@"chooser"]  = partnerUserId;
    } else {
        familyRole[@"uploader"] = partnerUserId;
        familyRole[@"chooser"]  = [PFUser currentUser][@"userId"];
    }
    
    // Segment Controlをdisabled
    self.roleControl.enabled = FALSE;
    [familyRole saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
        self.roleControl.enabled = TRUE;
        [FamilyRole updateCache];
    }];
}
                     
- (UISegmentedControl *)createRoleSwitchSegmentControl
{
    // segment controlの作成
    UISegmentedControl *sc = [[UISegmentedControl alloc] initWithItems:@[@"アップ", @"チョイス"]];
    CGRect rect = sc.frame;
    rect.origin.x = 170;
    rect.origin.y = 7;
    sc.frame = rect;
    [sc addTarget:self action:@selector(switchRole) forControlEvents:UIControlEventValueChanged];
    
    // 初期値を非同期でセット
    [FamilyRole fetchFamilyRole:[PFUser currentUser][@"familyId"] withBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            if (objects.count < 1) {
                return;
            }
            PFObject *familyRole = [objects objectAtIndex:0];
            NSString *uploader = familyRole[@"uploader"];
            if ([[PFUser currentUser][@"userId"] isEqualToString:uploader]) {
                sc.selectedSegmentIndex = 0;
            } else {
                sc.selectedSegmentIndex = 1;
            }
        }
    }];
    
    return sc;
}

- (void)openProfileEdit
{
    ProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ProfileViewController"];
    
    // リクエストが増えるのは微妙だが事前に情報を取得しておく
    // partnerInfo、childともに基本キャッシュ、ネットワークがない場合はキャッシュを使う
    profileViewController.childList = _childList;
    profileViewController.partnerInfo = _partnerInfo;
    [self.navigationController pushViewController:profileViewController animated:YES];
}

- (void)setupChildList
{
    NSString *familyId = [PFUser currentUser][@"familyId"];
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    [query whereKey:@"familyId" equalTo:familyId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // TODO createdAtの昇順でsortする
            _childList = objects;
        }
    }];
}

- (void)setupPartnerInfo
{
    NSString *familyId = [PFUser currentUser][@"familyId"];
    PFQuery *query = [PFQuery queryWithClassName:@"_User"];
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    [query whereKey:@"familyId" equalTo:familyId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *user in objects) {
                if (! [user[@"userId"] isEqualToString:[PFUser currentUser][@"userId"]]) {
                    _partnerInfo = user;
                }
            }
        }
    }];
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
