//
//  GlobalSettingViewController+Logic.h
//  babyry
//
//  Created by hirata.motoi on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GlobalSettingViewController.h"

@interface GlobalSettingViewController_Logic : NSObject

@property GlobalSettingViewController *globalSettingViewController;

- (void)addFrameForTutorial:(UITableViewCell *)cell withIndexPath:(NSIndexPath *)indexPath;
- (BOOL)forbiddenSelectForTutorial:(NSIndexPath *)indexPath;

@end
