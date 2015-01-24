//
//  ChildCreatePopupViewController.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/25.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ChildCreatePopupViewController.h"
#import "DatePickerView.h"
#import "ChildProfileIconCell.h"
#import "ChildProfileNameCell.h"
#import "ChildProfileBirthdayCell.h"
#import "ChildProfileGenderCell.h"
#import "GenderSegmentControl.h"
#import "ColorUtils.h"
#import "ChildPropertyUtils.h"
#import "DateUtils.h"
#import "ChildIconCollectionViewController.h"
#import "AlbumTableViewController.h"
#import "Logger.h"
#import "ChildProperties.h"
#import "Sharding.h"
#import "Tutorial.h"
#import "ImageCache.h"
#import "PushNotification.h"
#import "ChildIconManager.h"

@interface ChildCreatePopupViewController ()

@end

@implementation ChildCreatePopupViewController {
    ChildPropertyUtils *childPropertyUtils;
    DatePickerView *datePickerView;
    MBProgressHUD *hud;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _editTable.delegate = self;
    _editTable.dataSource = self;
    // Do any additional setup after loading the view from its nib.
    [_editTable registerNib:[UINib nibWithNibName:@"ChildProfileIconCell" bundle:nil] forCellReuseIdentifier:@"IconCell"];
    [_editTable registerNib:[UINib nibWithNibName:@"ChildProfileNameCell" bundle:nil] forCellReuseIdentifier:@"NameCell"];
    [_editTable registerNib:[UINib nibWithNibName:@"ChildProfileGenderCell" bundle:nil] forCellReuseIdentifier:@"GenderCell"];
    [_editTable registerNib:[UINib nibWithNibName:@"ChildProfileBirthdayCell" bundle:nil] forCellReuseIdentifier:@"BirthdayCell"];
    
    childPropertyUtils = [[ChildPropertyUtils alloc]init];
    childPropertyUtils.delegate = self;
    
    UITapGestureRecognizer *closeEditingTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeEditing)];
    closeEditingTapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:closeEditingTapGesture];
    
    // サイズ調整
//    self.view.frame = [[UIScreen mainScreen] applicationFrame];
    self.view.frame = [[UIScreen mainScreen] bounds];
}

- (void)openDatePickerView:(NSString *)childObjectId
{
    [self closeEditing];
    if (datePickerView) {
        return;
    }
  
    datePickerView = [DatePickerView view];
    datePickerView.delegate = self;
    datePickerView.childNameLabel.text = @"誕生日を選択";
   
    CGRect rect = datePickerView.frame;
    rect.origin.y = self.view.frame.size.height;
    rect.origin.x = (self.view.frame.size.width - rect.size.width) / 2;
    datePickerView.frame = rect;
    
    [self.view addSubview:datePickerView];
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         CGRect rect = datePickerView.frame;
                         rect.origin.y = self.view.frame.size.height - rect.size.height;
                         datePickerView.frame = rect;
                     }
                     completion:nil];
}

- (NSString *)cellType:(NSIndexPath *)indexPath
{
    int r = indexPath.row % 4;
    return (r == 0) ? @"Icon"        :
           (r == 1) ? @"Name"        :
           (r == 2) ? @"Gender"      :
           (r == 3) ? @"Birthday"    : nil;
}

- (void)closeEditing
{
    NSArray *cells = [_editTable visibleCells];
    for (UITableViewCell *cell in cells) {
        if ([cell isKindOfClass:[ChildProfileNameCell class]]) {
            ChildProfileNameCell *c = (ChildProfileNameCell *)cell;
            [c closeEditField];                               
        }
    }
    if (datePickerView) {
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             CGRect rect = datePickerView.frame;
                             rect.origin.y = self.view.frame.size.height;
                             datePickerView.frame = rect;
                         }
                         completion:^(BOOL finished) {
                             [datePickerView removeFromSuperview];
                             datePickerView = nil;
                         }];
    }
}

- (void)saveBirthday:(NSString *)childObjectId
{
    if (! datePickerView) {
        return;
    }
    
    for (id cell in [_editTable visibleCells]) {
        if ([cell isKindOfClass:[ChildProfileBirthdayCell class]]) {
            [cell setBirthdayLabelText:datePickerView.datepicker.date];
        }
    }
    
    [self closeEditing];
}

//- (void)openIconEdit:(NSString *)childObjectId
//{
//    [_delegate openIconEdit:childObjectId];
//}
//
//- (void)openAlbumPicker:(NSString *)childObjectId
//{
//    [_delegate openAlbumPicker:childObjectId];
//}

//- (void)openIconEdit:(NSString *)childObjectId
//{
//    // TODO ChildCreateViewControllerのdelegateをたたく
//    ChildIconCollectionViewController *childIconCollectionViewController = [[[_delegate parentViewController] storyboard] instantiateViewControllerWithIdentifier:@"ChildIconCollectionViewController"];
//    childIconCollectionViewController.delegate = self;
//    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:childIconCollectionViewController];
//    [self presentViewController:navController animated:YES completion:nil];
//}
//
//- (void)openAlbumPicker:(NSString *)childObjectId
//{
//    // TODO ChildCreateViewControllerのdelegateをたたく
//    AlbumTableViewController *albumTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumTableViewController"];
//    albumTableViewController.childObjectId = childObjectId;
//   
//    NSDateComponents *comps = [DateUtils dateCompsFromDate:[NSDate date]];
//    albumTableViewController.date = [NSString stringWithFormat:@"%04ld%02ld%02ld", comps.year, comps.month, comps.day];
//    
//    albumTableViewController.uploadType = @"icon";
////    [self.navigationController pushViewController:albumTableViewController animated:YES];
//    [self presentViewController:albumTableViewController animated:YES completion:nil];
//}

- (void)submit:imageData withChildObjectId:childObjectId
{
    for (id c in [_editTable visibleCells]) {
        if ([c isKindOfClass:[ChildProfileIconCell class]]) {
            [c setIconImageWithData:imageData];
        }
    }
}

//- (void)creatChild
//{
    // ぐるぐる出す
    // parseにデータを保存
    // 成功したら保持しているサムネイルでキャッシュを作る + AWSにアップ
    // [ChildIconManager updateChildIcon:imageData withChildObjectId:_childObjectId];
    // childPropertyChangedをcall
    // ポップアップを消す
//}

- (IBAction)cancel:(id)sender {
    [_delegate hidePopup];
}

- (IBAction)createChild:(id)sender {
    // データを集める
    NSMutableDictionary *childInfo = [[NSMutableDictionary alloc]init];
    for (id c in [_editTable visibleCells]) {
        if ([c isKindOfClass:[ChildProfileIconCell class]]) {
            ChildProfileIconCell *cell = (ChildProfileIconCell *)c;
            if (cell.imageData) {
                childInfo[@"imageData"] = cell.imageData;
            }
        } else if ([c isKindOfClass:[ChildProfileNameCell class]]) {
            ChildProfileNameCell *cell = (ChildProfileNameCell *)c;
            if (cell.nameField.text) {
                childInfo[@"name"] = cell.nameField.text;
            }
        } else if ([c isKindOfClass:[ChildProfileGenderCell class]]) {
            // TODO cellで管理する
            ChildProfileGenderCell *cell = (ChildProfileGenderCell *)c;
            if (cell.segmentControl.selected) {
                childInfo[@"sex"] = (cell.segmentControl.selectedSegmentIndex == 0) ? @"female" : @"male";
            }
        } else if ([c isKindOfClass:[ChildProfileBirthdayCell class]]) {
            ChildProfileBirthdayCell *cell = (ChildProfileBirthdayCell *)c;
            if (cell.birthday) {
                childInfo[@"birthday"] = cell.birthday;
            }
        }
    }
    // validate
    NSString *error = [self validateParams:childInfo];
    if (error) {
        // TODO もしこのview controllerから無理やったらViewControllerのdelegateをたたく
        [self showAlertMessage:error];
        return;
    }
    // ぐるぐる出す
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"データ更新中";
    
    PFQuery *user = [PFQuery queryWithClassName:@"_User"];
    [user whereKey:@"userId" equalTo:[PFUser currentUser][@"userId"]];
    user.cachePolicy = kPFCachePolicyNetworkElseCache;
    [user findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ネットワークエラー"
                                                            message:@"エラーが発生しました。もう一度お試しください。"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
            [hud hide:YES];
            return;
        }
        if ([objects count] > 0) {
            PFObject *child = [PFObject objectWithClassName:@"Child"];
            child[@"name"] = childInfo[@"name"];
            if (childInfo[@"sex"]) {
                child[@"sex"] = childInfo[@"sex"];
            }
            if (childInfo[@"birthday"]) {
                child[@"birthday"] = [DateUtils setSystemTimezoneAndZero:childInfo[@"birthday"]];
            }
            child[@"familyId"] = objects[0][@"familyId"];
            child[@"createdBy"] = [PFUser currentUser];
            child[@"childImageShardIndex"] = [NSNumber numberWithInteger: [Sharding shardIndexWithClassName:@"ChildImage"]];
            child[@"commentShardIndex"] = [NSNumber numberWithInteger: [Sharding shardIndexWithClassName:@"Comment"]];
            [child save];
            [child fetch];
            [ChildProperties syncChildProperties];
            
            // アイコンを保存
            // TODO これって非同期やっけ？失敗したらどうしようかな
            if (childInfo[@"imageData"]) {
                [ChildIconManager updateChildIcon:childInfo[@"imageData"] withChildObjectId:child.objectId];
            }

            // もしtutorial中だった場合はデフォルトのこどもの情報を消す
            if ([Tutorial underTutorial] && [Tutorial existsTutorialChild]) {
                [ImageCache removeAllCache];
                [Tutorial forwardStageWithNextStage:@"uploadByUser"];
            }
            
            NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:n];
            
            [hud hide:YES];
            [_delegate hidePopup];
            
            [self sendPushNotification:child[@"name"]];
        }
    }];
}

- (void)sendPushNotification:(NSString *)childName
{
    NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
    transitionInfoDic[@"event"] = @"childAdded";
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    options[@"data"] = [[NSMutableDictionary alloc]
                        initWithObjects:@[@"Increment", transitionInfoDic]
                        forKeys:@[@"badge", @"transitionInfo"]];
    options[@"formatArgs"] = [NSArray arrayWithObjects:[PFUser currentUser][@"nickName"], childName,  nil];
    [PushNotification sendInBackground:@"childAdded" withOptions:options];
}


// 不備があればエラーメッセージを返す
- (NSString *)validateParams:(NSMutableDictionary *)params
{
    // こどもが既に5人いたらエラー
    // 名前が未設定ならエラー
    // 性別がnil、male、female以外ならエラー
    // 誕生日がnilかNSDate以外ならエラー
    NSMutableArray *childProperties = [ChildProperties getChildProperties];
    if (childProperties.count >= 5) {
        return @"こどもを作成できる上限は5人です。";
    }
    if (!params[@"name"] || [params[@"name"] isEqualToString:@""]) {
        return @"なまえを入力してください";
    }
    if ( !(
           params[@"sex"] == nil                     ||
           [params[@"sex"] isEqualToString:@"male"]  ||
           [params[@"sex"] isEqualToString:@"female"]
           )
    ) {
        // あり得ないケースなのでログだけはく
        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Invalid sex was inputted :%@", params[@"sex"]]];
        // 変なデータは保存しない
        params[@"sex"] = nil;
        return nil;
    }
    if ( !(params[@"birthday"] == nil || [params[@"birthday"] isKindOfClass:[NSDate class]]) ) {
        // あり得ないケースなのでログだけはく
        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Invalid birthday was inputted :%@", params[@"birthday"]]];
        // 変なデータは保存しない
        params[@"birthday"] = nil;
        return nil;
    }
    
    return nil;
}


- (void)showIconEditActionSheet:(NSString *)childObjectId
{
    [self presentViewController:[childPropertyUtils iconEditActionSheet:childObjectId] animated:YES completion:nil];
}

- (void)openIconEdit:(NSString *)childObjectId
{
    ChildIconCollectionViewController *childIconCollectionViewController = [[[_delegate getParentViewController] storyboard] instantiateViewControllerWithIdentifier:@"ChildIconCollectionViewController"];
    childIconCollectionViewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:childIconCollectionViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)openAlbumPicker:(NSString *)childObjectId
{
    AlbumTableViewController *albumTableViewController = [[[_delegate getParentViewController] storyboard] instantiateViewControllerWithIdentifier:@"AlbumTableViewController"];
    albumTableViewController.childObjectId = childObjectId;
   
    NSDateComponents *comps = [DateUtils dateCompsFromDate:[NSDate date]];
    albumTableViewController.date = [NSString stringWithFormat:@"%04ld%02ld%02ld", comps.year, comps.month, comps.day];
    
    albumTableViewController.uploadType = @"icon";
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:albumTableViewController];
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    [closeButton setBackgroundImage:[UIImage imageNamed:@"closeIcon"] forState:UIControlStateNormal];
    [closeButton addTarget:albumTableViewController action:@selector(closeAlbumTable) forControlEvents:UIControlEventTouchUpInside];
    albumTableViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    albumTableViewController.navigationController.navigationBar.barTintColor = [ColorUtils getBabyryColor];
    
    [self presentViewController:navController animated:YES completion:nil];
    
}

- (void)showAlertMessage:(NSString *)error
{
    UIAlertController *alertControl = [UIAlertController alertControllerWithTitle:@"入力内容をご確認ください" message:error preferredStyle:UIAlertControllerStyleAlert];
    [alertControl addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertControl animated:YES completion:nil];
}

- (void)hidePopup
{
    [_delegate hidePopup];
}

- (void)switchGender:(id)sender
{
    // nothing to do
}


#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // テーブルに表示するデータ件数を返す;
    return 4;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellType = [self cellType:indexPath];

    if ([cellType isEqualToString:@"Icon"]) {
        ChildProfileIconCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IconCell" forIndexPath:indexPath];
        cell.delegate = self;
        return cell;
    } else if ([cellType isEqualToString:@"Name"]) {
        ChildProfileNameCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NameCell" forIndexPath:indexPath];
        return cell;
    } else if ([cellType isEqualToString:@"Gender"]) {
        ChildProfileGenderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GenderCell" forIndexPath:indexPath];
        cell.delegate = self;
       
        [cell setupSegmentControl:[[NSMutableDictionary alloc]init]];
        return cell;
    } else if ([cellType isEqualToString:@"Birthday"]) {
        ChildProfileBirthdayCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BirthdayCell" forIndexPath:indexPath];
        cell.birthdayLabel.text = @"未設定";
        CGRect rect = cell.birthdayLabel.frame;
        rect.origin.x = (_editTable.frame.size.width - rect.size.width - 20);
        cell.birthdayLabel.frame = rect;
        cell.delegate = self;
        return cell;
    } else {
        UITableViewCell *cell = [[UITableViewCell alloc]init];
        return cell;
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self cellType:indexPath] isEqualToString:@"Icon"]) {
        return 66.0f;
    } else {
        return 44.0f;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 何もしない
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
}

@end
