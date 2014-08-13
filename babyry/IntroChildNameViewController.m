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
    
    NSLog(@"Number of Current Child is %d", _currentChildNum);
    // Maxが5なので、追加できる子供は 5 - _currentChildNum;
    _addableChildNum = 5 - _currentChildNum;
    
    if (_addableChildNum < 5) {
        _childNameField5.hidden = YES;
    }
    if (_addableChildNum < 4) {
        _childNameField4.hidden = YES;
    }
    if (_addableChildNum < 3) {
        _childNameField3.hidden = YES;
    }
    if (_addableChildNum < 2) {
        _childNameField2.hidden = YES;
    }
    if (_addableChildNum < 1) {
        // この場合はもう追加できないよってメッセージにするべき
        _childNameField1.hidden = YES;
    }
    
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
    
    // Start observing
    if (!_keyboradObserving) {
        NSNotificationCenter *center;
        center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [center addObserver:self selector:@selector(keybaordWillHide:) name:UIKeyboardWillHideNotification object:nil];
        _keyboradObserving = YES;
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
    //NSLog(@"keyboardWillShow");
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
    //NSLog(@"overlap %f", overlap);
    
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
    //NSLog(@"keyboardWillHide");
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    CGRect textViewFrame;
    textViewFrame = _editingView.frame;
    //float overlap;
    //overlap = MAX(0.0f, CGRectGetMaxY(_defaultCommentViewRect) - CGRectGetMaxY(textViewFrame));
    //NSLog(@"overlap %f", overlap);
    
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
            NSLog(@"send childname");
        }
        NSLog(@"new child %@", newChildNameArray);
        if ([newChildNameArray count] < 1) {
            NSLog(@"no child names");
        } else {
            NSLog(@"update child names");
            
            // 念のためrefresh
            PFObject *user = [PFUser currentUser];
            [user refresh];
            for (NSString *childName in newChildNameArray) {
                PFObject *child = [PFObject objectWithClassName:@"Child"];
                [child setObject:user forKey:@"createdBy"];
                child[@"name"] = childName;
                child[@"familyId"] = user[@"familyId"];
                child[@"childImageShardIndex"] = [NSNumber numberWithInteger: [Sharding shardIndexWithClassName:@"ChildImage"]];
                [child save];
            }
            
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

@end
