//
//  ChildSwitchControlView.m
//  babyry
//
//  Created by hirata.motoi on 2014/12/27.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ChildSwitchControlView.h"
#import "ChildSwitchView.h"
#import "ChildProperties.h"
#import "DateUtils.h"
#import "Tutorial.h"
#import "Config.h"

@implementation ChildSwitchControlView {
    NSMutableArray *childSwitchViewList;
}

static ChildSwitchControlView* sharedObject = nil;

+ (ChildSwitchControlView*)sharedManager {
    @synchronized(self) {
        if (sharedObject == nil) {
            sharedObject = [[self alloc] init];
        }
    }
    return sharedObject;
}

- (id)init
{
    self = [super init];
    if (self) {
        //Initialization
        self.autoresizesSubviews = NO;
        [self setupChildSwitchViews];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetChildSwitchControlView) name:@"childPropertiesChanged" object:nil];
    }
  
    return self;
}

- (void)setupChildSwitchViews
{
    if (!childSwitchViewList) {
        childSwitchViewList = [[NSMutableArray alloc]init];
    }
    for (ChildSwitchView *view in [self subviews]) {
        [view removeFromSuperview];
    }
    [childSwitchViewList removeAllObjects];
    
    NSMutableArray *childProperties = [ChildProperties getChildProperties];
    if (childProperties.count < 1) {
        return;
    }
    
    for (NSMutableDictionary *childProperty in childProperties) {
        ChildSwitchView *childSwitchView = [ChildSwitchView view];
        childSwitchView.delegate = self;
        [childSwitchView setParams:childProperty[@"name"] forKey:@"childName"];
        [childSwitchView setParams:childProperty[@"objectId"] forKey:@"childObjectId"];
        childSwitchView.childNameLabel.alpha = 0.0f;
        [childSwitchViewList addObject:childSwitchView];
        [childSwitchView setup];
    }
  
    // サイズ・位置の調整
    float width = [[Config config][@"ChildSwitchControlViewWidth"] floatValue];
    float height = [[Config config][@"ChildSwitchControlViewHeight"] floatValue];
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    self.frame = CGRectMake(screenRect.size.width - width, [[Config config][@"ChildSwitchControlViewMarginTop"] floatValue], width, height);
    
    // 自身にaddSubview
    for (ChildSwitchView *view in childSwitchViewList) {
        [self addSubview:view];
    }
}

- (void)switchToInitialChild
{
    NSMutableArray *childProperties = [ChildProperties getChildProperties];
    if (childProperties.count < 1) {
        return;
    }

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastDisplayedAt" ascending:NO];
    NSArray *sortedArray = [childProperties sortedArrayUsingDescriptors:@[sortDescriptor]];
    [self switchChildSwitchView:sortedArray[0][@"objectId"]];
}

- (void)switchChildSwitchView: (NSString *)childObjectId
{
    // 指定されたchildのviewを最前面に持ってくる
    // activeを入れ替えする
    for (ChildSwitchView *view in childSwitchViewList) {
        if ([view.childObjectId isEqualToString:childObjectId]) {
            [self bringSubviewToFront:view];
            [view switch:YES];
        } else {
            [view switch:NO];
        }
    }
    
    // delegateメソッドを叩いて表示切り替え
    [_delegate reloadPageContentViewController:childObjectId];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[DateUtils setSystemTimezone:[NSDate date]], @"lastDisplayedAt", nil];
    [ChildProperties updateChildPropertyWithObjectId:childObjectId withParams:params];
}

- (void)openChildSwitchViews
{
    [_delegate showOverlay];
    CGRect rect = self.frame;
    rect.size.width = [self superview].frame.size.width;
    rect.origin.x = 0;
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.frame = rect;
                     }
                     completion:nil];
    
    // ChildSwitchViewの位置を調整
    NSArray *subviews = [[[self subviews] reverseObjectEnumerator] allObjects];
    for (NSInteger i = 0; i < subviews.count; i++) {
        ChildSwitchView *view = subviews[i];
        view.switchAvailable = YES;
        
        CGRect switchRect = view.frame;
        switchRect.origin.x = rect.size.width - switchRect.size.width - (switchRect.size.width + 10) * i;
        
        view.hidden = NO;
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             view.frame = switchRect;
                             view.childNameLabel.alpha = 1.0f;
                         }
                         completion:nil];
    }
}

- (void)closeChildSwitchViews
{
    // 自身のサイズを調整
    CGRect rect = self.frame;
    rect.size.width = 50;
    rect.origin.x = 320 - 50;
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.frame = rect;
                     }
                     completion:nil];
    // 位置を調整
    NSArray *subviews = [self subviews];
    for (NSInteger i = subviews.count - 1; i >= 0; i--) {
        ChildSwitchView *view = subviews[i];
        view.switchAvailable = NO;
        
        CGRect rect = view.frame;
        rect.origin.x = 0;
        
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             view.frame = rect;
                             view.childNameLabel.alpha = 0.0f;
                         }
                         completion:^(BOOL finished){
                             if (i != subviews.count - 1) {
                                 view.hidden = YES;
                             }
                         }];
    }
}

- (void)resetChildSwitchControlView
{
    [self setupChildSwitchViews];
    [self switchToInitialChild];
}

- (void)removeChildSwitchControlView
{
    [childSwitchViewList removeAllObjects];
    for (ChildSwitchView *view in [self subviews]) {
        [view removeFromSuperview];
    }
    [self removeFromSuperview];
    sharedObject = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
