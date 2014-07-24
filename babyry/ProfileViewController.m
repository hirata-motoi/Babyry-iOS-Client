//
//  ProfileViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ProfileViewController.h"
#import "NicknameEditViewController.h"
#import "SettingViewController.h"

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
    
    _profileTableView.delegate = self;
    _profileTableView.dataSource = self;
    [self.closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    // ほんとはprotocolを使うべきだがSettingViewControllerの仕様に合わせる
    // _returnValueOfChildNameがnullでない場合 == childのnameを変更した場合
    if (_returnValueOfChildName) {
        [_childList objectAtIndex:_editedChildIndex][@"name"] = _returnValueOfChildName;
        [_profileTableView reloadData];
        _returnValueOfChildName = NULL;
    }

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows;
    switch (section) {
        case 0:
            numberOfRows = 1;
            break;
        case 1:
            numberOfRows = 1;
            break;
        case 2:
            numberOfRows = [_childList count];
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
                    cell.textLabel.text = @"ニックネーム";
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
                    cell.textLabel.text = @"パートナー";
                    cell.detailTextLabel.text = _partnerInfo[@"nickName"];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
                }
                default:
                    break;
            }
            break;
        case 2: {
            // indexPath.rowに従って子供の情報をセットする
            PFObject *child = [_childList objectAtIndex:indexPath.row];
            cell.textLabel.text = child[@"name"];
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
            title = @"子供";
            break;
        default:
            title = @"";
            break;
    }
    return title;
}

- (void)close
{
    CGRect rect = self.view.frame;
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.view.frame = CGRectMake(rect.size.width, rect.origin.y, rect.size.width, rect.size.height);
                     }
                     completion:^(BOOL finished){
                         [self.view removeFromSuperview];
                         [self dismissViewControllerAnimated:YES completion:nil];
                     }];
}

- (void)showNicknameEditView
{
    NicknameEditViewController *nicknameEditViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NicknameEditViewController"];
    nicknameEditViewController.delegate = self;
    CGRect tableViewRect = _nicknameCell.superview.superview.frame;
    
    nicknameEditViewController.nicknameCellRect = CGRectMake(tableViewRect.origin.x + _nicknameCell.frame.origin.x, tableViewRect.origin.y + _nicknameCell.frame.origin.y, _nicknameCell.frame.size.width, _nicknameCell.frame.size.height);
    [self addChildViewController:nicknameEditViewController];
    [self.view addSubview:nicknameEditViewController.view];
}

- (void)changeNickname:(NSString *)nickname
{
    _nicknameCell.detailTextLabel.text = nickname;
}

- (void)showChildInfo:(NSInteger)index
{
    SettingViewController *settingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingViewController"];
    PFObject *child = [_childList objectAtIndex:index];
    settingViewController.childObjectId = child.objectId;
    
    settingViewController.childName = child[@"name"];
    settingViewController.childBirthday = child[@"birthday"];
    settingViewController.pViewController = self;
    [self presentViewController:settingViewController animated:YES completion:NULL];
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