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
#import "CheckAppVersion.h"
#import "TmpUser.h"
#import "Tutorial.h"
#import "TutorialAttributes.h"
#import "DateUtils.h"
#import "PartnerInvitedEntity.h"
#import "PartnerWaitViewController.h"
#import "ParseUtils.h"
#import "ChildProperties.h"
#import "PartnerApply.h"

@interface ViewController ()

@end

@implementation ViewController {
    NSMutableDictionary *oldestChildImageDate;
}

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
    self.navigationController.delegate = self;
    self.navigationController.navigationBar.barTintColor = [UIColor_Hex colorWithHexString:@"f4c510" alpha:1.0f];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithTitle:@""
                                             style:UIBarButtonItemStylePlain
                                             target:nil
                                             action:nil];
    
    // partner情報初期化
    [Partner initialize];
    
    // sharding conf初期化
    [Sharding setupShardConf];
    
    // notification center
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPageViewController) name:@"childPropertiesChanged" object:nil];
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
        
        // 招待されて認証コードを入力した人はここで承認まで待つ (ただし、familyIdがある人はチュートリアルをやったか、一回ひも付けが解除されている人なので除外)
        if (_only_first_load == 1) {
            [PartnerApply syncPartnerApply];
        }
        PartnerInvitedEntity *pie = [PartnerInvitedEntity MR_findFirst];
        if (pie && !_currentUser[@"familyId"]) {
            PartnerWaitViewController *partnerWaitViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PartnerWaitViewController"];
            [self presentViewController:partnerWaitViewController animated:YES completion:NULL];
            return;
        }
      
        // familyIdを発行する前に呼び出す必要がある
        if (_only_first_load == 1) {
            [self initializeTutorialStage];
        }
        
        // familyIdがなければ新規にfamilyIdを発行
        if (!_currentUser[@"familyId"]) {
            IdIssue *idIssue = [[IdIssue alloc]init];
            _currentUser[@"familyId"] = [idIssue issue:@"family"];
            [_currentUser saveInBackground];
            
            // その上でbotと紐付けをする TutorialMapにデータを保存
            PFObject *tutorialMap = [PFObject objectWithClassName:@"TutorialMap"];
            tutorialMap[@"userId"] = _currentUser[@"userId"];
            [tutorialMap saveInBackground];
            
            // chooserに設定
            PFObject *familyRole = [PFObject objectWithClassName:@"FamilyRole"];
            familyRole[@"familyId"] = _currentUser[@"familyId"];
            familyRole[@"chooser"]  = _currentUser[@"userId"];
            familyRole[@"uploader"] = @"";
            familyRole[@"createdBy"] = _currentUser[@"userId"];
            [familyRole saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in saving FamilyRole:%@", error]];
                    return;
                }
                [FamilyRole updateCache];
            }];
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
            NSMutableArray *childProperties = [ChildProperties syncChildProperties];
            if (childProperties.count < 1) {
                if ([[Tutorial currentStage].currentStage isEqualToString:@"familyApplyExec"]) {
                    [self setChildNames];
                    return;
                }
                // こどもがいないのでbabyryちゃんのobjectIdをConfigから引く → _childArrayFromParseにセット
                // ここは同期で処理する
                PFQuery *query = [PFQuery queryWithClassName:@"Config"]; // TODO Configクラスに切り出し
                [query whereKey:@"key" equalTo:@"tutorialChild"];
                NSArray *botUsers = [query findObjects];
                if (botUsers.count > 0) {
                    NSString *childObjectId = botUsers[0][@"value"];
                    
                    [Tutorial upsertTutorialAttributes:@"tutorialChildObjectId" withValue:childObjectId];
                    
                    // Childからbotのrowをひく
                    NSMutableDictionary *botChildProperty = [ChildProperties syncChildProperty:childObjectId];
                    
                    if (!botChildProperty) {
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"No Bot User in Child class objectId:%@", childObjectId]];
                    }
                } else {
                    [Logger writeOneShot:@"crit" message:@"No Bot User Setting in Config class"];
                }
            }
            _only_first_load = 0;
            
            [_hud hide:YES];
        } else {
            // 二回目以降はchildPropertiesの更新を行わない
            // PageContentViewControllerの方に委譲しているため
            TutorialStage *currentStage = [Tutorial currentStage];
            if ([currentStage.currentStage isEqualToString:@"familyApplyExec"] && [[ChildProperties getChildProperties] count] == 0) {
                [self setChildNames];
            }
        }
        [self showPageViewController];
    }
}

- (void)openGlobalSettingView
{
    GlobalSettingViewController *globalSettingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GlobalSettingViewController"];
    globalSettingViewController.viewController = self;
    [self.navigationController pushViewController:globalSettingViewController animated:YES];
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
                return;
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
    NSMutableArray *childProperties = [ChildProperties getChildProperties];
    if (childProperties.count < 1) {
        return;
    }
    _pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
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
    [self.navigationController pushViewController:introChildNameViewController animated:YES];
}

- (NSString*) createFamilyId
{
    IdIssue *idIssue = [[IdIssue alloc]init];
    return [idIssue issue:@"family"];
}

- (void)reloadPageViewController
{
    [_pageViewController.view removeFromSuperview];
    [_pageViewController removeFromParentViewController];
    _pageViewController = nil;
   
    [self instantiatePageViewController];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [Logger writeToTrackingLog:[NSString stringWithFormat:@"%@ %@ %@ %@", [DateUtils setSystemTimezone:[NSDate date]], _currentUser.objectId, _currentUser[@"userId"], NSStringFromClass([viewController class])]];
    
    // 動的に[self.navigationController topViewController]とかでとるとタイミングによってnullが帰ってくるので、TransitionByPushNotificationのclass変数に格納
    [TransitionByPushNotification setCurrentViewController:NSStringFromClass([viewController class])];
}

- (BOOL)hasStartedTutorial
{
    BOOL hasStartedTutorial = NO;
    if (_currentUser && _currentUser[@"userId"]) {
        PFQuery *query = [PFQuery queryWithClassName:@"TutorialMap"];
        [query whereKey:@"userId" equalTo:_currentUser[@"userId"]];
        NSArray *objects = [query findObjects];
        hasStartedTutorial = (objects.count > 0);
    }
    return hasStartedTutorial;
}

- (void)initializeTutorialStage
{
    // 既にTutorialStageがあったらreturn
    if ([Tutorial currentStage]) {
        return;
    }
    
    // TutorialMapの情報
    BOOL hasStartedTutorial = [self hasStartedTutorial];
    
    // パートナーのuserId取得
    NSString *partnerUserId;
    if (_currentUser[@"familyId"]) {
        PFObject *familyRole = [FamilyRole getFamilyRole:@"NetworkFirst"];
        partnerUserId = ([familyRole[@"uploader"] isEqualToString:_currentUser[@"userId"]]) ? familyRole[@"chooser"] : familyRole[@"uploader"];
    }
    
    [Tutorial initializeTutorialStage:_currentUser[@"familyId"] hasStartedTutorial:hasStartedTutorial partnerUserId:partnerUserId];
    
    if (_currentUser[@"familyId"]) {
        return;
    }
    
    // familyIdがなければ新規にfamilyIdを発行
    IdIssue *idIssue = [[IdIssue alloc]init];
    _currentUser[@"familyId"] = [idIssue issue:@"family"];
    [_currentUser saveInBackground];
    
    // その上でbotと紐付けをする TutorialMapにデータを保存
    if (!hasStartedTutorial) {
        PFObject *tutorialMap = [PFObject objectWithClassName:@"TutorialMap"];
        tutorialMap[@"userId"] = _currentUser[@"userId"];
        [tutorialMap saveInBackground];
    }
    
    // chooserに設定
    PFObject *familyRole = [PFObject objectWithClassName:@"FamilyRole"];
    familyRole[@"familyId"] = _currentUser[@"familyId"];
    familyRole[@"chooser"]  = _currentUser[@"userId"];
    familyRole[@"uploader"] = @"";
    familyRole[@"createdBy"] = _currentUser[@"userId"];
    [familyRole saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in saving FamilyRole:%@", error]];
            return;
        }
        [FamilyRole updateCache];
    }];
}

@end
