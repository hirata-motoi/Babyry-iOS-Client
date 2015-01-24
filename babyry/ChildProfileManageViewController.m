//
//  ChildProfileManageViewController.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/10.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ChildProfileManageViewController.h"
#import "ChildProperties.h"
#import "ChildSwitchView.h"
#import "ChildProfileIconAndNameCell.h"
#import "ChildProfileGenderCell.h"
#import "ChildProfileBirthdayCell.h"
#import "Config.h"
#import "GenderSegmentControl.h"
#import "Logger.h"
#import "DatePickerView.h"
#import "DateUtils.h"
#import "ChildIconCollectionViewController.h"
#import "IntroChildNameViewController.h"
#import "ColorUtils.h"
#import "Navigation.h"
#import "AlbumTableViewController.h"
#import "ChildPropertyUtils.h"
#import "ChildCreatePopupViewController.h"
#import "UIViewController+MJPopupViewController.h"
#import "ChildIconCollectionViewController.h"
#import "ChildIconManager.h"
#import "PushNotification.h"

@interface ChildProfileManageViewController ()

@end

@implementation ChildProfileManageViewController {
    NSMutableArray *childProperties;
    NSString *switchTargetChild;
    DatePickerView *datePickerView;
    BOOL observing;
    NSString *targetChild;
    NSString *removeTargetChild;
    ChildProfileIconAndNameCell *targetCell;
    ChildPropertyUtils *childPropertyUtils;
    MBProgressHUD *hud;
}                   

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _profileTable.delegate = self;
    _profileTable.dataSource = self;
    [self setupChildProperties];
    
    _openChildAddButton.layer.cornerRadius = 6.0f;
    _openChildAddButton.layer.masksToBounds = YES;
    
    [Navigation setTitle:self.navigationItem withTitle:@"こども設定" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
    
    [_profileTable registerNib:[UINib nibWithNibName:@"ChildProfileIconAndNameCell" bundle:nil] forCellReuseIdentifier:@"IconCell"];
    [_profileTable registerNib:[UINib nibWithNibName:@"ChildProfileGenderCell" bundle:nil] forCellReuseIdentifier:@"GenderCell"];
    [_profileTable registerNib:[UINib nibWithNibName:@"ChildProfileBirthdayCell" bundle:nil] forCellReuseIdentifier:@"BirthdayCell"];
    
    UITapGestureRecognizer *closeEditingTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeEditing)];
    closeEditingTapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:closeEditingTapGesture];
    
    childPropertyUtils = [[ChildPropertyUtils alloc]init];
    childPropertyUtils.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadChildProfile) name:@"childPropertiesChanged" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [_profileTable reloadData];
    if (!observing) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self
                   selector:@selector(keyboardWillShow:)
                       name:UIKeyboardWillShowNotification
                     object:nil];
        
        [center addObserver:self
                   selector:@selector(keybaordWillHide:)
                       name:UIKeyboardWillHideNotification
                     object:nil];
        
        observing = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)cellType:(NSIndexPath *)indexPath
{
    int r = indexPath.row % 3;
    return (r == 0) ? @"IconAndName" :
           (r == 1) ? @"Gender"      :
           (r == 2) ? @"Birthday"    : nil;
}

- (void)switchGender:(id)sender
{
    GenderSegmentControl *segment = (GenderSegmentControl *)sender;
    NSString *childObjectId = segment.childObjectId;
    switch (segment.selectedSegmentIndex) {
        case 0: {
            // 性別を女に設定
            NSMutableDictionary *params = [[NSMutableDictionary alloc]initWithObjectsAndKeys:@"female", @"sex", nil];
            [childPropertyUtils saveChildProperty:childObjectId withParams:params];
            break;
        }
        case 1: {
            // 性別を男に設定
            NSMutableDictionary *params = [[NSMutableDictionary alloc]initWithObjectsAndKeys:@"male", @"sex", nil];
            [childPropertyUtils saveChildProperty:childObjectId withParams:params];
            break;
        }
        default:
            break;
    }
}

- (void)openDatePickerView:(NSString *)childObjectId
{
    [self closeEditing];
    
    if (datePickerView) {
        return;
    }
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:childObjectId];
  
    datePickerView = [DatePickerView view];
    datePickerView.delegate = self;
    datePickerView.childObjectId = childObjectId;
    if (childProperty[@"birthday"]) {
        datePickerView.datepicker.date = childProperty[@"birthday"];
    }
    datePickerView.childNameLabel.text = childProperty[@"name"];
   
    CGRect rect = datePickerView.frame;
    rect.origin.y = self.view.frame.size.height;
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
//    [self showOverlay];
}

- (void)saveBirthday:(NSString *)childObjectId
{
    if (! datePickerView) {
        return;
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
    params[@"birthday"] = [DateUtils setSystemTimezoneAndZero:datePickerView.datepicker.date];
    [childPropertyUtils saveChildProperty:childObjectId withParams:params];
    [self setupChildProperties];
    [_profileTable reloadData];
    
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

- (void)setupChildProperties
{
    if (childProperties) {
        [childProperties removeAllObjects];
        childProperties = nil;
    }
    childProperties = [ChildProperties getChildProperties];
}

- (void)showOverlay
{
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    UIView *overlay = [[UIView alloc]initWithFrame:screenRect];
    
    UITapGestureRecognizer *overlayTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeEditing)];
    overlayTapGesture.numberOfTapsRequired = 1;
    [overlay addGestureRecognizer:overlayTapGesture];
    
    [self.view addSubview:overlay];
}

- (void)closeEditing
{
    NSArray *cells = [_profileTable visibleCells];
    for (UITableViewCell *cell in cells) {
        if ([cell isKindOfClass:[ChildProfileIconAndNameCell class]]) {
            ChildProfileIconAndNameCell *c = (ChildProfileIconAndNameCell *)cell;
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

- (void)keyboardWillShow:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    CGRect keyboardFrameEnd = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    float screenHeight = screenBounds.size.height;
    
    // 対象のcellを探す
    for (UITableViewCell *c in [_profileTable visibleCells]) {
        if ([c isKindOfClass:[ChildProfileIconAndNameCell class]]) {
            ChildProfileIconAndNameCell *cell = (ChildProfileIconAndNameCell *)c;
            if ([cell.childObjectId isEqualToString:targetChild]) {
                targetCell = cell;
                break;
            }
        }
    }
    if (!targetCell) {
        return;
    }
    CGPoint offset = _profileTable.contentOffset;
    if((targetCell.frame.origin.y + targetCell.frame.size.height - offset.y) > (screenHeight - keyboardFrameEnd.size.height - 20)){
        // テキストフィールドがキーボードで隠れるようなら
        // 選択中のテキストフィールドの直ぐ下にキーボードの上端が付くように、スクロールビューの位置を上げる
        [UIView animateWithDuration:0.3
                         animations:^{
                             CGFloat diff = targetCell.frame.origin.y + targetCell.frame.size.height - offset.y - (screenHeight - keyboardFrameEnd.size.height - 20);
                             CGRect tableRect = _profileTable.frame;
                             _profileTable.frame = CGRectMake(0, tableRect.origin.y - diff, _profileTable.frame.size.width,_profileTable.frame.size.height);
                         }];
    }
}

- (void)keybaordWillHide:(NSNotification*)notification
{
    // viewのy座標を元に戻してキーボードをしまう
    [UIView animateWithDuration:0.2
                     animations:^{_profileTable.frame = CGRectMake(0, 0, _profileTable.frame.size.width, _profileTable.frame.size.height);
                     }];
    targetCell = nil;
    return;
}

- (void)setTargetChild:(NSString *)childObjectId
{
    targetChild = childObjectId;
}

- (void)openIconEdit:(NSString *)childObjectId
{
    ChildIconCollectionViewController *childIconCollectionViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChildIconCollectionViewController"];
    childIconCollectionViewController.childObjectId = childObjectId;
    childIconCollectionViewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:childIconCollectionViewController];
    [self.navigationController presentViewController:navController animated:YES completion:nil];
    
}

- (void)showIconEditActionSheet:(NSString *)childObjectId
{
    [self presentViewController:[childPropertyUtils iconEditActionSheet:childObjectId] animated:YES completion:nil];
}

- (void)openAlbumPicker:(NSString *)childObjectId
{
    AlbumTableViewController *albumTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumTableViewController"];
    albumTableViewController.childObjectId = childObjectId;
   
    NSDateComponents *comps = [DateUtils dateCompsFromDate:[NSDate date]];
    albumTableViewController.date = [NSString stringWithFormat:@"%04ld%02ld%02ld", comps.year, comps.month, comps.day];
    
    albumTableViewController.uploadType = @"icon";
    [self.navigationController pushViewController:albumTableViewController animated:YES];
}

- (void)reloadChildProfile
{
    [childProperties removeAllObjects];
    childProperties = nil;
    childProperties = [ChildProperties getChildProperties];
    [_profileTable reloadData];
}

- (void)resetFields
{
    [self setupChildProperties];
    [_profileTable reloadData];
}

#pragma mark - Add Child
- (IBAction)openChildAdd:(id)sender {
    ChildCreatePopupViewController *childCreatePopupViewController = [[ChildCreatePopupViewController alloc]initWithNibName:@"ChildCreatePopupViewController" bundle:nil];
    childCreatePopupViewController.delegate = self;
    [self presentPopupViewController:childCreatePopupViewController animationType:MJPopupViewAnimationFade];
}

#pragma mark - Delegate for ChildCreatePopupViewController
- (void)hidePopup
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (id)getParentViewController
{
    return self;
}


#pragma mark - Remove Child

- (void)removeChild:(NSString *)childObjectId
{
    if (childProperties.count == 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"こどもが0人になります"
                                                        message:@"こどもは最低一人は登録しておく必要があります。"
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
        return;
    }
    
    removeTargetChild = childObjectId;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"削除しますか？"
                                                    message:@"一度削除したこどものデータは復旧できません。削除を実行しますか？"
                                                   delegate:self
                                          cancelButtonTitle:@"戻る"
                                          otherButtonTitles:@"削除", nil
                          ];
    [alert show];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
        {
            removeTargetChild = nil;
        }
            break;
        case 1:
        {
            childProperties = [ChildProperties getChildProperties];
            hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.labelText = @"削除中";
            PFQuery *childQuery = [PFQuery queryWithClassName:@"Child"];
            [childQuery whereKey:@"objectId" equalTo:removeTargetChild];
            [childQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (error) {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in find child in alertView %@", error]];
                    return;
                }
                
                if (objects.count < 1) {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Child not found in alertView"]];
                    return;
                }

                PFObject *object = objects[0];
                [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error) {
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in child delete in alertView %@", error]];
                        return;
                    }
                    
                    if (succeeded) {
                        [ChildProperties deleteByObjectId:removeTargetChild];
                        [hud hide:YES];
                        removeTargetChild = nil;
                        [self reloadChildProfile];
                        
                        // 念のため裏でsync
                        [ChildProperties asyncChildProperties];
                        
                        NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
                        [[NSNotificationCenter defaultCenter] postNotification:n];
                    }
                }];
            }];
        }
            break;
    }
}

#pragma mark - Delegate for ChildIconCollectionViewController
- (void)submit:(NSData *)imageData withChildObjectId:(NSString *)childObjectId
{
    [ChildIconManager updateChildIcon:imageData withChildObjectId:childObjectId];
    [self sendPushNotification];
}

- (void)sendPushNotification
{
    NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
    transitionInfoDic[@"event"] = @"childIconChanged";
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    options[@"data"] = [[NSMutableDictionary alloc]
                        initWithObjects:@[transitionInfoDic, [NSNumber numberWithInt:1], @""]
                        forKeys:@[@"transitionInfo", @"content-available", @"sound"]];
    [PushNotification sendInBackground:@"childIconChanged" withOptions:options];
}

#pragma mark - TableView Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // テーブルに表示するデータ件数を返す;
    return childProperties.count * 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int childIndex = floor(indexPath.row / 3);
    NSString *cellType = [self cellType:indexPath];
    
    if ([cellType isEqualToString:@"IconAndName"]) {
        ChildProfileIconAndNameCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IconCell" forIndexPath:indexPath];
        cell.delegate = self;
        ChildSwitchView *iconView = [ChildSwitchView view];
        [iconView setParams:childProperties[childIndex][@"objectId"] forKey:@"childObjectId"];
        [iconView setParams:@"" forKey:@"childName"];
        [iconView setup];
        [iconView removeGestures];
        iconView.childNameLabel.hidden = YES;
        
        cell.childNameLabel.text = childProperties[childIndex][@"name"];
       
        for (UIView *v in [cell.iconContainer subviews]) {
            if (![v isKindOfClass:[UILabel class]]) {
                [v removeFromSuperview];
            }
        }
        [cell.iconContainer insertSubview:iconView belowSubview:cell.editLabel];
        
        cell.childObjectId = childProperties[childIndex][@"objectId"];
       
        return cell;
    } else if ([cellType isEqualToString:@"Gender"]) {
        ChildProfileGenderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GenderCell" forIndexPath:indexPath];
        cell.delegate = self;
       
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        NSString *sex = childProperties[childIndex][@"sex"];
        if (sex) {
            params[@"gender"] = sex;
        }
        params[@"childObjectId"] = childProperties[childIndex][@"objectId"];
        [cell setupSegmentControl:params];
      
        return cell;
    } else if ([cellType isEqualToString:@"Birthday"]) {
        ChildProfileBirthdayCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BirthdayCell" forIndexPath:indexPath];
        cell.delegate = self;
        cell.childObjectId = childProperties[childIndex][@"objectId"];
        
        if (childProperties[childIndex][@"birthday"]) {
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            df.dateFormat = @"yyyy/MM/dd";
            cell.birthdayLabel.text = [df stringFromDate:childProperties[childIndex][@"birthday"]];
        }
        return cell;
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// セルの高さをtextの高さに合わせる
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self cellType:indexPath] isEqualToString:@"IconAndName"]) {
        return 88.0f;
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
    return 20.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 20.0f)];
    sectionView.backgroundColor = [ColorUtils getLightPositiveColor];
   
    CGRect labelRect = sectionView.frame;
    labelRect.origin.x = 10.0f;
    labelRect.size.width = labelRect.size.width - labelRect.origin.x * 2;
    UILabel *label = [[UILabel alloc]initWithFrame:labelRect];
    label.textAlignment = NSTextAlignmentLeft;
    label.textColor = [UIColor whiteColor];
    label.text = @"登録済のこども一覧";
    label.font = [UIFont boldSystemFontOfSize:12.0f];
    
    [sectionView addSubview:label];
    
    return sectionView;
}


@end
