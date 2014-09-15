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
#import "Logger.h"
#import "NotEmailVerifiedViewController.h"
#import "CheckAppVersion.h"
#import "TmpUser.h"
#import "Tutorial.h"

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
    
    // 強制アップデート用 (backgroundメソッド)
    [CheckAppVersion checkForceUpdate];
    
    // tmpUserData (会員登録していないひと) でログインできるか試行
    [TmpUser loginTmpUserByCoreData];
    
    _currentUser = [PFUser currentUser];
    if (!_currentUser) { // No user logged in
        
        // アプリのバージョンを確認してロジック変えるのがよさげ
        [Logger writeOneShot:@"info" message:@"Not-Login User Accessed."];
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
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in check maintenance : %@", error]];
            } else {
                if([objects count] == 1) {
                    if([[objects objectAtIndex:0][@"value"] isEqualToString:@"ON"]) {
                        MaintenanceViewController *maintenanceViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MaintenanceViewController"];
                        [self presentViewController:maintenanceViewController animated:YES completion:NULL];
                    }
                }
            }
        }];
        
        // プッシュ通知用のデータがなければUserIdを突っ込んでおく
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            [PushNotification setupPushNotificationInstallation];
            dispatch_sync(dispatch_get_main_queue(), ^{
            });
        });

        // facebook連携していない場合、emailが確認されているか
        // まずはキャッシュからとる(verifiledされていればここで終わりなのでParseにとりにいかない)
        if ([_currentUser objectForKey:@"emailVerified"]) {
            if (![[_currentUser objectForKey:@"emailVerified"] boolValue]) {
                [_currentUser refresh];
                if (![[_currentUser objectForKey:@"emailVerified"] boolValue]) {
                    [self setNotVerifiedPage];
                    return;
                }
            }
        }
      
        // familyIdを発行する前に呼び出す必要がある
        BOOL hasFamilyId = (_currentUser[@"familyId"]) ? YES : NO;
        [Tutorial initializeTutorialStage:hasFamilyId];
        
        // familyIdがなければ新規にfamilyIdを発行
        if (!_currentUser[@"familyId"]) {
            IdIssue *idIssue = [[IdIssue alloc]init];
            _currentUser[@"familyId"] = [idIssue issue:@"family"];
            [_currentUser saveInBackground];
            // その上でbotと紐付けをする TutorialMapにデータを保存
            PFObject *tutorialMap = [PFObject objectWithClassName:@"TutorialMap"];
            tutorialMap[@"userId"] = _currentUser[@"userId"];
            [tutorialMap saveInBackground];
            
            // TODO TutorialSetting entityにChild.objectIdを保存しとく。TutorialSettingにobjectIdがあればチュートリアル中と判断する
        }
        
//        // falimyIdがなければ招待画面をだして先に進めない
//        if (!_currentUser[@"familyId"] || [_currentUser[@"familyId"] isEqualToString:@""]) {
//            // パートナー検索画面を出す
//            FamilyApplyViewController *familyApplyViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FamilyApplyViewController"];
//            familyApplyViewController.viewController = self;
//            [self.navigationController pushViewController:familyApplyViewController animated:YES];
//            return;
//        }
//        
//        // roleがundefの場合パートナーひも付けされてないからパートナー招待画面を出す
//        if (![FamilyRole selfRole:@"cachekOnly"]) {
//            if (![FamilyRole selfRole:@"noCache"]) {
//                // パートナー検索画面を出す
//                FamilyApplyViewController *familyApplyViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FamilyApplyViewController"];
//                [self.navigationController pushViewController:familyApplyViewController animated:YES];
//                return;
//            }
//        }
        
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
            NSArray *childList = [childQuery findObjects];
            if (childList.count < 1) {
                // こどもがいないのでbabyryちゃんのobjectIdをConfigから引く → _childArrayFromParseにセット
                // ここは同期で処理する
                PFQuery *query = [PFQuery queryWithClassName:@"Config"]; // TODO Configクラスに切り出し
                [query whereKey:@"key" equalTo:@"tutorialChild"];
                NSArray *botUsers = [query findObjects];
                if (botUsers.count > 0) {
                    NSString *childObjectId = botUsers[0][@"value"];
                    // Childからbotのrowをひく
                    PFQuery *botQuery = [PFQuery queryWithClassName:@"Child"];
                    [botQuery whereKey:@"objectId" equalTo:childObjectId];
                    NSArray *botChild = [botQuery findObjects];
                    
                    if (botChild.count > 0) {
                        childList = botChild;
                    } else {
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"No Bot User in Child class objectId:%@", childObjectId]];
                    }
                } else {
                    [Logger writeOneShot:@"crit" message:@"No Bot User Setting in Config class"];
                }
            }
            _childArrayFoundFromParse = childList;
            [self setupChildProperties];
            [self initializeChildImages];
            _only_first_load = 0;
            
            [_hud hide:YES];
        } else {
            // 二発目以降はbackgroundで引かないとUIが固まる
            [childQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if(!error) {
                    // 申請を取り下げた場合に起こりうる
                    if ([objects count] < 1) {
                        // こどもがいないのでbabyryちゃんのobjectIdをConfigから引く → _childArrayFromParseにセット
                        // TODO babyryちゃんのobjectIdはキャッシュしておきたいなー
                        PFQuery *query = [PFQuery queryWithClassName:@"Config"]; // TODO Configクラスに切り出し
                        [query whereKey:@"key" equalTo:@"tutorialChild"];
                        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                            if (error) {
                                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getting tutorialChild : %@", error]];
                                // TODO ネットワークを確認してねというメッセージ出す
                            }
                            if (objects.count > 0) {
                                NSString *childObjectId = objects[0][@"value"];
                                // Childからbotのrowをひく
                                PFQuery *botQuery = [PFQuery queryWithClassName:@"Child"];
                                [botQuery whereKey:@"objectId" equalTo:childObjectId];
                                [botQuery findObjectsInBackgroundWithBlock:^(NSArray *botUsers, NSError *error) {
                                    if (error) {
                                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getting tutorialBotChild from Child objectId:%@", childObjectId]];
                                    }
                                    if (botUsers.count > 0) {
                                        _childArrayFoundFromParse = botUsers;
                                        [self setupChildProperties];
                                        [self initializeChildImages];
                                    } else {
                                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"No Bot User in Child class objectId:%@", childObjectId]];
                                    }
                                }];
                            } else {
                                [Logger writeOneShot:@"crit" message:@"No Bot User Setting in Config class"];
                            }
                        }];
                    }
                } else {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in get childInfo : %@", error]];
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
        childSubDic[@"commentShardIndex"] = c[@"commentShardIndex"];
        childSubDic[@"createdAt"] = c.createdAt;
        [_childProperties addObject:childSubDic];
    }
}

-(void) showPageViewController
{
    if (_pageViewController) {
        [self setupGlobalSetting];
        return;
    }
    
    PFUser *user = [PFUser currentUser];
    if (user[@"familyId"]) {
        [self instantiatePageViewController];
        return;
    }
    
    user[@"familyId"] = [self createFamilyId];
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        PFQuery *query = [PFQuery queryWithClassName:@"TutorialMap"];
        [query whereKey:@"userId" equalTo:user[@"userId"]];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getting TutorialMap userId:%@ error:%@", user[@"userId"], error]];
                // TODO ネットワークエラーが発生しました を表示
                return;
            }
            if (objects.count > 0) {
                [self instantiatePageViewController];
            }
            PFObject *tutorialMap = [[PFObject alloc]initWithClassName:@"TutorialMap"];
            tutorialMap[@"userid"] = user[@"userId"];
            [tutorialMap saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    // TODO ネットワークエラーが発生しました を表示
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in saving TutorialMap userId:%@ error:%@", user[@"userId"], error]];
                    return;
                }
                [self instantiatePageViewController];
            }];
        }];
    }];
}

- (void)instantiatePageViewController
{
    _pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
    _pageViewController.childProperties = _childProperties;
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self setupGlobalSetting];
}

- (void)setupGlobalSetting
{
    UIButton *openGlobalSettingButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [openGlobalSettingButton setBackgroundImage:[UIImage imageNamed:@"listReverse"] forState:UIControlStateNormal];
    [openGlobalSettingButton addTarget:self action:@selector(openGlobalSettingView) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:openGlobalSettingButton];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

-(void)setNotVerifiedPage
{
    NotEmailVerifiedViewController *emailVerifiedViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NotEmailVerifiedViewController"];
    [self presentViewController:emailVerifiedViewController animated:YES completion:nil];
}


-(void)logOut
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    [PFUser logOut];
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

- (NSString*) createFamilyId
{
    IdIssue *idIssue = [[IdIssue alloc]init];
    return [idIssue issue:@"family"];
}

@end
