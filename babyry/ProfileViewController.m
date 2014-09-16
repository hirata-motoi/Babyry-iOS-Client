//
//  ProfileViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ProfileViewController.h"
#import "NicknameEditViewController.h"
#import "ChildProfileViewController.h"
#import "Navigation.h"
#import "PartnerApply.h"
#import "PartnerInviteViewController.h"

@interface ProfileViewController ()

@end

@implementation ProfileViewController

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
    // Do any additional setup after loading the view.
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithTitle:@""
                                             style:UIBarButtonItemStylePlain
                                             target:nil
                                             action:nil];
    _profileTableView.delegate = self;
    _profileTableView.dataSource = self;
    [Navigation setTitle:self.navigationItem withTitle:@"プロフィール" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [_profileTableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows;
    switch (section) {
        case 0:
            numberOfRows = 1;
            break;
        case 1:
            numberOfRows = 2;
            break;
        case 2:
            numberOfRows = [_childProperties count];
            break;
        default:
            break;
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProfileCellValue1"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ProfileCellValue1"];
    }
    cell.textLabel.numberOfLines = 0;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = @"あなたの名前";
                    cell.detailTextLabel.text = [PFUser currentUser][@"nickName"];
                    _nicknameCell = cell;
                    break;
                }
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = @"パートナーの名前";
                    cell.detailTextLabel.text = _partnerInfo[@"nickName"];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
                }
                case 1: {
                    if ([[PartnerApply getApplyStatus] isEqualToString:@"NoApplying"]) {
                        cell.textLabel.text = @"パートナー招待";
                    }
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
                }
                default:
                    break;
            }
            break;
        case 2: {
            // indexPath.rowに従って子供の情報をセットする
            cell.textLabel.text = _childProperties[indexPath.row][@"name"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; // 選択状態の解除
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:{
                    // ニックネーム
                    [self showNicknameEditView];
                    break;
                }
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    break;
                case 1:
                    if ([[PartnerApply getApplyStatus] isEqualToString:@"NoApplying"]) {
                        [self openPartnerApplyView];
                    }
                    break;
                    
                default:
                    break;
            }
            break;
        case 2:
            _editedChildIndex = indexPath.row;
            [self showChildInfo:indexPath.row];
        default:
            break;
    }

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case 2:
            title = @"こども";
            break;
        default:
            title = @"";
            break;
    }
    return title;
}

- (void)showNicknameEditView
{
    NicknameEditViewController *nicknameEditViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NicknameEditViewController"];
    nicknameEditViewController.delegate = self;
    CGRect tableViewRect = _nicknameCell.superview.superview.frame;
    
    nicknameEditViewController.nicknameCellRect = CGRectMake(tableViewRect.origin.x + _nicknameCell.frame.origin.x, tableViewRect.origin.y + self.navigationController.navigationBar.bounds.size.height + [[UIApplication sharedApplication]statusBarFrame].size.height + _nicknameCell.frame.origin.y, _nicknameCell.frame.size.width, _nicknameCell.frame.size.height);
    [self addChildViewController:nicknameEditViewController];
    [self.view addSubview:nicknameEditViewController.view];
    
}

- (void)changeNickname:(NSString *)nickname
{
    _nicknameCell.detailTextLabel.text = nickname;
}

- (void)showChildInfo:(NSInteger)index
{
    ChildProfileViewController *childProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChildProfileViewController"];
    NSMutableDictionary *child = _childProperties[index];
    childProfileViewController.childObjectId = child[@"objectId"];
    childProfileViewController.child = child;
    
    childProfileViewController.childName = child[@"name"];
    childProfileViewController.childBirthday = child[@"birthday"];
    [self.navigationController pushViewController:childProfileViewController animated:YES];
}

- (void)openPartnerApplyView
{
    PartnerInviteViewController *partnerInviteViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PartnerInviteViewController"];
    [self.navigationController pushViewController:partnerInviteViewController animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
