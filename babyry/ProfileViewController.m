//
//  ProfileViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ProfileViewController.h"
#import "ProfileEditViewController.h"
#import "ChildProfileViewController.h"
#import "Navigation.h"
#import "PartnerApply.h"
#import "PartnerInviteViewController.h"
#import "FamilyRole.h"
#import "ChildProperties.h"
#import "TmpUser.h"
#import "UserRegisterViewController.h"
#import "NotEmailVerifiedViewController.h"
#import "Logger.h"
#import "PasswordChangeViewController.h"

@interface ProfileViewController ()

@end

@implementation ProfileViewController {
    NSMutableArray *childProperties;
    BOOL emailVerified;
}

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
    childProperties = [ChildProperties getChildProperties];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithTitle:@""
                                             style:UIBarButtonItemStylePlain
                                             target:nil
                                             action:nil];
    _profileTableView.delegate = self;
    _profileTableView.dataSource = self;
    [Navigation setTitle:self.navigationItem withTitle:@"プロフィール" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];

    emailVerified = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    childProperties = [ChildProperties getChildProperties];
    
    PFQuery *query = [PFQuery queryWithClassName:@"EmailVerify"];
    [query whereKey:@"email" equalTo:[PFUser currentUser][@"emailCommon"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (error) {
            [Logger writeOneShot:@"cirt" message:[NSString stringWithFormat:@"Error in get emal vverify : %@", error]];
            return;
        }
        if ([objects count] > 0) {
            if ([objects[0][@"isVerified"] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
                emailVerified = YES;
            }
            [_profileTableView reloadData];
        }
    }];
    
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
            if ([TmpUser checkRegistered]) {
                numberOfRows = 3;
            } else {
                numberOfRows = 1;
            }
            break;
        case 2: {
            if (![PartnerApply linkComplete]) {
                numberOfRows = 2;
            } else {
                numberOfRows = 1; // TODO 紐付け解除機能を実装すれば2にする
            }
            break;
        }
        case 3:
            numberOfRows = [childProperties count];
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
                    if ([TmpUser checkRegistered]) {
                        cell.textLabel.text = [PFUser currentUser][@"emailCommon"];
                        _emailCell = cell;
                    } else {
                        cell.textLabel.text = @"本登録を完了する";
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    }
                    break;
                }
                case 1: {
                    cell.textLabel.text = @"メールアドレス認証";
                    if (emailVerified) {
                        cell.detailTextLabel.text = @"完了";
                    } else {
                        cell.detailTextLabel.text = @"未済";
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    }
                    break;
                }
                case 2: {
                    cell.textLabel.text = @"パスワード変更";
                    break;
                }
                default:
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = @"パートナーの名前";
                    cell.detailTextLabel.text = _partnerInfo[@"nickName"];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
                }
                case 1: {
                    if (![PartnerApply linkComplete]) {
                        cell.textLabel.text = @"パートナー招待";
                    } else {
                        cell.textLabel.text = @"パートナーひも付け解除";
                    }
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
                }
                default:
                    break;
            }
            break;
        case 3: {
            // indexPath.rowに従って子供の情報をセットする
            cell.textLabel.text = childProperties[indexPath.row][@"name"];
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
                    [self showProfileEditView:@"nickname"];
                    break;
                }
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0: {
                    if ([TmpUser checkRegistered]) {
                        [self showProfileEditView:@"email"];
                    } else {
                        [self openRegisterView];
                    }
                    break;
                }
                case 1: {
                    if (!emailVerified) {
                        [self openEmailVerifiedView];
                    }
                    break;
                }
                case 2: {
                    [self openPasswordEditView];
                    break;
                }
                default:
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    break;
                case 1:
                    if (![PartnerApply linkComplete]) {
                        [self openPartnerApplyView];
                    } else {
                        [self openPartnerUnlinkAlert];
                    }
                    break;
                    
                default:
                    break;
            }
            break;
        case 3:
            _editedChildIndex = indexPath.row;
            [self showChildInfo:indexPath.row];
        default:
            break;
    }

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case 3:
            title = @"こども";
            break;
        default:
            title = @"";
            break;
    }
    return title;
}

- (void)showProfileEditView:(NSString *)type
{
    ProfileEditViewController *profileEditViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ProfileEditViewController"];
    profileEditViewController.delegate = self;
    profileEditViewController.profileType = type;
    
    if ([type isEqualToString:@"nickname"]) {
        CGRect tableViewRect = _nicknameCell.superview.superview.frame;
        profileEditViewController.profileCellRect = CGRectMake(tableViewRect.origin.x + _nicknameCell.frame.origin.x, tableViewRect.origin.y + self.navigationController.navigationBar.bounds.size.height + [[UIApplication sharedApplication]statusBarFrame].size.height + _nicknameCell.frame.origin.y, _nicknameCell.frame.size.width, _nicknameCell.frame.size.height);
    } else if ([type isEqualToString:@"email"]) {
        CGRect tableViewRect = _emailCell.superview.superview.frame;
        profileEditViewController.profileCellRect = CGRectMake(tableViewRect.origin.x + _emailCell.frame.origin.x, tableViewRect.origin.y + self.navigationController.navigationBar.bounds.size.height + [[UIApplication sharedApplication]statusBarFrame].size.height + _emailCell.frame.origin.y, _emailCell.frame.size.width, _emailCell.frame.size.height);
    } else {
        return;
    }
    [self addChildViewController:profileEditViewController];
    [self.view addSubview:profileEditViewController.view];
}

- (void)changeNickname:(NSString *)nickname
{
    _nicknameCell.detailTextLabel.text = nickname;
}

- (void)changeEmail:(NSString *)email
{
    _emailCell.textLabel.text = email;
    emailVerified = NO;
    [_profileTableView reloadData];
}

- (void)showChildInfo:(NSInteger)index
{
    ChildProfileViewController *childProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChildProfileViewController"];
    NSMutableDictionary *child = childProperties[index];
    childProfileViewController.childObjectId = child[@"objectId"];
    [self.navigationController pushViewController:childProfileViewController animated:YES];
}

- (void)openPartnerApplyView
{
    PartnerInviteViewController *partnerInviteViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PartnerInviteViewController"];
    [self.navigationController pushViewController:partnerInviteViewController animated:YES];
}

- (void)openPartnerUnlinkAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"パートナーとのひも付けを削除しますか？"
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"もどる"
                                          otherButtonTitles:@"解除する", nil
                          ];
    [alert show];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
        {
        }
            break;
        case 1:
        {

        }
        case 2:
        {
            [FamilyRole unlinkFamily:^(BOOL succeeded, NSError *error){
                if (error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ネットワークエラー"
                                                                    message:@"エラーが発生しました。\n再度お試しください"
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"OK", nil
                                          ];
                    [alert show];
                    return;
                }
                
                [self.navigationController popToRootViewControllerAnimated:YES];
            }];
        }
            break;
            
        default:
            break;
    }
}

- (void)openRegisterView
{
    UserRegisterViewController * userRegisterViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UserRegisterViewController"];
    [self.navigationController pushViewController:userRegisterViewController animated:YES];
}

- (void)openEmailVerifiedView
{
    NotEmailVerifiedViewController *emailVerifiedViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NotEmailVerifiedViewController"];
    [self.navigationController pushViewController:emailVerifiedViewController animated:YES];
}

- (void)openPasswordEditView
{
    PasswordChangeViewController *passwordChangeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PasswordChangeViewController"];
    [self.navigationController pushViewController:passwordChangeViewController animated:YES];
}

@end
