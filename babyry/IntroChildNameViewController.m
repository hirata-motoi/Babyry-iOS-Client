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
#import "TutorialNavigator.h"
#import "ImageCache.h"
#import "ChildListCell.h"
#import "ParseUtils.h"
#import "DateUtils.h"

@interface IntroChildNameViewController ()

@end

@implementation IntroChildNameViewController {
    TutorialNavigator *tn;
    BOOL selectedBirthday;
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
    
    [Navigation setTitle:self.navigationItem withTitle:@"こどもを追加" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
    
    UITapGestureRecognizer *stgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    stgr.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:stgr];
    
    UITapGestureRecognizer *addChildGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addChild)];
    addChildGesture.numberOfTapsRequired = 1;
    [_childAddButton addGestureRecognizer:addChildGesture];
    _childAddButton.layer.cornerRadius = 2.0f;
    
    UITapGestureRecognizer *stgr3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openDatePicker)];
    stgr3.numberOfTapsRequired = 1;
    [_birthdayLabel addGestureRecognizer:stgr3];
    
    [self refreshChildList];
    
    // set date
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy/MM/dd";
    [self resetBirthday];
    selectedBirthday = NO;
    
    _datePickerContainer.hidden = YES;
    
    _datePicker.maximumDate = [NSDate date];
    [_datePicker addTarget:self action:@selector(action:forEvent:) forControlEvents:UIControlEventValueChanged];
    
    // sex
    [self resetSex];
   
    // set frame
    _requireChildName.layer.borderColor = [UIColor redColor].CGColor;
    _requireChildName.layer.borderWidth = 0.6f;
    _optionalBirthday.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _optionalBirthday.layer.borderWidth = 0.6f;
    _optionalSex.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _optionalSex.layer.borderWidth = 0.6f;
    
    // reset
    [_resetBirthdayButton addTarget:self action:@selector(resetBirthday) forControlEvents:UIControlEventTouchUpInside];
    [_resetSexButton addTarget:self action:@selector(resetSex) forControlEvents:UIControlEventTouchUpInside];
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
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    _datePickerContainer.hidden = YES;
    
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"こどもの名前を入力してください"
                                                        message:@""
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
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
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.labelText = @"データ更新中";
    [self.view endEditing:YES];
    // 念のためrefresh
    PFObject *user = [PFUser currentUser];
    [user refreshInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ネットワークエラー"
                                                            message:@"エラーが発生しました。もう一度お試しください。"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
            [_hud hide:YES];
            return;
        }
        if (object) {
            PFObject *child = [PFObject objectWithClassName:@"Child"];
            [child setObject:object forKey:@"createdBy"];
            child[@"name"] = _childNameField.text;
            child[@"familyId"] = object[@"familyId"];
            
            if (_childSexSegment.selectedSegmentIndex == 0) {
                child[@"sex"] = @"male";
            } else if (_childSexSegment.selectedSegmentIndex == 1) {
                child[@"sex"] = @"female";
            }
           
            if (selectedBirthday) {
                child[@"birthday"] = [DateUtils setSystemTimezoneAndZero:_datePicker.date];
            }
            
            child[@"childImageShardIndex"] = [NSNumber numberWithInteger: [Sharding shardIndexWithClassName:@"ChildImage"]];
            child[@"commentShardIndex"] = [NSNumber numberWithInteger: [Sharding shardIndexWithClassName:@"Comment"]];
            [child save];

            [_childProperties addObject:[ParseUtils pfObjectToDic:child]];
            
            // もしtutorial中だった場合はデフォルトのこどもの情報を消す
            if ([Tutorial underTutorial] && _isBabyryExist) {
                [ImageCache removeAllCache];
                [Tutorial forwardStageWithNextStage:@"uploadByUser"];
                // ViewControllerのchildPropertiesからデフォルトのこどもを削除
                NSString *tutorialChildObjectId = [Tutorial getTutorialAttributes:@"tutorialChildObjectId"];
                NSPredicate *p = [NSPredicate predicateWithFormat:@"objectId = %@", tutorialChildObjectId];
                NSArray *tutorialChildObjects = [_childProperties filteredArrayUsingPredicate:p];
                if (tutorialChildObjects.count > 0) {
                    [_childProperties removeObject:tutorialChildObjects[0]];
                }
            }
            [self refreshChildList];
            
            // reset forms
            _childNameField.text = @"";
            [self resetBirthday];
            [self resetSex];
            
            // _pageViewControllerを再読み込み
            NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:n];
            
            [_hud hide:YES];
           
            // tutorial中でBabyryちゃんに対して操作している場合こども追加が完了したらPageContentViewControllerに戻る
            if ([[Tutorial currentStage].currentStage isEqualToString:@"uploadByUser"]) {
                [self.navigationController popToViewController: [self.navigationController.viewControllers objectAtIndex:0] animated:YES];
            }
        }
    }];
}

- (void)refreshChildList
{
    for (UIView *view in _childListContainer.subviews) {
        [view removeFromSuperview];
    }
    
    // BabyryちゃんのobjectIdを取得
    //NSString *babyryId = @"aI1Lo7FXhH";
    NSString *babyryId = @"0HJFGtSrzN";
    
    _isBabyryExist = NO;
    
    float lastY = 0;
    int childIndex = 0;
    for (NSMutableDictionary *childDic in _childProperties) {
        if (![childDic[@"objectId"] isEqualToString:babyryId]) {
            ChildListCell *childListView = [ChildListCell view];
            
            childListView.childDeleteLabel.tag = childIndex;
            childIndex++;
            UITapGestureRecognizer *stgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeChild:)];
            stgr.numberOfTapsRequired = 1;
            [childListView.childDeleteLabel addGestureRecognizer:stgr];
            childListView.childObjectId = childDic[@"objectId"];
            childListView.childName.text = childDic[@"name"];
            
            if (childDic[@"birthday"] && ![childDic[@"birthday"] isEqualToDate:[NSDate distantFuture]]) {
                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                df.dateFormat = @"yyyy/MM/dd";
                childListView.childBirthday.text = [df stringFromDate:childDic[@"birthday"]];
            } else {
                childListView.childBirthday.text = @"";
            }
            
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
    _datePickerContainer.hidden = YES;
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
//    NSString *babyryId = @"aI1Lo7FXhH";
    NSString *babyryId = @"0HJFGtSrzN";

    int count = 0;
    for (NSMutableDictionary *childDic in _childProperties) {
        if (![childDic[@"objectId"] isEqualToString:babyryId]) {
            count++;
        }
    }
    return count;
}

- (void)openDatePicker
{
    [self.view endEditing:YES];
    _datePickerContainer.hidden = NO;
}

- (void)action:(id)sender forEvent:(UIEvent *)event
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy/MM/dd";
    _birthdayLabel.text = [df stringFromDate:_datePicker.date];
    selectedBirthday = YES;
}

- (void)resetBirthday
{
    _birthdayLabel.text = @"----/--/--";
    _datePicker.date = [DateUtils setSystemTimezone:[NSDate date]];
    selectedBirthday = NO;
}

- (void)resetSex
{
    _childSexSegment.selectedSegmentIndex = UISegmentedControlNoSegment;
}

@end
