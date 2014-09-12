//
//  LogoutIntroduceView.h
//  babyry
//
//  Created by hirata.motoi on 2014/09/12.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LogoutIntroduceView;
@protocol LogoutIntroduceViewDelegate <NSObject>
+ (void)doLogout;
@end

@interface LogoutIntroduceView : UIView {
    id<LogoutIntroduceViewDelegate>delegate;
}
@property (nonatomic,assign) id<LogoutIntroduceViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;

+ (instancetype)view;
- (void)close;

@end
