//
//  NotificationHistoryViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2015/01/08.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "NotificationHistoryViewController.h"
#import "ColorUtils.h"
#import "Navigation.h"
#import <Parse/Parse.h>
#import "NotificationHistory.h"
#import "ImageTrimming.h"
#import "Config.h"

@interface NotificationHistoryViewController ()
{
    BOOL setDisplayedAllStatus;
}

@end

@implementation NotificationHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _allKidokuButton.layer.cornerRadius = 3;
    setDisplayedAllStatus = NO;

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithTitle:@""
                                             style:UIBarButtonItemStylePlain
                                             target:nil
                                             action:nil];
    _notificationTableView.delegate = self;
    _notificationTableView.dataSource = self;
    _notificationTableView.separatorInset = UIEdgeInsetsZero;
    _notificationTableView.backgroundColor = [ColorUtils getGlobalMenuDarkGrayColor];
    // iOS8用
    if ([_notificationTableView respondsToSelector:@selector(layoutMargins)]) {
        _notificationTableView.layoutMargins = UIEdgeInsetsZero;
    }
    
    [Navigation setTitle:self.navigationItem withTitle:@"お知らせ履歴" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    setDisplayedAllStatus = NO;
    [self getNotificationHistory];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
    }
    cell.imageView.image = nil;
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont fontWithName:@"HiraKakuProN-W3" size:14];
    cell.separatorInset = UIEdgeInsetsZero;
    cell.backgroundColor = [UIColor whiteColor];
    // iOS8用
    if ([cell respondsToSelector:@selector(layoutMargins)]) {
        cell.layoutMargins = UIEdgeInsetsZero;
    }
    
    if (_notificationHistoryArray[indexPath.row]) {
        PFObject *histObject = _notificationHistoryArray[indexPath.row];
        cell.textLabel.text = [NotificationHistory getNotificationString:histObject];
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        if ([histObject[@"type"] isEqualToString:@"imageUploaded"]) {
            cell.imageView.image = [UIImage imageNamed:@"IconMenuUploaded"];
        } else if ([histObject[@"type"] isEqualToString:@"commentPosted"]) {
            cell.imageView.image = [UIImage imageNamed:@"IconMenuComment"];
        } else if ([histObject[@"type"] isEqualToString:@"requestPhoto"]) {
            cell.imageView.image = [UIImage imageNamed:@"IconMenuGMP"];
        } else if ([histObject[@"type"] isEqualToString:@"bestShotChanged"]) {
            cell.imageView.image = [UIImage imageNamed:@"IconMenuLike"];
        }
        if (![histObject[@"status"] isEqualToString:@"displayed"] && !setDisplayedAllStatus) {
            cell.backgroundColor = [ColorUtils getGlobalMenuDarkGrayColor];
        }
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_notificationHistoryArray count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; // 選択状態の解除
    
    PFObject *histObject = _notificationHistoryArray[indexPath.row];
    [TransitionByPushNotification createTransitionInfoAndTransition:histObject viewController:self];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 24)];
    headerView.backgroundColor = [ColorUtils getSectionHeaderColor];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(6, 0, 320, 24)];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.font = [UIFont fontWithName:@"HiraKakuProN-W3" size:12];
    headerLabel.text = @"お知らせ";
    [headerView addSubview:headerLabel];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 24.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooderInSection:(NSInteger)section
{
    return 12.0f;
}

- (void)getNotificationHistory
{
    [NotificationHistory getNotificationHistoryInBackground:[PFUser currentUser][@"userId"] withType:nil withChild:nil withStatus:nil withLimit:100 withBlock:^(NSArray *objects){
        _notificationHistoryArray = [[NSMutableArray alloc] initWithArray:objects];
        [_notificationTableView reloadData];
    }];
}

- (IBAction)allKidokuButtonAction:(id)sender {
    // 本当はreloadが終わったらNOに戻したいが、reloadDataがbackgroundの処理なのでこのままにする。ページ遷移をすれば戻るので問題ない。
    setDisplayedAllStatus = YES;
    [_notificationTableView reloadData];
    [NotificationHistory disableDisplayedNotificationsWithUser:[PFUser currentUser][@"userId"] withChild:nil withDate:nil withType:nil];
}
@end
