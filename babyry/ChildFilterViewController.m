//
//  ChildFilterViewController.m
//  babyry
//
//  Created by hirata.motoi on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ChildFilterViewController.h"
#import "ChildFilterListCell.h"

@interface ChildFilterViewController ()

@end

@implementation ChildFilterViewController
@synthesize delegate = _delegate;

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
    
    _childListTable.delegate = self;
    _childListTable.dataSource = self;
    
    UINib *nib = [UINib nibWithNibName:@"ChildFilterListCell" bundle:nil];
    [_childListTable registerNib:nib forCellReuseIdentifier:@"Cell"];
    
    self.backgroundView.layer.cornerRadius = 5.0f;
    self.childListTable.layer.cornerRadius = 5.0f;
    
    [self setupButtons];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)submit
{
    NSMutableDictionary *childFamilyMap = [[NSMutableDictionary alloc]init];
    for (NSMutableDictionary *section in _childList) {
        for (NSMutableDictionary *child in section[@"childList"]) {
            // selectedのこどもは自分のfamilyIdを、selectedでないこどもは空にする
            childFamilyMap[child[@"childObjectId"]]
                = ([child[@"selected"] isEqualToNumber:[NSNumber numberWithBool:YES]]) ? [PFUser currentUser][@"familyId"] : @"";
        }
    }
    
    [_delegate executeAdmit:_indexNumber withChildFamilyMap:childFamilyMap];
}

- (void)refreshChildListTable:(NSMutableArray *)childList
{
    _childList = childList;
    [_childListTable reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_childList[section][@"childList"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    // 再利用できるセルがあれば再利用する
    ChildFilterListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        // 再利用できない場合は新規で作成
        cell = [[ChildFilterListCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
    }
    cell.delegate = self;
    cell.indexPath = indexPath;
    cell.childNameLabel.text = _childList[indexPath.section][@"childList"][indexPath.row][@"name"];
    cell.childNameLabel.font = [UIFont systemFontOfSize:18];
    cell.childNameLabel.numberOfLines = 0;
    CGSize bounds = CGSizeMake(cell.childNameLabel.frame.size.width, tableView.frame.size.height);
    CGSize sizeEmailLabel = [cell.childNameLabel.text
                   boundingRectWithSize:bounds
                   options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                   attributes:[NSDictionary dictionaryWithObject:cell.childNameLabel.font forKey:NSFontAttributeName]
                   context:nil].size;
    
    CGRect rect = cell.childNameLabel.frame;
    rect.size.height = sizeEmailLabel.height;
    cell.childNameLabel.frame = rect;
    
    // デフォルトでチェックマークつける
    cell.selectSwitch.on = YES;
    return cell;
};

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _childList.count;
}

// セルの高さをtextの高さに合わせる
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChildFilterListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.childNameLabel.text = _childList[indexPath.section][@"childList"][indexPath.row][@"name"];
    cell.childNameLabel.font = [UIFont systemFontOfSize:18];
    
    // get cell height
    cell.childNameLabel.numberOfLines = 0;
    CGSize bounds = CGSizeMake(cell.childNameLabel.frame.size.width, tableView.frame.size.height);
    CGSize sizeEmailLabel = [cell.childNameLabel.text
                              boundingRectWithSize:bounds
                              options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                              attributes:[NSDictionary dictionaryWithObject:cell.childNameLabel.font forKey:NSFontAttributeName]
                              context:nil].size;
    
    return sizeEmailLabel.height + 30; // 余白30
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _childList[section][@"nameOfCreatedBy"];
}

- (BOOL)switchSelected:(BOOL)selected withIndexPath:(NSIndexPath *)indexPath
{
    _childList[indexPath.section][@"childList"][indexPath.row][@"selected"] = [NSNumber numberWithBool:selected];
    
    if ([self hasNoChild]) {
        _childList[indexPath.section][@"childList"][indexPath.row][@"selected"] = [NSNumber numberWithBool:!selected];
        [self showNoChildAlert];
        return NO;
    }
    
    return YES;
}

- (BOOL)hasNoChild
{
    for (NSMutableDictionary *section in _childList) {
        for (NSMutableDictionary *child in section[@"childList"]) {
            if ([child[@"selected"] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
                return NO;
            }
        }
    }
    return YES;
}

- (void)setupButtons
{
    [self setupCloseButton];
    [self setupSubmitButton];
}

- (void)setupCloseButton
{
    UITapGestureRecognizer *closeGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(close)];
    closeGesture.numberOfTapsRequired = 1;
    _closeButton.userInteractionEnabled = YES;
    [_closeButton addGestureRecognizer:closeGesture];
}

- (void)close
{
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (void)setupSubmitButton
{
    UITapGestureRecognizer *submitGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(submit)];
    submitGesture.numberOfTapsRequired = 1;
    [_submitButton addGestureRecognizer:submitGesture];
    _submitButton.layer.cornerRadius = 2.0f;
}

- (void)showNoChildAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"こどもを0人にすることはできません"
                                                    message:@""
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    [alert show];
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
