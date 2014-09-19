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

@interface IntroChildNameViewController ()

@end

@implementation IntroChildNameViewController {
    TutorialNavigator *tn;
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

    _childNameSendLabel.layer.cornerRadius = _childNameSendLabel.frame.size.width/2;
    _childNameSendLabel.layer.borderColor = [UIColor orangeColor].CGColor;
    _childNameSendLabel.layer.borderWidth = 2.0f;
    _childNameSendLabel.tag = 2;
    
    UITapGestureRecognizer *stgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    stgr.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:stgr];
    
    UITapGestureRecognizer *stgr2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    stgr2.numberOfTapsRequired = 1;
    [_childNameSendLabel addGestureRecognizer:stgr2];
    
    [Navigation setTitle:self.navigationItem withTitle:@"こどもを追加" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
}

- (void)viewDidLayoutSubviews
{
    _textFieldContainerScrollView.contentSize = CGSizeMake(_textFieldContainerView.frame.size.width, _textFieldContainerView.frame.size.height);
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
    _addableChildNum = 5 - [_childProperties count];
    
    // init
    _childNameField1.hidden = NO;
    _childNameField2.hidden = NO;
    _childNameField3.hidden = NO;
    _childNameField4.hidden = NO;
    _childNameField5.hidden = NO;
    _childLabel1.hidden = YES;
    _childLabel2.hidden = YES;
    _childLabel3.hidden = YES;
    _childLabel4.hidden = YES;
    _childLabel5.hidden = YES;
    _childButton1.hidden = YES;
    _childButton2.hidden = YES;
    _childButton3.hidden = YES;
    _childButton4.hidden = YES;
    _childButton5.hidden = YES;
    
    if (_addableChildNum < 5) {
        _childNameField5.hidden = YES;
        _childLabel5 = [[UILabel alloc] initWithFrame:_childNameField5.frame];
        _childLabel5.text = _childProperties[0][@"name"];
        [_textFieldContainerView addSubview:_childLabel5];
        
        if ([_childProperties count] > 1) {
            CGRect frame = _childNameField5.frame;
            frame.origin.x += (frame.size.width - frame.size.height*2);
            frame.size.width = frame.size.height * 2;
            _childButton5 =[[UIButton alloc] initWithFrame:frame];
            [_childButton5 setTitle:@"削除" forState:UIControlStateNormal];
            [_childButton5 setBackgroundColor:[ColorUtils getSunDayCalColor]];
            [_textFieldContainerView addSubview:_childButton5];
            _childButton5.tag = 0;
            [_childButton5 addTarget:self action:@selector(removeChild:) forControlEvents:UIControlEventTouchDown];
        }
    }
    if (_addableChildNum < 4) {
        _childNameField4.hidden = YES;
        _childLabel4 = [[UILabel alloc] initWithFrame:_childNameField4.frame];
        _childLabel4.text = _childProperties[1][@"name"];
        [_textFieldContainerView addSubview:_childLabel4];
        
        CGRect frame = _childNameField4.frame;
        frame.origin.x += (frame.size.width - frame.size.height*2);
        frame.size.width = frame.size.height * 2;
        _childButton4 =[[UIButton alloc] initWithFrame:frame];
        [_childButton4 setTitle:@"削除" forState:UIControlStateNormal];
        [_childButton4 setBackgroundColor:[ColorUtils getSunDayCalColor]];
        [_textFieldContainerView addSubview:_childButton4];
        _childButton4.tag = 1;
        [_childButton4 addTarget:self action:@selector(removeChild:) forControlEvents:UIControlEventTouchDown];
    }
    if (_addableChildNum < 3) {
        _childNameField3.hidden = YES;
        _childLabel3 = [[UILabel alloc] initWithFrame:_childNameField3.frame];
        _childLabel3.text = _childProperties[2][@"name"];
        [_textFieldContainerView addSubview:_childLabel3];
        
        CGRect frame = _childNameField3.frame;
        frame.origin.x += (frame.size.width - frame.size.height*2);
        frame.size.width = frame.size.height * 2;
        _childButton3 =[[UIButton alloc] initWithFrame:frame];
        [_childButton3 setTitle:@"削除" forState:UIControlStateNormal];
        [_childButton3 setBackgroundColor:[ColorUtils getSunDayCalColor]];
        [_textFieldContainerView addSubview:_childButton3];
        _childButton3.tag = 2;
        [_childButton3 addTarget:self action:@selector(removeChild:) forControlEvents:UIControlEventTouchDown];
    }
    if (_addableChildNum < 2) {
        _childNameField2.hidden = YES;
        _childLabel2 = [[UILabel alloc] initWithFrame:_childNameField2.frame];
        _childLabel2.text = _childProperties[3][@"name"];
        [_textFieldContainerView addSubview:_childLabel2];
        
        CGRect frame = _childNameField2.frame;
        frame.origin.x += (frame.size.width - frame.size.height*2);
        frame.size.width = frame.size.height * 2;
        _childButton2 =[[UIButton alloc] initWithFrame:frame];
        [_childButton2 setTitle:@"削除" forState:UIControlStateNormal];
        [_childButton2 setBackgroundColor:[ColorUtils getSunDayCalColor]];
        [_textFieldContainerView addSubview:_childButton2];
        _childButton2.tag = 3;
        [_childButton2 addTarget:self action:@selector(removeChild:) forControlEvents:UIControlEventTouchDown];
    }
    if (_addableChildNum < 1) {
        // この場合はもう追加できないよってメッセージにするべき
        _childNameField1.hidden = YES;
        _childLabel1 = [[UILabel alloc] initWithFrame:_childNameField1.frame];
        _childLabel1.text = _childProperties[4][@"name"];
        [_textFieldContainerView addSubview:_childLabel1];
        
        CGRect frame = _childNameField1.frame;
        frame.origin.x += (frame.size.width - frame.size.height*2);
        frame.size.width = frame.size.height * 2;
        _childButton1 =[[UIButton alloc] initWithFrame:frame];
        [_childButton1 setTitle:@"削除" forState:UIControlStateNormal];
        [_childButton1 setBackgroundColor:[ColorUtils getSunDayCalColor]];
        [_textFieldContainerView addSubview:_childButton1];
        _childButton1.tag = 4;
        [_childButton1 addTarget:self action:@selector(removeChild:) forControlEvents:UIControlEventTouchDown];
    }
    
    // Start observing
    if (!_keyboradObserving) {
        NSNotificationCenter *center;
        center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [center addObserver:self selector:@selector(keybaordWillHide:) name:UIKeyboardWillHideNotification object:nil];
        _keyboradObserving = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if ([Tutorial underTutorial]) {
        tn = [[TutorialNavigator alloc]init];
        tn.targetViewController = self;
        [tn showNavigationView];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    if ([Tutorial underTutorial]) {
        [tn removeNavigationView];
        tn = nil;
    }
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

- (void)keyboardWillShow:(NSNotification*)notification
{
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    // Calc overlap of keyboardFrame and textViewFrame
    CGRect keyboardFrame;
    CGRect textViewFrame;
    keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [_editingView.superview convertRect:keyboardFrame fromView:nil];
    textViewFrame = _editingView.frame;
    float overlap;
    overlap = MAX(0.0f, CGRectGetMaxY(textViewFrame) - CGRectGetMinY(keyboardFrame));
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
        CGRect viewFrame = _editingView.frame;
        viewFrame.origin.y -= overlap;
        _editingView.frame = viewFrame;
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

- (void)keybaordWillHide:(NSNotification*)notification
{
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    CGRect textViewFrame;
    textViewFrame = _editingView.frame;
    //float overlap;
    //overlap = MAX(0.0f, CGRectGetMaxY(_defaultCommentViewRect) - CGRectGetMaxY(textViewFrame));
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
        CGRect viewFrame = _editingView.frame;
        viewFrame.origin.y = (self.view.frame.size.height - _editingView.frame.size.height);
        _editingView.frame = viewFrame;
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

-(void)handleSingleTap:(id) sender
{
    if ([sender view].tag == 2) {
        NSMutableArray *newChildNameArray = [[NSMutableArray alloc] init];
        // 地道に入れよう。。。
        if (_childNameField1.text && ![_childNameField1.text isEqualToString:@""]) {
            [newChildNameArray addObject:_childNameField1.text];
        }
        if (_childNameField2.text && ![_childNameField2.text isEqualToString:@""]) {
            [newChildNameArray addObject:_childNameField2.text];
        }
        if (_childNameField3.text && ![_childNameField3.text isEqualToString:@""]) {
            [newChildNameArray addObject:_childNameField3.text];
        }
        if (_childNameField4.text && ![_childNameField4.text isEqualToString:@""]) {
            [newChildNameArray addObject:_childNameField4.text];
        }
        if (_childNameField5.text && ![_childNameField5.text isEqualToString:@""]) {
            [newChildNameArray addObject:_childNameField5.text];
        }
        if ([newChildNameArray count] < 1) {
        } else {
            
            // 移行の処理がforegrandなのでこれ表示されない。。。
            _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            _hud.labelText = @"データ更新";
            
            // 念のためrefresh
            PFObject *user = [PFUser currentUser];
            [user refresh];
            for (NSString *childName in newChildNameArray) {
                PFObject *child = [PFObject objectWithClassName:@"Child"];
                [child setObject:user forKey:@"createdBy"];
                child[@"name"] = childName;
                child[@"familyId"] = user[@"familyId"];
                child[@"childImageShardIndex"] = [NSNumber numberWithInteger: [Sharding shardIndexWithClassName:@"ChildImage"]];
                child[@"commentShardIndex"] = [NSNumber numberWithInteger: [Sharding shardIndexWithClassName:@"Comment"]];
                [child save];
                
                // _childPropertiesを更新
                // TODO childPropertiesはPFObjectじゃなくてdictionaryを保持するようになってる。。。仕様そろえる必要あり
                NSMutableDictionary *childProperty = [[NSMutableDictionary alloc]init];
                childProperty[@"objectId"] = child.objectId;
                childProperty[@"name"] = child[@"name"];
                childProperty[@"childImageShardIndex"] = child[@"childImageShardIndex"];
                childProperty[@"commentShardIndex"] = child[@"commentShardIndex"];
                childProperty[@"createdAt"] = child.createdAt;
                [_childProperties addObject:childProperty];
            }
            
            // もしtutorial中だった場合はデフォルトのこどもの情報を消す
            if ([Tutorial underTutorial]) {
                [ImageCache removeAllCache];
                [Tutorial updateStage];
                // ViewControllerのchildPropertiesからデフォルトのこどもを削除
                NSString *tutorialChildObjectId = [Tutorial getTutorialAttributes:@"tutorialChildObjectId"];
                NSPredicate *p = [NSPredicate predicateWithFormat:@"objectId = %@", tutorialChildObjectId];
                NSArray *tutorialChildObjects = [_childProperties filteredArrayUsingPredicate:p];
                if (tutorialChildObjects.count > 0) {
                    [_childProperties removeObject:tutorialChildObjects[0]];
                }
            }
            
            // _pageViewControllerを再読み込み
            NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:n];
            
            [_hud hide:YES];
            
            if ([self.navigationController isViewLoaded]) {
                [self.navigationController popToRootViewControllerAnimated:YES];
            } else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
    } else {
        [self.view endEditing:YES];
    }
}

- (void)removeChild:(UIButton *)sender
{
    _removeTarget = sender.tag;
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
                    }
                }];
            }];
        }
            break;
    }
}

@end
