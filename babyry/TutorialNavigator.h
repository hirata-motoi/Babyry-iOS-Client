//
//  TutorialNavigator.h
//  babyry
//
//  Created by hirata.motoi on 2014/09/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TutorialNavigator : NSObject

@property UIViewController *targetViewController;

- (BOOL)showNavigationView;
- (void)removeNavigationView;
- (UIButton *)createTutorialSkipButton;

@end
