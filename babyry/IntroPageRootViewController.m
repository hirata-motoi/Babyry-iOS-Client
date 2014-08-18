//
//  IntroPageRootViewController.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "IntroPageRootViewController.h"
#import "UIColor+Hex.h"

@interface IntroPageRootViewController ()

@end

@implementation IntroPageRootViewController
@synthesize delegate;

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
    
    self.view.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.6];
   
    UITapGestureRecognizer *openLoginView = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openLoginView)];
    openLoginView.numberOfTapsRequired = 1;
    if (_startButton) {
        [_startButton addGestureRecognizer:openLoginView];
    }
    [self setupSkipAction];
}

- (void)setupSkipAction
{
    UILabel *target;
    if (_skipFromFirst) {
        target = _skipFromFirst;
    } else if (_skipFromSecond) {
        target = _skipFromSecond;
    } else if (_skipFromThird) {
        target = _skipFromThird;
    } else {
        target = _skipFromFourth;
    }
    [self setupSkipGesture:target];
}

- (void)setupSkipGesture:(UILabel *)label
{
    UITapGestureRecognizer *skipGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(skip)];
    skipGesture.numberOfTapsRequired = 1;
    label.userInteractionEnabled = YES;
    [label addGestureRecognizer:skipGesture];
}

- (void)skip
{
    [self.delegate skipToLast:_currentIndex];
}

- (void)openLoginView
{
    [self.delegate openLoginView];
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

@end
