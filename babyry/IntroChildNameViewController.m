//
//  IntroChildNameViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "IntroChildNameViewController.h"
#import "Navigation.h"
#import "Sharding.h"
#import "ColorUtils.h"
#import "Logger.h"
#import "Tutorial.h"
#import "ImageCache.h"
#import "ChildListCell.h"
#import "ParseUtils.h"

@interface IntroChildNameViewController ()

@end

@implementation IntroChildNameViewController

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
    
    [Navigation setTitle:self.navigationItem withTitle:@"こどもを追加" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
    
    UITapGestureRecognizer *stgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    stgr.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:stgr];
    
    UITapGestureRecognizer *addChildGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addChild)];
    addChildGesture.numberOfTapsRequired = 1;
    [_childAddButton addGestureRecognizer:addChildGesture];
    
    [self refreshChildList];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    // super
    [super viewWillAppear:animated];
    
    
    // Maxが5なので、追加できる子供は 5 - _currentChildNum;
    //_addableChildNum = 5 - [_childProperties count];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

- (void)keybaordWillHide:(NSNotification*)notification
{
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

-(void)addChild
{
    if (!_childNameField.text || [_childNameField.text isEqualToString:@""]) {
        return;
    }
    
    if ([_childProperties count] >= 5) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"上限に達しています"
                                                        message:@"こどもを作成できる上限は5人です。"
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
        return;
    }
    
    NSString *childSex = [[NSString alloc] init];
    if (_childSexSegment.selectedSegmentIndex == 0) {
        childSex = @"male";
    } else {
        childSex = @"female";
    }
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.labelText = @"データ更新中";
    [self.view endEditing:YES];
    // 念のためrefresh
    PFObject *user = [PFUser currentUser];
    [user refreshInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (error) {
            // アラート？
            [_hud hide:YES];
            return;
        }
        if (object) {
            PFObject *child = [PFObject objectWithClassName:@"Child"];
            [child setObject:object forKey:@"createdBy"];
            child[@"name"] = _childNameField.text;
            child[@"familyId"] = object[@"familyId"];
            child[@"sex"] = childSex;
            child[@"childImageShardIndex"] = [NSNumber numberWithInteger: [Sharding shardIndexWithClassName:@"ChildImage"]];
            child[@"commentShardIndex"] = [NSNumber numberWithInteger: [Sharding shardIndexWithClassName:@"Comment"]];
            [child save];
            
            [_childProperties addObject:[ParseUtils pfObjectToDic:child]];
            
            // もしtutorial中だった場合はデフォルトのこどもの情報を消す
            if ([Tutorial underTutorial] && _isBabyryExist) {
                [ImageCache removeAllCache];
                [Tutorial updateStage];
                // ViewControllerのchildPropertiesからデフォルトのこどもを削除 indexではなくちゃんとobject指定して消した方がいい
                [_childProperties removeObjectAtIndex:0];
            }
            [self refreshChildList];
            _childNameField.text = @"";
            
            [_hud hide:YES];
        }
    }];
}

- (void)refreshChildList
{
    for (UIView *view in _childListContainer.subviews) {
        [view removeFromSuperview];
    }
    
    // BabyryちゃんのobjectIdを取得
    NSString *babyryId = @"aI1Lo7FXhH";
    _isBabyryExist = NO;
    
    float lastY = 0;
    int childIndex = 0;
    for (NSDictionary *childDic in _childProperties) {
        if (![childDic[@"objectId"] isEqualToString:babyryId]) {
            ChildListCell *childListView = [ChildListCell view];
            
            childListView.childDeleteLabel.tag = childIndex;
            childIndex++;
            UITapGestureRecognizer *stgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeChild:)];
            stgr.numberOfTapsRequired = 1;
            [childListView.childDeleteLabel addGestureRecognizer:stgr];
            childListView.childObjectId = childDic[@"objectId"];
            
            childListView.childName.text = childDic[@"name"];
            CGRect frame = childListView.frame;
            frame.origin.y = lastY;
            childListView.frame = frame;
            lastY += childListView.frame.size.height;
            [_childListContainer addSubview:childListView];
        } else {
            _isBabyryExist = YES;
        }
    }
}

-(void)handleSingleTap:(id) sender
{
    [self.view endEditing:YES];
}

- (void)removeChild:(UIGestureRecognizer *) sender
{
    if ([self countChildProperty] == 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"こどもが0人になります"
                                                        message:@"こどもは最低一人は登録しておく必要があります。"
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
        return;
    }
    
    _removeTarget = [sender view].tag;
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
            _removeTarget = -1;
        }
            break;
        case 1:
        {
            _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            _hud.labelText = @"削除中";
            PFQuery *childQuery = [PFQuery queryWithClassName:@"Child"];
            [childQuery whereKey:@"objectId" equalTo:[[_childProperties objectAtIndex:_removeTarget] objectForKey:@"objectId"]];
            [childQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
                if (error) {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in find child in alertView %@", error]];
                    return;
                }
                
                [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error) {
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in child delete in alertView %@", error]];
                        return;
                    }
                    
                    if (succeeded) {
                        [_childProperties removeObjectAtIndex:_removeTarget];
                        [_hud hide:YES];
                        [self viewWillAppear:YES];
                        _removeTarget = -1;
                        [self refreshChildList];
                    }
                }];
            }];
        }
            break;
    }
}

- (int) countChildProperty
{
    NSString *babyryId = @"aI1Lo7FXhH";

    int count = 0;
    for (NSDictionary *childDic in _childProperties) {
        if (![childDic[@"objectId"] isEqualToString:babyryId]) {
            count++;
        }
    }
    return count;
}

@end
