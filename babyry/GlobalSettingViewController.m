//
//  GlobalSettingViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "GlobalSettingViewController.h"
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
#import "TmpUser.h"
#import "UserRegisterViewController.h"
#import "NotEmailVerifiedViewController.h"
#import "PartnerApply.h"
#import "UINavigationController+Block.h"
#import "AnnounceBoardView.h"
#import "ChildSwitchControlView.h"

@interface GlobalSettingViewController ()

@end

@implementation GlobalSettingViewController {
    TutorialNavigator *tn;
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
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithTitle:@""
                                             style:UIBarButtonItemStylePlain
                                             target:nil
                                             action:nil];
    _settingTableView.delegate = self;
    _settingTableView.dataSource = self;
    
    [self setupPartnerInfo];
    [Navigation setTitle:self.navigationItem withTitle:@"設定" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
    
//    [self checkEmailVerified];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [_settingTableView reloadData];
    [self setRoleSegmentControl];
    
    tn = [[TutorialNavigator alloc]init];
    tn.targetViewController = self;
    [tn showNavigationView];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [tn removeNavigationView];
    tn = nil;
}

//- (void) checkEmailVerified
//{
//    // Facebookログイン: user[@"email"]なし => noNeed
//    // 簡単ログイン : user[@"emailCommon"]がメアド形式でない => notYet
//    // 本登録&認証済み : user[@"email"]あり、EmailVerifyのisVerifedがTRUE => done
//    // 本登録&認証未済 : user[@"email"]あり、EmailVerifyのisVerifedがFALSE => doing
//    PFUser *user = [PFUser currentUser];
//    if (user[@"emailVerified"]) {
//        if ([user[@"emailVerified"] boolValue]) {
//            _emailVerified = @"done";
//        } else {
//            _emailVerified = @"notYet";
//        }
//    } else {
//        _emailVerified = @"noNeed";
//    }
//}

#pragma mark - Table view data source


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
            [self.navigationController popViewControllerAnimated:YES onCompletion:^(void){
                [PushNotification removeSelfUserIdFromChannels:^(){
                    [PFUser logOut];
                    [ImageCache removeAllCache];
                    [Tutorial removeTutorialStage];
                    [TmpUser removeTmpUserFromCoreData];
                    [PartnerApply removePartnerInviteFromCoreData];
                    [PartnerApply removePartnerInvitedFromCoreData];
//                    [AnnounceBoardView removeAnnounceInfoByOuter];
                    [_delegate viewDidAppear:YES];
                    [_delegate removeChildSwitchControlView];
                }];
            }];
        }
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
    }
    for (UIView *view in [cell subviews]) {
        for (UIView *elem in [view subviews]) {
            if ([elem isKindOfClass:[UISegmentedControl class]]) {
                [elem removeFromSuperview];
            }
        }
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
//                case 2:
//                    if (![TmpUser checkRegistered]) {
//                        cell.textLabel.text = @"本登録を完了する";
//                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//                    } else {
//                        cell.textLabel.text = @"メールアドレス認証";
//                        cell.detailTextLabel.text = @"未認証";
//                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//                    }
//                    break;
                default:
                    break;
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
//            if (![TmpUser checkRegistered] || ![_emailVerified isEqualToString:@"noNeed"]) {
//                rowCount = 3;
//            } else {
                rowCount = 2;
//            }
            break;
        case 1:
            rowCount = 1;
            break;
        case 2:
            rowCount = 3;
            break;
        case 3:
            if ([TmpUser checkRegistered]) {
                rowCount = 1;
            } else {
                rowCount = 0;
            }
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
//                case 2:
//                    if (![TmpUser checkRegistered]) {
//                        [self openRegisterView];
//                    } else {
//                        [self openEmailVerifiedView];
//                    }
//                    break;
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

//- (void)openRegisterView
//{
//    UserRegisterViewController * userRegisterViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UserRegisterViewController"];
//    [self.navigationController pushViewController:userRegisterViewController animated:YES];
//}

- (void)openAddChildAddView
{
    [tn removeNavigationView];
    IntroChildNameViewController *icnvc = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroChildNameViewController"];
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
        if ([[Tutorial currentStage].currentStage isEqualToString:@"partChange"]) {
            [Tutorial forwardStageWithNextStage:@"addChild"];
            [tn removeNavigationView];
            [tn showNavigationView];
        }
        
        // push通知
        NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
        transitionInfoDic[@"event"] = @"partSwitched";
        NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
        options[@"formatArgs"] = [NSArray arrayWithObject:[PFUser currentUser][@"nickName"]];
        options[@"data"] = [[NSMutableDictionary alloc]initWithObjects:@[@"Increment"] forKeys:@[@"badge"]];
        options[@"data"] = [[NSMutableDictionary alloc]
                            initWithObjects:@[@"Increment", transitionInfoDic]
                            forKeys:@[@"badge", @"transitionInfo"]];
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
   
    // cacheから取得した値を初期値としておく
    NSString *familyRole = [FamilyRole selfRole:@"cacheOnly"];
    if (familyRole) {
        if ([familyRole isEqualToString:@"uploader"]) {
            sc.selectedSegmentIndex = 0;
        } else if ([familyRole isEqualToString:@"chooser"]) {
            sc.selectedSegmentIndex = 1;
        }
    }
    
    return sc;
}

- (void)setRoleSegmentControl
{
    // 初期値を非同期でセット
    [FamilyRole fetchFamilyRole:[PFUser currentUser][@"familyId"] withBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            if (objects.count < 1) {
                return;
            }
            PFObject *familyRole = [objects objectAtIndex:0];
            NSString *uploader = familyRole[@"uploader"];
            if ([[PFUser currentUser][@"userId"] isEqualToString:uploader]) {
                _roleControl.selectedSegmentIndex = 0;
            } else {
                _roleControl.selectedSegmentIndex = 1;
            }
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in createRoleSwitchSegmentControl : %@", error]];
        }
    }];
}

- (void)openProfileEdit
{
    ProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ProfileViewController"];
    
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

- (void)openEmailVerifiedView
{
    NotEmailVerifiedViewController *emailVerifiedViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NotEmailVerifiedViewController"];
    [self.navigationController pushViewController:emailVerifiedViewController animated:YES];
}

@end
