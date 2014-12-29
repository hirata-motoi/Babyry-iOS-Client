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
        // 全こどものChildSwitchViewを作成
        childSwitchViewList = [[NSMutableArray alloc]init];
        NSMutableArray *childProperties = [ChildProperties getChildProperties];
        for (NSMutableDictionary *childProperty in childProperties) {
            NSLog(@"childProperty :%@", childProperty[@"name"]);
            ChildSwitchView *childSwitchView = [ChildSwitchView view];
            childSwitchView.delegate = self;
            [childSwitchView setParams:childProperty[@"name"] forKey:@"childName"];
            [childSwitchView setParams:childProperty[@"objectId"] forKey:@"childObjectId"];
            [childSwitchViewList addObject:childSwitchView];
        }
        
        // 自身のサイズを調整
        // 最初は40x40のレクタングルでOK
        self.frame = CGRectMake(320 - 50, 70, 50, 50);
        
        // 自身にaddSubview
        for (ChildSwitchView *view in childSwitchViewList) {
            [self addSubview:view];
        }
    }
    return self;
}

- (void)switchChildSwitchView: (NSString *)childObjectId
{
    NSLog(@"switchChildSwitchView :%@", childObjectId);
    // 指定されたchildのviewを最前面に持ってくる
    // activeを入れ替えする
    for (ChildSwitchView *view in childSwitchViewList) {
        if ([view.childObjectId isEqualToString:childObjectId]) {
            NSLog(@"switchChildSwitchView yes");
            [self bringSubviewToFront:view];
            [view switch:YES];
        } else {
            NSLog(@"switchChildSwitchView no");
            [view switch:NO];
        }
    }
    
    // delegateメソッドを叩いて表示切り替え
    [_delegate reloadPageContentViewController:childObjectId];
}

- (void)openChildSwitchViews
{
    NSLog(@"openChildSwitchViews");
    // ViewControllerにoverlayを設定
    [_delegate showOverlay];
    // 自身を最前面に持ってくる
    // 自身を広げる
    CGRect rect = self.frame;
    rect.size.width = [self superview].frame.size.width;
    rect.origin.x = 0;
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:nil
                     animations:^{
                        self.frame = rect;
                     }
                     completion:nil];
    
    // ChildSwitchViewの位置を調整
    
    NSArray *subviews = [self subviews];
    for (int i = subviews.count - 1; i >= 0; i--) {
        ChildSwitchView *view = subviews[i];
        view.switchAvailable = YES;
        
        CGRect rect = view.frame;
        rect.origin.x = self.frame.size.width - 80 * (i + 1);
        
        view.hidden = NO;
        
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:nil
                         animations:^{
                             view.frame = rect;
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
                        options:nil
                     animations:^{
                         self.frame = rect;
                     }
                     completion:nil];
    // 位置を調整
    NSArray *subviews = [self subviews];
    for (int i = subviews.count - 1; i >= 0; i--) {
        ChildSwitchView *view = subviews[i];
        view.switchAvailable = NO;
        
        CGRect rect = view.frame;
        rect.origin.x = 0;
        
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:nil
                         animations:^{
                             view.frame = rect;
                         }
                         completion:^(BOOL finished){
                             if (i != subviews.count - 1) {
                                 view.hidden = YES;
                             }
                         }];
    }
}


@end
