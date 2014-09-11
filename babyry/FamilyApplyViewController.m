//
//  FamilyApplyViewController.m
//  babyry
//
//  Created by Motoi Hirata on 2014/06/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "FamilyApplyViewController.h"
#import "IdIssue.h"
#import "Navigation.h"
#import "ColorUtils.h"
#import "FamilyApplyListViewController.h"
#import "Logger.h"
#import "Config.h"
#import "WaitPartnerAcceptView.h"
#import "ImageCache.h"
#import "PushNotification.h"
#import "LogoutIntroduceView.h"

@interface FamilyApplyViewController ()

@end

@implementation FamilyApplyViewController

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
    
    _searchingStep = @"";
    
    self.view.backgroundColor = [UIColor whiteColor];
    _searchBackContainerView.backgroundColor = [ColorUtils getBackgroundColor];
    _searchBackContainerView.layer.cornerRadius = 10;
    
    _inviteContainer.backgroundColor = [ColorUtils getBackgroundColor];
    _inviteContainer.layer.cornerRadius = 10;
    
	// Do any additional setup after loading the view.
    self.searchContainerView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
    self.selfUserIdContainer.backgroundColor = [UIColor whiteColor];
    [self showSelfUserEmail];
    
    [self setupSearchForm];
    [Navigation setTitle:self.navigationItem withTitle:@"パートナー検索" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
    
    // view押したらキーボードを隠す
    UITapGestureRecognizer *hideKeyboradGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
    hideKeyboradGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:hideKeyboradGesture];
    
    _messageButton = [[UIButton alloc] init];
    _messageButton.frame = _searchContainerView.frame;
    _messageButton.backgroundColor = [ColorUtils getSunDayCalColor];
    [_searchBackContainerView addSubview:_messageButton];
    _messageButton.hidden = YES;
    
    _pickedAddress = @"";
    
    // logoutボタン
    [self setupLogoutButton];
    [self showRescueDialog];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // 最初のデータ確認だけはクルクル出す
    _stasusHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _stasusHud.labelText = @"パートナーデータ確認";
    
    if (!_tm || ![_tm isValid]) {
        _tm = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(checkFamilyApply) userInfo:nil repeats:YES];
        [_tm fire];
    }
}

- (void) checkFamilyApply
{
    // 既にFamilyひも付け完了している、申請済み、リクエストが来ている、を確認する。
    PFUser *user = [PFUser currentUser];
    
    if (user[@"familyId"] && ![user[@"familyId"] isEqualToString:@""]) {
        PFQuery * roleQuery = [PFQuery queryWithClassName:@"FamilyRole"];
        [roleQuery whereKey:@"familyId" equalTo:user[@"familyId"]];
        [roleQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in checkFamilyApply(from FamilyId) : %@", error]];
                [_stasusHud hide:YES];
                return;
            }
            if ([objects count] > 0) {
                _familyObject = [objects objectAtIndex:0];
                [self showMessage:@"forFamily"];
                [_stasusHud hide:YES];
                return;
            }
            
            PFQuery * applyQuery = [PFQuery queryWithClassName:@"FamilyApply"];
            [applyQuery whereKey:@"userId" equalTo:user[@"userId"]];
            [applyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
                if (error) {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in checkFamilyApply(from userId) : %@", error]];
                    [_stasusHud hide:YES];
                    return;
                }
                
                if ([objects count] > 0) {
                    _applyObject = [objects objectAtIndex:0];
                    [self showMessage:@"forInviter"];
                }
                [_stasusHud hide:YES];
            }];
        }];
    } else {
        PFQuery * applyQuery = [PFQuery queryWithClassName:@"FamilyApply"];
        [applyQuery whereKey:@"inviteeUserId" equalTo:user[@"userId"]];
        [applyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in checkFamilyApply(from inviteeUserId) : %@", error]];
                [_stasusHud hide:YES];
                return;
            }
            
            if ([objects count] > 0) {
                [self showMessage:@"forInvitee"];
                [_stasusHud hide:YES];
                return;
            } else {
                [self showMessage:@"clear"];
                [_stasusHud hide:YES];
                return;
            }
            [_stasusHud hide:YES];
        }];
    }
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_tm invalidate];
}

-(void) showMessage:(NSString *)type
{
    if ([type isEqualToString:@"clear"]) {
        _messageButton.hidden = YES;
        return;
    }
    
    if ([type isEqualToString:@"forInviter"]) {
        [self showWaitPartnerMessage];
        return;
    }
    
    if ([type isEqualToString:@"forInvitee"]) {
        [_messageButton setTitle:@"申請が来ています(タップで確認)" forState:UIControlStateNormal];
        [_messageButton addTarget:self action:@selector(checkApply) forControlEvents:UIControlEventTouchDown];
    } else  if ([type isEqualToString:@"forFamily"]) {
        [_messageButton setTitle:@"パートナー登録は完了しています" forState:UIControlStateNormal];
        [self.navigationController popViewControllerAnimated:YES];
    }
    _messageButton.hidden = NO;
}

-(void)hideKeyboard:(id) sender
{
    [self.view endEditing:YES];
}

- (void)closeFamilyApply
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showSelfUserEmail
{
    PFUser *user = [PFUser currentUser];
    [user refresh];
    _selfUserEmail.text = user[@"emailCommon"];
}

- (void)executeSearch
{
    NSString * inputtedUserEmail = [[NSString alloc] init];
    if (![_pickedAddress isEqualToString:@""]) {
        inputtedUserEmail = _pickedAddress;
    } else {
        inputtedUserEmail = [_searchForm.text mutableCopy];
    }
    
    if ([inputtedUserEmail isEqualToString:_selfUserEmail.text]) {
        [self showSearchYourSelf];
        return;
    }
    
    if (inputtedUserEmail && ![inputtedUserEmail isEqualToString:@""]) {
        
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.labelText = @"検索中...";
        
        // search用APIを叩いてユーザを検索
        PFQuery * query = [PFQuery queryWithClassName:@"_User"];
        
        [query whereKey:@"emailCommon" equalTo:inputtedUserEmail];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
            if (!error){
                if (objects.count < 1) {
                    [self showSearchNoResult];
                } else {
                    // すでにFamilyIdがある人だった場合は表示しない
                    // セキュリティ的に、既にパートナーがいますってのも出さない方が良い
                    _searchedUserObject = [objects objectAtIndex:0];
                    if(_searchedUserObject[@"familyId"] && ![_searchedUserObject[@"familyId"] isEqualToString:@""]) {
                        [self showSearchNoResult];
                    } else {
                        [self showSearchResult];
                    }
                }
            } else {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in executeSearch %@", error]];
            }
            [_hud hide:YES];
        }];
        [self.view endEditing:YES];
    }
}

- (void)showSearchNoResult
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"一致するユーザーが見つかりませんでした"
                                                    message:@"メールアドレスを確認してください"
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil
                          ];
    [alert show];
    _pickedAddress = @"";
}

- (void)showSearchResult
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"パートナー申請しますか？"
                                                    message:_searchedUserObject[@"emailCommon"]
                                                   delegate:self
                                          cancelButtonTitle:@"戻る"
                                          otherButtonTitles:@"申請", nil
                          ];
    [alert show];
    _pickedAddress = @"";
}

- (void)showSearchYourSelf
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"自分のメールアドレスには申請できません"
                                                    message:@"パートナーのメールアドレスを入力してください"
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil
                          ];
    [alert show];
    _pickedAddress = @"";
}

// 画像削除確認後に呼ばれる
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // logout処理
    if (_tryingLogout) {
        _tryingLogout = NO;
        [self logout:buttonIndex];
        return;
    }
    
    switch (buttonIndex) {
        case 0:
        {
            //１番目のボタンが押されたときの処理を記述する
            // Stepリセット
            _searchingStep = @"";
        }
            break;
        case 1:
        {
            if ([_searchingStep isEqualToString:@""]) {
                _searchingStep = @"applying";
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"あなたのパートを決めてください"
                                                                message:@"パートは後から変更可能です"
                                                               delegate:self
                                                      cancelButtonTitle:@"戻る"
                                                      otherButtonTitles:@"こどもの写真を『アップ』する", @"ベストショットを『チョイス』する", nil
                                      ];
                [alert show];
            } else if ([_searchingStep isEqualToString:@"applying"]) {
                _searchingStep = @"";
                [self sendApply:@"uploader"];
            } else if ([_searchingStep isEqualToString:@"removeApply"]) {
                _searchingStep = @"";
                [_applyObject delete];
                [_applyObject save];
                _messageButton.hidden = YES;
            }
        }
            break;
        case 2:
        {
            _searchingStep = @"";
            [self sendApply:@"chooser"];
        }
    }
}

- (NSString*) createFamilyId
{
    IdIssue *idIssue = [[IdIssue alloc]init];
    return [idIssue issue:@"family"];
}

- (void)sendApply:(NSString *)role
{
    NSString *familyId = [self createFamilyId];
//    _searchedUserObject[@"familyId"] = familyId;
    
    PFObject *currentUser = [PFUser currentUser];
    // userテーブルの自分のレコードを更新
    currentUser[@"familyId"] = familyId;
    [currentUser save];
    
    // OKだったらfamilyApplyへinesrt
    PFObject *familyApply = [PFObject objectWithClassName:@"FamilyApply"];
    familyApply[@"userId"] = currentUser[@"userId"];
    familyApply[@"inviteeUserId"] = _searchedUserObject[@"userId"];
    familyApply[@"status"] = @"applying"; // 申請中
    familyApply[@"role"] = role;
    
    [familyApply save];
    [Logger writeOneShot:@"info" message:[NSString stringWithFormat:@"FamilyApply send from:%@ to:%@ role:%@", currentUser[@"userId"], _searchedUserObject[@"userId"], role]];
    // そのうちpush通知送る
    
    [self showWaitPartnerMessage];
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
    _searchForm = [[UITextField alloc]initWithFrame:CGRectMake(12, 10, 215, 30)];
    _searchForm.clearButtonMode = UITextFieldViewModeAlways;
    _searchForm.placeholder = @"メールアドレスを入力";
    _searchForm.keyboardType = UIKeyboardTypeASCIICapable;
    _searchForm.opaque = NO;
    _searchForm.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
    [self.searchContainerView addSubview:_searchForm];
}

- (void) removeApply
{
    _searchingStep = @"removeApply";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"申請ととりけしますか？"
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"戻る"
                                          otherButtonTitles:@"取り消し", nil
                          ];
    [alert show];
}

- (void) checkApply
{
    FamilyApplyListViewController *familyApplyListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FamilyApplyListViewController"];
    [self.navigationController pushViewController:familyApplyListViewController animated:YES];
}

- (IBAction)inviteByLine:(id)sender {
    NSDictionary *mailInfo = [self makeInviteBody:@"line"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"line://msg/text/%@", mailInfo[@"text"]]]];
}

- (IBAction)inviteByMail:(id)sender {
    NSDictionary *mailInfo = [self makeInviteBody:@"mail"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:?Subject=%@&body=%@", mailInfo[@"title"], mailInfo[@"text"]]]];
}

- (NSDictionary *) makeInviteBody:(NSString *)type
{
    NSMutableDictionary *mailDic = [[NSMutableDictionary alloc] init];
    NSString *inviteTitle = [Config config][@"InviteMailTitle"];
    NSString *inviteText = [[NSString alloc] init];
    if ([type isEqualToString:@"line"]) {
        inviteText = [Config config][@"InviteLineText"];
    } else if ([type isEqualToString:@"mail"]) {
        inviteText = [Config config][@"InviteMailText"];
    }
    NSString *inviteReplacedText = [inviteText stringByReplacingOccurrencesOfString:@"%mail" withString:_selfUserEmail.text];
    mailDic[@"title"] = [inviteTitle stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    mailDic[@"text"] = [inviteReplacedText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return [[NSDictionary alloc] initWithDictionary:mailDic];
}

- (IBAction)searchFromAddressBook:(id)sender {
    ABPeoplePickerNavigationController *ABPicker = [[ABPeoplePickerNavigationController alloc] init];
    ABPicker.peoplePickerDelegate = self;
    [self presentViewController:ABPicker animated:YES completion:nil];
}

// ABPeoplePickerNavigationControllerDelegateのデリゲートメソッド
- (void)peoplePickerNavigationControllerDidCancel: (ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)peoplePickerNavigationController: (ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    ABMutableMultiValueRef multi = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (ABMultiValueGetCount(multi)>1) {
        // 複数メールアドレスがある
        // メールアドレスのみ表示するようにする
        [peoplePicker setDisplayedProperties:[NSArray arrayWithObject:[NSNumber numberWithInt:kABPersonEmailProperty]]];
        return YES;
    } else {
        // メールアドレスは1件だけ
        _pickedAddress = (__bridge NSString*)ABMultiValueCopyValueAtIndex(multi, 0);
        [self dismissViewControllerAnimated:YES completion:nil];
        [self executeSearch];
        return NO;
    }
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    // 選択したメールアドレスを取り出す
    ABMutableMultiValueRef multi = ABRecordCopyValue(person, property);
    CFIndex index = ABMultiValueGetIndexForIdentifier(multi, identifier);
    _pickedAddress = (__bridge NSString*)ABMultiValueCopyValueAtIndex(multi, index);
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self executeSearch];
    return NO;
}

- (void) showWaitPartnerMessage
{
    // 下のボタンを押せないようにViewを重ねる
    if (_waitingCoverView) {
        [_waitingCoverView removeFromSuperview];
        _waitingCoverView = nil;
    }
    
    _waitingCoverView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_waitingCoverView];
    
    // 承認待ちメッセージの表示
    WaitPartnerAcceptView *view = [WaitPartnerAcceptView view];
    CGRect rect = view.frame;
    rect.origin.x = (self.view.frame.size.width - rect.size.width)/2;
    rect.origin.y = (self.view.frame.size.height - rect.size.height)/2;
    view.frame = rect;
    [_waitingCoverView addSubview:view];
}

- (void)setupLogoutButton
{
    UIButton *logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [logoutButton setBackgroundImage:[UIImage imageNamed:@"CogWheelReverse"] forState:UIControlStateNormal];
    [logoutButton addTarget:self action:@selector(toggleLogoutButton) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:logoutButton];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)toggleLogoutButton
{
    if (!_clearView) {
        [self createLogoutView];
    }
    
    if (_clearView.hidden == NO) {
        [UIView animateWithDuration:0.3f
                     animations:^{
                         CGRect rect = _logoutButtonView.frame;
                         rect.origin.y = 0;
                         _logoutButtonView.frame = rect;
                     }
                     completion:^(BOOL finished){
                         _clearView.hidden = YES;
                         _logoutButtonView.hidden = YES;
                     }];
    } else {
        _clearView.hidden = NO;
        _logoutButtonView.hidden = NO;
        [UIView animateWithDuration:0.3f
                     animations:^{
                         CGRect rect = _logoutButtonView.frame;
                         rect.origin.y = 64;
                         _logoutButtonView.frame = rect;
                     }
                     completion:^(BOOL finished){
                     }];
    }
    
}

- (void)createLogoutView
{
    _clearView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    _clearView.hidden = YES;
    [self.view addSubview:_clearView];
    UITapGestureRecognizer *clearViewGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggleLogoutButton)];
    clearViewGesture.numberOfTapsRequired = 1;
    [_clearView addGestureRecognizer:clearViewGesture];
   
    int viewWidth = 120;
    int viewHeight = 44;
    _logoutButtonView = [[UIView alloc]initWithFrame:CGRectMake(self.view.frame.size.width - viewWidth, 0, viewWidth, viewHeight)];
    _logoutButtonView.backgroundColor = [ColorUtils getBabyryColor];
    _logoutButtonView.hidden = YES;
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:_logoutButtonView.bounds
                                     byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight)
                                           cornerRadii:CGSizeMake(3.0, 3.0)];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = _logoutButtonView.bounds;
    maskLayer.path = maskPath.CGPath;
    _logoutButtonView.layer.mask = maskLayer;
    
    UIButton *logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, viewWidth, viewHeight)];
    [logoutButton setTitle:@"ログアウト" forState:UIControlStateNormal];
    [logoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [logoutButton addTarget:self action:@selector(showLogoutAlert) forControlEvents:UIControlEventTouchUpInside];
    [_logoutButtonView addSubview:logoutButton];
    
    [_clearView addSubview:_logoutButtonView];
}

- (void)showLogoutAlert
{
    _tryingLogout = YES;
    [[[UIAlertView alloc] initWithTitle:@""
                                message:@"ログアウトします、よろしいですか？"
                               delegate:self
                      cancelButtonTitle:@"キャンセル"
                      otherButtonTitles:@"ログアウト", nil] show];
}

- (void)logout:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0../babyry.xcodeproj/project.pbxproj
            break;
        case 1:
        {
            [self doLogout];
            break;
        }
    }
}

- (void)doLogout
{
    [self.navigationController popViewControllerAnimated:YES];
    [ImageCache removeAllCache];
    [PushNotification removeSelfUserIdFromChannels:^(){
        [PFUser logOut];
        [_viewController viewDidAppear:YES];
    }];
}

// FB会員登録したユーザのemailCommonが空になる障害で
// emailCommonが空になったユーザの救済措置
- (void)showRescueDialog
{
    if ([PFUser currentUser][@"emailCommon"]) {
        return;
    }
    
    LogoutIntroduceView *view = [LogoutIntroduceView view];
    CGRect rect = view.frame;
    rect.origin.x = (self.view.frame.size.width - rect.size.width)/1.5;
    rect.origin.y = (self.view.frame.size.height - rect.size.height)/2;
    view.frame = rect;
    view.delegate = self;
    [self.view addSubview:view];
}

@end
