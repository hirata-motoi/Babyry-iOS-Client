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
        // 全こどものChildSwitchViewを作成
        childSwitchViewList = [[NSMutableArray alloc]init];
        NSMutableArray *childProperties = [ChildProperties getChildProperties];
        for (NSMutableDictionary *childProperty in childProperties) {
            NSLog(@"childProperty :%@", childProperty[@"name"]);
            ChildSwitchView *childSwitchView = [ChildSwitchView view];
            childSwitchView.delegate = self;
            [childSwitchView setValue:childProperty[@"name"] forKey:@"childName"];
            [childSwitchView setValue:childProperty[@"childObjectId"] forKey:@"objectId"];
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
}

// ChildSwitchViewをタップされた時のdelegateメソッド
// 全こどものChildSwitchViewをactiveにする
// 自身の大きさを調整
// 位置を調節して表示
// 自分の一つ下にoverlayを表示

// こどもの切り替えが行われた時のdelegateメソッド
// タップされたChildSwitchViewをactiveに、他のChildSwitchViewをinactiveにする
// inactiveなChildSwitchViewを隠す
// overlayを消す
// ViewControllerのdelegateメソッドを実行してPageContentViewControllerを切り替える

- (void)openChildSwitchViews
{
    // 自身の裏にoverlayを設定
    // 自身の色を半透明黒に設定
    // ChildSwitchViewの位置を調整
    NSArray *subviews = [self subviews];
    for (int i = subviews.count - 1; i >= 0; i--) {
        ChildSwitchView *view = subviews[i];
        
        CGRect rect = view.frame;
        rect.origin.x -= 80 * i;
        view.frame = rect;
    }
}


@end
