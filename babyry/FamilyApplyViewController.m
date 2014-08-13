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
    NSLog(@"viewDidLoad in FamilyApplyViewController");
    [super viewDidLoad];
    
    _searchingStep = @"";
    
    self.view.backgroundColor = [UIColor whiteColor];
    _searchBackContainerView.backgroundColor = [ColorUtils getBackgroundColor];
    _searchBackContainerView.layer.cornerRadius = 10;
    
	// Do any additional setup after loading the view.
    self.searchContainerView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
    self.selfUserIdContainer.backgroundColor = [UIColor whiteColor];
    [self showSelfUserEmail];
    
    [self setupSearchForm];
    [Navigation setTitle:self.navigationItem withTitle:@"パートナー検索" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
    
    NSLog(@"set navigator for keyboard");
    // view押したらキーボードを隠す
    UITapGestureRecognizer *hideKeyboradGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
    hideKeyboradGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:hideKeyboradGesture];
    
    _messageButton = [[UIButton alloc] init];
    _messageButton.frame = _searchContainerView.frame;
    _messageButton.backgroundColor = [ColorUtils getSunDayCalColor];
    [_searchBackContainerView addSubview:_messageButton];
    _messageButton.hidden = YES;
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
        NSLog(@"timer fire");
        _tm = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(checkFamilyApply) userInfo:nil repeats:YES];
        [_tm fire];
    }
}

- (void) checkFamilyApply
{
    // 既にFamilyひも付け完了している、申請済み、リクエストが来ている、を確認する。
    PFUser *user = [PFUser currentUser];
    
    if (user[@"familyId"]) {
        NSLog(@"familyIdがある場合は、ひも付け完了しているか、リクエスト済み");
        PFQuery * roleQuery = [PFQuery queryWithClassName:@"FamilyRole"];
        [roleQuery whereKey:@"familyId" equalTo:user[@"familyId"]];
        [roleQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
            if (!error){
                if ([objects count] > 0) {
                    NSLog(@"ひも付け済み");
                    _familyObject = [objects objectAtIndex:0];
                    [self showMessage:@"forFamily"];
                } else {
                    NSLog(@"ひも付け未完、申請確認");
                    PFQuery * applyQuery = [PFQuery queryWithClassName:@"FamilyApply"];
                    [applyQuery whereKey:@"userId" equalTo:user[@"userId"]];
                    [applyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
                        if (!error){
                            if ([objects count] > 0) {
                                NSLog(@"申請中、相手待ち");
                                _applyObject = [objects objectAtIndex:0];
                                [self showMessage:@"forInviter"];
                            }
                        }
                        [_stasusHud hide:YES];
                    }];
                }
            }
            [_stasusHud hide:YES];
        }];
    } else {
        NSLog(@"familyIdがない場合、申請を受けているかだけ見る");
        PFQuery * applyQuery = [PFQuery queryWithClassName:@"FamilyApply"];
        [applyQuery whereKey:@"inviteeUserId" equalTo:user[@"userId"]];
        [applyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
            if (!error){
                if ([objects count] > 0) {
                    NSLog(@"申請が来ています");
                    [self showMessage:@"forInvitee"];
                }
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
    if ([type isEqualToString:@"forInvitee"]) {
        NSLog(@"申請メッセージ表示");
        [_messageButton setTitle:@"申請が来ています(タップで確認)" forState:UIControlStateNormal];
        [_messageButton addTarget:self action:@selector(checkApply) forControlEvents:UIControlEventTouchDown];
    } else if ([type isEqualToString:@"forInviter"]) {
        NSLog(@"申請メッセージ表示");
        [_messageButton setTitle:@"申請済みです(タップで取り消し)" forState:UIControlStateNormal];
        [_messageButton addTarget:self action:@selector(removeApply) forControlEvents:UIControlEventTouchDown];
    } else if ([type isEqualToString:@"forFamily"]) {
        NSLog(@"申請メッセージ表示");
        [_messageButton setTitle:@"パートナー登録は完了しています" forState:UIControlStateNormal];
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
    _selfUserEmail.text = user[@"email"];
}

- (void)executeSearch
{
    NSString * inputtedUserEmail = [_searchForm.text mutableCopy];
    if (inputtedUserEmail && ![inputtedUserEmail isEqualToString:@""]) {
        
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.labelText = @"検索中...";
        
        // search用APIを叩いてユーザを検索
        PFQuery * query = [PFQuery queryWithClassName:@"_User"];
        
        [query whereKey:@"email" equalTo:inputtedUserEmail];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
            if (!error){
                NSLog(@"aaaa %d %@", objects.count, objects);
                if (objects.count < 1) {
                    NSLog(@"検索0件");
                    [self showSearchNoResult];
                } else {
                    // すでにFamilyIdがある人だった場合は表示しない
                    // セキュリティ的に、既にパートナーがいますってのも出さない方が良い
                    _searchedUserObject = [objects objectAtIndex:0];
                    if(_searchedUserObject[@"familyId"] && ![_searchedUserObject[@"familyId"] isEqualToString:@""]) {
                        NSLog(@"このユーザーはすでにパートナーいます %@", _searchedUserObject[@"familyId"]);
                        [self showSearchNoResult];
                    } else {
                        NSLog(@"OK");
                        [self showSearchResult];
                    }
                }
            } else {
                NSLog(@"error occured %@", error);
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
}

- (void)showSearchResult
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"パートナー申請しますか？"
                                                    message:_searchedUserObject[@"email"]
                                                   delegate:self
                                          cancelButtonTitle:@"戻る"
                                          otherButtonTitles:@"申請", nil
                          ];
    [alert show];
}

// 画像削除確認後に呼ばれる
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
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
                NSLog(@"ユーザー見つかったのでパートを決める");
                _searchingStep = @"applying";
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"あなたのパートを決めてください"
                                                                message:@"パートは後から変更可能です"
                                                               delegate:self
                                                      cancelButtonTitle:@"戻る"
                                                      otherButtonTitles:@"こどもの写真を『アップ』する", @"ベストショットを『チョイス』する", nil
                                      ];
                [alert show];
            } else if ([_searchingStep isEqualToString:@"applying"]) {
                NSLog(@"アップで申請");
                _searchingStep = @"";
                [self sendApply:@"uploader"];
            } else if ([_searchingStep isEqualToString:@"removeApply"]) {
                NSLog(@"申請取り消し");
                _searchingStep = @"";
                [_applyObject delete];
                [_applyObject save];
                _messageButton.hidden = YES;
            }
        }
            break;
        case 2:
        {
            NSLog(@"チョイスで申請");
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
    // そのうちpush通知送る
    
    [self closeFamilyApply];
}

- (void)setupSearchForm
{
    NSLog(@"setupSearchForm");
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
    NSLog(@"remove!");
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

@end
