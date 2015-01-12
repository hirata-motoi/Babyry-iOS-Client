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
#import "ChildProfileIconCell.h"
#import "ChildProfileGenderCell.h"
#import "ChildProfileBirthdayCell.h"
#import "Config.h"
#import "GenderSegmentControl.h"
#import "Logger.h"
#import "DatePickerView.h"
#import "DateUtils.h"
#import "ChildIconCollectionViewController.h"
#import "IntroChildNameViewController.h"

@interface ChildProfileManageViewController ()

@end

@implementation ChildProfileManageViewController {
    NSMutableArray *childProperties;
    NSString *switchTargetChild;
    DatePickerView *datePickerView;
    BOOL observing;
    NSString *targetChild;
    ChildProfileIconCell *targetCell;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _profileTable.delegate = self;
    _profileTable.dataSource = self;
    [self setupChildProperties];
    
    _openChildAddButton.layer.cornerRadius = 6.0f;
    _openChildAddButton.layer.masksToBounds = YES;
    
    [_profileTable registerNib:[UINib nibWithNibName:@"ChildProfileIconCell" bundle:nil] forCellReuseIdentifier:@"IconCell"];
    [_profileTable registerNib:[UINib nibWithNibName:@"ChildProfileGenderCell" bundle:nil] forCellReuseIdentifier:@"GenderCell"];
    [_profileTable registerNib:[UINib nibWithNibName:@"ChildProfileBirthdayCell" bundle:nil] forCellReuseIdentifier:@"BirthdayCell"];
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
        ChildProfileIconCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IconCell" forIndexPath:indexPath];
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
       
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        NSString *sex = childProperties[childIndex][@"sex"];
        if (sex) {
            params[@"gender"] = sex;
        }
        params[@"childObjectId"] = childProperties[childIndex][@"objectId"];
       
        GenderSegmentControl *segmentControl = [[GenderSegmentControl alloc]initWithParams:params];
        
        [segmentControl addTarget:self action:@selector(switchGender:) forControlEvents:UIControlEventValueChanged];
        CGRect rect =  segmentControl.frame;
        rect.origin.x = self.view.frame.size.width - rect.size.width - 20;
        rect.origin.y = (cell.frame.size.height - rect.size.height ) / 2;
        segmentControl.frame = rect;
       
        [cell.contentView addSubview:segmentControl];
        
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
            [self saveChildProperty:childObjectId withParams:params];
            break;
        }
        case 1: {
            // 性別を男に設定
            NSMutableDictionary *params = [[NSMutableDictionary alloc]initWithObjectsAndKeys:@"male", @"sex", nil];
            [self saveChildProperty:childObjectId withParams:params];
            break;
        }
        default:
            break;
    }
}

- (void)saveChildProperty:(NSString *)childObjectId withParams:(NSMutableDictionary *)params
{
    // リセット用に保持
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:childObjectId];
    // coredataに保存
    [ChildProperties updateChildPropertyWithObjectId:childObjectId withParams:params];
    // parseを更新
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    [query whereKey:@"objectId" equalTo:childObjectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to get Child for saveChildProperty childObjectId:%@ error:%@", childObjectId, error]];
            // TODO coredataを戻す
            [self resetChildProperty:(NSMutableDictionary *)childProperty withParams:(NSMutableDictionary *)params];
            [self showAlert];
            return;
        }
        if (objects.count < 1) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Child NOT FOUND for saveChildProperty childObjectId:%@ error:%@", childObjectId, error]];
            [self resetChildProperty:(NSMutableDictionary *)childProperty withParams:(NSMutableDictionary *)params];
            [self showAlert];
            return;
        }

        PFObject *child = objects[0];
        for (NSString *key in [params allKeys]) {
            child[key] = params[key];
        }
        [child saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to save Child childObjectId:%@ error:%@", childObjectId, error]];
                [self resetChildProperty:(NSMutableDictionary *)childProperty withParams:(NSMutableDictionary *)params];
                [self showAlert];
                return;
            }
        }];
    }];
}

- (void)resetChildProperty:(NSMutableDictionary *)childProperty withParams:(NSMutableDictionary *)params
{
    NSMutableDictionary *resetParams = [[NSMutableDictionary alloc]init];
    for (NSString *key in params.allKeys) {
        resetParams[key] = childProperty[key];
    }
    [ChildProperties updateChildPropertyWithObjectId:childProperty[@"objectId"] withParams:resetParams];
  
    [self setupChildProperties];
    [_profileTable reloadData];
}

- (void)showAlert
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"ネットワークエラー"
                                                   message:@"ネットワークエラーが発生しました"
                                                  delegate:self
                                         cancelButtonTitle:@""
                                         otherButtonTitles:@"OK", nil];
    [alert show];
}

- (void)openDatePickerView:(NSString *)childObjectId
{
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
    [self showOverlay];
}

- (void)saveBirthday:(NSString *)childObjectId
{
    if (! datePickerView) {
        return;
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
    params[@"birthday"] = [DateUtils setSystemTimezoneAndZero:datePickerView.datepicker.date];
    [self saveChildProperty:childObjectId withParams:params];
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
    
    UITapGestureRecognizer *overlayTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeEditing:)];
    overlayTapGesture.numberOfTapsRequired = 1;
    [overlay addGestureRecognizer:overlayTapGesture];
    
    [self.view addSubview:overlay];
}

- (void)closeEditing:(id)sender
{
    NSArray *cells = [_profileTable visibleCells];
    for (UITableViewCell *cell in cells) {
        if ([cell isKindOfClass:[ChildProfileIconCell class]]) {
            ChildProfileIconCell *c = (ChildProfileIconCell *)cell;
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
    UIView *overlay = [sender view];
    [overlay removeFromSuperview];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    CGRect keyboardFrameEnd = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    float screenHeight = screenBounds.size.height;
    
    // 対象のcellを探す
    for (UITableViewCell *c in [_profileTable visibleCells]) {
        if ([c isKindOfClass:[ChildProfileIconCell class]]) {
            ChildProfileIconCell *cell = (ChildProfileIconCell *)c;
            if ([cell.childObjectId isEqualToString:targetChild]) {
                targetCell = cell;
                break;
            }
        }
    }
    NSLog(@"targetCell : %@", targetCell);
    if (!targetCell) {
        return;
    }
                               
    if((targetCell.frame.origin.y + targetCell.frame.size.height) > (screenHeight - keyboardFrameEnd.size.height - 20)){
        // テキストフィールドがキーボードで隠れるようなら
        // 選択中のテキストフィールドの直ぐ下にキーボードの上端が付くように、スクロールビューの位置を上げる
        [UIView animateWithDuration:0.3
                         animations:^{
                             _profileTable.frame = CGRectMake(0, screenHeight - targetCell.frame.origin.y - targetCell.frame.size.height - keyboardFrameEnd.size.height - 20, _profileTable.frame.size.width,_profileTable.frame.size.height);
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
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:childIconCollectionViewController];
    [self.navigationController presentViewController:navController animated:YES completion:nil];
    
}

- (IBAction)openChildAdd:(id)sender {
    IntroChildNameViewController *icnvc = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroChildNameViewController"];
    [self.navigationController pushViewController:icnvc animated:YES];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
