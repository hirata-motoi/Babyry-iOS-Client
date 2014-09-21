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
#import "AcceptableUsePolicyViewController.h"
#import "PrivacyPolicyViewController.h"
#import "Config.h"
#import "Logger.h"
#import "Tutorial.h"
#import "TutorialNavigator.h"
#import "GlobalSettingViewController+Logic.h"
#import "GlobalSettingViewController+Logic+Tutorial.h"
#import "TmpUser.h"
#import "UserRegisterViewController.h"

@interface GlobalSettingViewController ()

@end

@implementation GlobalSettingViewController {
    TutorialNavigator *tn;
    GlobalSettingViewController_Logic *logic;
    GlobalSettingViewController_Logic_Tutorial *logicTutorial;
}

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
    
    if ([Tutorial underTutorial]) {
        logicTutorial = [[GlobalSettingViewController_Logic_Tutorial alloc]init];
        logicTutorial.globalSettingViewController = self;
    } else {
        logic = [[GlobalSettingViewController_Logic alloc]init];
        logic.globalSettingViewController = self;
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithTitle:@""
                                             style:UIBarButtonItemStylePlain
                                             target:nil
                                             action:nil];
    _settingTableView.delegate = self;
    _settingTableView.dataSource = self;
    
    [self setupPartnerInfo];
    [Navigation setTitle:self.navigationItem withTitle:@"設定" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    tn = [[TutorialNavigator alloc]init];
    tn.targetViewController = self;
    [tn showNavigationView];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [tn removeNavigationView];
    tn = nil;
}

#pragma mark - Table view data source


- (id)logic
{
    return
        (logicTutorial) ? logicTutorial :
        (logic)         ? logic         : nil;
}

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
    [[[UIAlertView alloc] initWithTitle:@""
                                message:@"ログアウトします、よろしいですか？"
                               delegate:self
                      cancelButtonTitle:@"キャンセル"
                      otherButtonTitles:@"ログアウト", nil] show];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
            break;
        case 1:
        {
            [self.navigationController popViewControllerAnimated:YES];
            [ImageCache removeAllCache];
            [PushNotification removeSelfUserIdFromChannels:^(){
                [PFUser logOut];
                [_viewController viewDidAppear:YES];
            }];
        }
            break;
    }
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
            if ([TmpUser checkRegistered]) {
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
            } else {
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
                    case 2:
                        cell.textLabel.text = @"本登録を完了する";
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        break;
                    default:
                        break;
                }
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"こどもを追加";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                default:
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"利用規約";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case 1:
                    cell.textLabel.text = @"プライバシーポリシー";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case 2:
                    cell.textLabel.text = @"お問い合わせ";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                default:
                    break;
            }
            break;
        case 3:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"ログアウト";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
    
    
    if (indexPath.section == 0 && indexPath.row == 1) {
        _partSwitchCell = cell;
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        _addChildCell = cell;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount;
    switch (section) {
        case 0:
            if ([TmpUser checkRegistered]) {
                rowCount = 2;
            } else {
                rowCount = 3;
            }
            break;
        case 1:
            rowCount = 1;
            break;
        case 2:
            rowCount = 3;
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
    
    if ([[self logic]forbiddenSelectForTutorial:indexPath]) {
        return;
    }
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    [self openProfileEdit];
                    break;
                case 1:
                    break;
                case 2:
                    [self openRegisterView];
                    break;
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    [self openAddChildAddView];
                    break;
                default:
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    [self openAcceptableUsePolicy];
                    break;
                case 1:
                    [self openPrivacyPolicy];
                    break;
                case 2:
                    [self openInquiry];
                    break;
                default:
                    break;
            }
            break;
        case 3:
            switch (indexPath.row) {
                case 0:
                    [self logout];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case 0:
            title = @"アカウント情報";
            break;
        case 1:
            title = @"こども設定";
            break;
        case 2:
            title = @"Babyryについて";
            break;
        default:
            title = @"";
            break;
    }
    return title;
}

// titleForHeaderInSectionでアルファベットをsection headerに設定すると大文字になってしまう
// そこでheaderの表示直前に書き換える
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section{
    if (section == 2) {
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        tableViewHeaderFooterView.textLabel.text = @"Babyryについて";
    }
}

- (void)openRegisterView
{
    UserRegisterViewController * userRegisterViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UserRegisterViewController"];
    [self.navigationController pushViewController:userRegisterViewController animated:YES];
}

- (void)openFamilyApply
{
    FamilyApplyViewController * familyApplyViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FamilyApplyViewController"];
    [self.navigationController pushViewController:familyApplyViewController animated:YES];
}

- (void)openFamilyApplyList
{
    FamilyApplyListViewController *familyApplyListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FamilyApplyListViewController"];
    [self.navigationController pushViewController:familyApplyListViewController animated:YES];
}

- (void)openAddChildAddView
{
    [tn removeNavigationView];
    IntroChildNameViewController *icnvc = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroChildNameViewController"];
    icnvc.childProperties = _childProperties;
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
    PFObject *familyRole = [FamilyRole getFamilyRole:@"useCache"];
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
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in switchRole : %@", error]];
            return;
        }
        self.roleControl.enabled = TRUE;
        [FamilyRole updateCache];
        
        // Tutorial中の場合はステージを進める
        if ([Tutorial underTutorial]) {
            [Tutorial updateStage];
            [tn removeNavigationView];
            [tn showNavigationView];
        }
        
        // push通知
        NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
        options[@"formatArgs"] = [PFUser currentUser][@"nickName"];
        options[@"data"] = [[NSMutableDictionary alloc]initWithObjects:@[@"Increment"] forKeys:@[@"badge"]];
        [PushNotification sendInBackground:@"partSwitched" withOptions:options];
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
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in createRoleSwitchSegmentControl : %@", error]];
        }
    }];
    
    return sc;
}

- (void)openProfileEdit
{
    ProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ProfileViewController"];
    
    // リクエストが増えるのは微妙だが事前に情報を取得しておく
    // partnerInfo、childともに基本キャッシュ、ネットワークがない場合はキャッシュを使う
    profileViewController.childProperties = _childProperties;
    profileViewController.partnerInfo = _partnerInfo;
    [self.navigationController pushViewController:profileViewController animated:YES];
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
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in setupPartnerInfo : %@", error]];
        }
    }];
}

- (void)openAcceptableUsePolicy
{
    AcceptableUsePolicyViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"AcceptableUsePolicyViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openPrivacyPolicy
{
    PrivacyPolicyViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"PrivacyPolicyViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openInquiry
{
    NSString *bodyFormat = @"%@\n\n\n\n\n\n\n%@\n\n%@\n\n%@\n\n%@";
    
    NSString *introduction = @"いつもBabyryをご利用いただき、ありがとうございます。こちらにお問い合わせ内容をご記入ください。";
    NSString *note         = @"下記はご使用端末の情報です。お問い合わせ対応の際に使用させて頂くため、修正せず、そのまま送信してください。";
    NSString *infoNote     = @"以下の情報はお問い合わせ対応のみに使用します。上記に同意の上、送信してください。";
    NSString *company      = @"(株)ミーニング";
                               
    float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    NSString *info = [NSString stringWithFormat:@"OS:%@\nOS Version:%f\nUser Id:%@\nApp Version:%@",
                      @"iOS",
                      osVersion,
                      [PFUser currentUser][@"userId"],
                      [Config config][@"AppVersion"]];
   
    NSString *body = [NSString stringWithFormat:bodyFormat,
                      introduction,
                      note,
                      infoNote,
                      company,
                      info];
    
    NSString *encodedBody = [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *subject = @"Babyryお問い合わせ";
    NSString *encodedSubject = [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *url = [NSString stringWithFormat:@"mailto:%@?Subject=%@&body=%@", [Config config][@"InquiryEmail"], encodedSubject, encodedBody];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
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
