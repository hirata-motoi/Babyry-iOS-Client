//
//  ChildSwitchControlView.h
//  babyry
//
//  Created by hirata.motoi on 2014/12/27.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

@protocol ChildSwitchControlViewDelegate <NSObject>

- (void)reloadPageContentViewController:(NSString *)childObjectId;
- (void)showOverlay;
- (void)hideOverlay;
- (void)openAddChild;
- (void)adjustChildSwitchControlView;

@end

#import <UIKit/UIKit.h>
#import "ChildSwitchView.h"

@interface ChildSwitchControlView : UIView <ChildSwitchViewDelegate>

+ (ChildSwitchControlView*)sharedManager;
- (void)switchChildSwitchView: (NSString *)childObjectId;
- (void)openChildSwitchViews;
- (void)closeChildSwitchViews;
- (void)setupChildSwitchViews;
- (void)switchToInitialChild;
- (void)resetChildSwitchControlView;
- (void)removeChildSwitchControlView;
- (ChildSwitchView *)getChildAddIcon;

@property (nonatomic,assign) id<ChildSwitchControlViewDelegate> delegate;

@end
