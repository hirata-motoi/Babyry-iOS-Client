//
//  ChildProfileViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ChildProfileViewController.h"
#import "Navigation.h"
#import "ChildProfileEditViewController.h"
#import "ChildProperties.h"
#import "ChildIconCollectionViewController.h"
#import "ColorUtils.h"

@interface ChildProfileViewController ()

@end

@implementation ChildProfileViewController {
    NSMutableDictionary *childProperty;
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
    childProperty = [ChildProperties getChildProperty:_childObjectId];
    
    _childProfileTableView.delegate = self;
    _childProfileTableView.dataSource = self;
    [Navigation setTitle:self.navigationItem withTitle:@"プロフィール編集" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
            numberOfRows = 1; // test
        default:
            break;
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChildProfileCellValue"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ChildProfileCellValue"];
    }
    cell.textLabel.numberOfLines = 0;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = @"名前";
                    cell.detailTextLabel.text = childProperty[@"name"];
                    
                    _childNicknameCell = cell;
                    break;
                }
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = @"誕生日";
                    NSDateFormatter *df = [[NSDateFormatter alloc] init];
                    df.dateFormat = @"yyyy/MM/dd";
                    if ([childProperty[@"birthday"] isEqualToDate:[NSDate distantFuture]]) {
                        cell.detailTextLabel.text = @"";
                    } else {
                        cell.detailTextLabel.text = [df stringFromDate:childProperty[@"birthday"]];
                    }
                    _childBirthdayCell = cell;
                    break;
                }
                default:
                    break;
            }
            break;
        case 2: // test
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = @"アイコン";
                    break;
                }
                default:
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
                    [self showChildProfileEditView:@"name"];
                    break;
                }
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:{
                    [self showChildProfileEditView:@"birthday"];
                    break;
                }
                default:
                    break;
            }
            break;
        case 2: // test
            switch (indexPath.row) {
                case 0: {
                    ChildIconCollectionViewController *childIconCollectionViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChildIconCollectionViewController"];
                    childIconCollectionViewController.childObjectId = _childObjectId;
                    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:childIconCollectionViewController];
                    [self.navigationController presentViewController:navController animated:YES completion:nil];
                    break;
                }
                default:
                    break;
            }
        default:
            break;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//    return 2;
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        default:
            title = @"";
            break;
    }
    return title;
}

- (void)showChildProfileEditView:(NSString *)editName
{
    ChildProfileEditViewController *childProfileEditViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChildProfileEditViewController"];
    childProfileEditViewController.delegate = self;
    childProfileEditViewController.childObjectId = _childObjectId;
    CGRect tableViewRect;
    if ([editName isEqualToString:@"name"]) {
        tableViewRect = _childNicknameCell.superview.superview.frame;
        childProfileEditViewController.childNicknameCellRect = CGRectMake(tableViewRect.origin.x + _childNicknameCell.frame.origin.x, tableViewRect.origin.y + self.navigationController.navigationBar.bounds.size.height + [[UIApplication sharedApplication]statusBarFrame].size.height + _childNicknameCell.frame.origin.y, _childNicknameCell.frame.size.width, _childNicknameCell.frame.size.height);
    } else if ([editName isEqualToString:@"birthday"]) {
        tableViewRect = _childBirthdayCell.superview.superview.frame;
        childProfileEditViewController.childBirthdayCellPoint = CGPointMake(tableViewRect.origin.x + _childBirthdayCell.frame.origin.x, tableViewRect.origin.y + self.navigationController.navigationBar.bounds.size.height + [[UIApplication sharedApplication]statusBarFrame].size.height + _childBirthdayCell.frame.origin.y);
    }
    childProfileEditViewController.editTarget = editName;

    [self addChildViewController:childProfileEditViewController];
    [self.view addSubview:childProfileEditViewController.view];
}

- (void)reloadChildProfile
{
    childProperty = [ChildProperties getChildProperty:_childObjectId];
    [_childProfileTableView reloadData];
}

- (void)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
