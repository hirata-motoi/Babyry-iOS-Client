//
//  ViewController.m
//  babyrydev
//
//  Created by kenjiszk on 2014/05/30.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ViewController.h"
#import "ImageCache.h"
#import "GlobalSettingViewController.h"
#import "IdIssue.h"
#import "FamilyApplyViewController.h"
#import "FamilyRole.h"
#import "MaintenanceViewController.h"
#import "Config.h"
#import "IntroFirstViewController.h"
#import "PageContentViewController.h"
#import "IntroChildNameViewController.h"
#import "PushNotification.h"
#import "UIColor+Hex.h"
#import "AWSS3Utils.h"
#import "ImageEdit.h"
#import "TagAlbumOperationViewController.h"
#import "ArrayUtils.h"
#import "Navigation.h"
#import "Partner.h"
#import "Sharding.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // よく使うからここに書いておく
    //[PFUser logOut];
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.labelText = @"データ準備中";
    //_hud.margin = 0;
    //_hud.labelFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15];
    
    _only_first_load = 1;
    
    // navigation controller
    CGRect rect = CGRectMake(0, 0, 130, 38);
    UIImageView *titleview = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"babyryTitleReverse"]];
    titleview.frame = rect;
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(176, 0, 130, 38)];
    [view addSubview:titleview];
    self.navigationItem.titleView = view;
    self.navigationController.navigationBar.barTintColor = [UIColor_Hex colorWithHexString:@"f4c510" alpha:1.0f];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithTitle:@""
                                             style:UIBarButtonItemStylePlain
                                             target:nil
                                             action:nil];
    
    // childPropertiesのメモリ領域確保
    _childProperties = [[NSMutableArray alloc] init];
    // partner情報初期化
    [Partner initialize];
    
    // sharding conf初期化
    [Sharding setupShardConf];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _currentUser = [PFUser currentUser];
    if (!_currentUser) { // No user logged in
        _only_first_load = 1;
        [_pageViewController.view removeFromSuperview];
        [_pageViewController removeFromParentViewController];
        _pageViewController = nil;
        
        // ログインしてない場合は、イントロ+ログインViewを出す
        IntroFirstViewController *introFirstViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroFirstViewController"];
        [self presentViewController:introFirstViewController animated:YES completion:NULL];
    } else {
        // メンテナンス状態かどうか確認
        // バックグラウンドで行わないと一瞬固まる
        PFQuery *maintenanceQuery = [PFQuery queryWithClassName:@"Config"];
        maintenanceQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
        [maintenanceQuery whereKey:@"key" equalTo:@"maintenance"];
        [maintenanceQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if([objects count] == 1) {
                if([[objects objectAtIndex:0][@"value"] isEqualToString:@"ON"]) {
                    MaintenanceViewController *maintenanceViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MaintenanceViewController"];
                    [self presentViewController:maintenanceViewController animated:YES completion:NULL];
                }
            }
        }];
        
        // プッシュ通知用のデータがなければUserIdを突っ込んでおく
        [PushNotification setupPushNotificationInstallation];

        
        /*/////////////////////////////いちいちメール確認必要だから開発中はコメント//////////////////////////////////////
        // emailが確認されているか
        // まずはキャッシュからとる(verifiledされていればここで終わりなのでParseにとりにいかない)
        NSLog(@"currentUserStatus %@", _currentUser);
        if (![[_currentUser objectForKey:@"emailVerified"] boolValue]) {
            NSLog(@"Parseにフォアグランドでとりにいく");
            [_currentUser refresh];
            NSLog(@"refleshed currentUser %@", _currentUser);
            if (![[_currentUser objectForKey:@"emailVerified"] boolValue]) {
                NSLog(@"mailがまだ確認されていません");
                [self setNotVerifiedPage];
                return;
            }
        }
        //////////////////////////////////////////////////////////////////////////////*/
        
        // falimyIdを取得
        if (!_currentUser[@"familyId"] || [_currentUser[@"familyId"] isEqualToString:@""]) {
            NSLog(@"ログインしているけどファミリ- IDがない = 最初のログイン");
            // パートナー検索画面を出す
            FamilyApplyViewController *familyApplyViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FamilyApplyViewController"];
            [self.navigationController pushViewController:familyApplyViewController animated:YES];
            return;
        }
        
        // nickname確認 なければ入れてもらう (ないとpush通知とかで落ちる)
        // まずはキャッシュから確認
        if (![_currentUser objectForKey:@"nickName"] || [[_currentUser objectForKey:@"nickName"] isEqualToString:@""]) {
            //キャッシュがなければフォアグランドで引いても良い。
            [_currentUser refresh];
            if (![_currentUser objectForKey:@"nickName"] || [[_currentUser objectForKey:@"nickName"] isEqualToString:@""]) {
                [self setMyNickNamePage];
                return;
            }
        }
        
        // roleを更新
        [FamilyRole updateCache];
        
        // Set if user has no child
        PFQuery *childQuery = [PFQuery queryWithClassName:@"Child"];
        [childQuery whereKey:@"familyId" equalTo:_currentUser[@"familyId"]];
        [childQuery orderByAscending:@"createdAt"];
        
        // networkから引く nwが駄目なら cacheから
        childQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
        // 起動して一発目はfrontで引く
        if (_only_first_load == 1) {
            _childArrayFoundFromParse = [childQuery findObjects];
            [self setupChildProperties];
        
            // こどもが一人もいない = 一番最初のログインで一人目のこどもを作成しておく
            // こどもいるけどNW接続ないcacheないみたいな状況でここに入るとまずいか？
            if ([_childArrayFoundFromParse count] < 1) {
                [self setChildNames];
                return;
            }
            [self initializeChildImages];
            _only_first_load = 0;
            
            [_hud hide:YES];
        } else {
            // 二発目以降はbackgroundで引かないとUIが固まる
            [childQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if(!error) {
                    _childArrayFoundFromParse = objects;
                    [self setupChildProperties];
                    [self initializeChildImages];
                }
            }];
        }
        [self showPageViewController];
    }
}

- (void)openGlobalSettingView
{
    GlobalSettingViewController *globalSettingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GlobalSettingViewController"];
    globalSettingViewController.viewController = self;
    globalSettingViewController.childProperties = _childProperties;
    [self.navigationController pushViewController:globalSettingViewController animated:YES];
}

- (void)setupChildProperties
{
    // 初期化
    [_childProperties removeAllObjects];
    
    for (PFObject *c in _childArrayFoundFromParse) {
        NSMutableDictionary *childSubDic = [[NSMutableDictionary alloc] init];
        [childSubDic setObject:c.objectId forKey:@"objectId"];
        [childSubDic setObject:c[@"name"] forKey:@"name"];
        if (c[@"birthday"]) {
            [childSubDic setObject:c[@"birthday"] forKey:@"birthday"];
        } else {
            [childSubDic setObject:[NSDate distantFuture] forKey:@"birthday"];
        }
        childSubDic[@"childImageShardIndex"] = c[@"childImageShardIndex"];
        childSubDic[@"createdAt"] = c.createdAt;
        [_childProperties addObject:childSubDic];
    }
}

-(void) showPageViewController
{
    if (!_pageViewController) {
        _pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
        _pageViewController.childProperties = _childProperties;
        [self addChildViewController:_pageViewController];
        [self.view addSubview:_pageViewController.view];
    }

    // global setting
    UIButton *openGlobalSettingButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [openGlobalSettingButton setBackgroundImage:[UIImage imageNamed:@"listReverse"] forState:UIControlStateNormal];
    [openGlobalSettingButton addTarget:self action:@selector(openGlobalSettingView) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:openGlobalSettingButton];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

-(void)setNotVerifiedPage
{
    UIViewController *emailVerifiedViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NotEmailVerifiedViewController"];
    
    // リロードラベル
    UILabel *reloadLabel = [[UILabel alloc] init];
    reloadLabel.userInteractionEnabled = YES;
    reloadLabel.textAlignment = NSTextAlignmentCenter;
    reloadLabel.text = @"リロード";
    reloadLabel.textColor = [UIColor orangeColor];
    reloadLabel.layer.cornerRadius = 50;
    reloadLabel.layer.borderColor = [UIColor orangeColor].CGColor;
    reloadLabel.layer.borderWidth = 2.0f;
    CGRect frame = CGRectMake((self.view.frame.size.width - 100)/2, self.view.frame.size.height*2/3, 100, 100);
    reloadLabel.frame = frame;
    [emailVerifiedViewController.view addSubview:reloadLabel];
    
    UITapGestureRecognizer *stgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reloadEmailVerifiedView:)];
    stgr.numberOfTapsRequired = 1;
    [reloadLabel addGestureRecognizer:stgr];
    
    [self presentViewController:emailVerifiedViewController animated:YES completion:NULL];
}

-(void)reloadEmailVerifiedView:(id)selector
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)setMyNickNamePage
{
    UIViewController *introMyNicknameViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroMyNicknameViewController"];
    [self presentViewController:introMyNicknameViewController animated:YES completion:NULL];
}

-(void)setChildNames
{
    IntroChildNameViewController *introChildNameViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroChildNameViewController"];
    [self presentViewController:introChildNameViewController animated:YES completion:NULL];
}

- (void)initializeChildImages
{
    _childImages = [[NSMutableDictionary alloc]init];
    for (PFObject *child in _childArrayFoundFromParse) {
        [_childImages setObject:[[NSMutableArray alloc]init] forKey:child.objectId];
    }
}


@end
