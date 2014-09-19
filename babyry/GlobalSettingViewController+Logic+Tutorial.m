//
//  GlobalSettingViewController+Logic+Tutorial.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "GlobalSettingViewController+Logic+Tutorial.h"
#import "Tutorial.h"
#import "TutorialStage.h"

@implementation GlobalSettingViewController_Logic_Tutorial

- (void)addFrameForTutorial:(UITableViewCell *)cell withIndexPath:(NSIndexPath *)indexPath
{
    TutorialStage *currentStage = [Tutorial currentStage];
    // partChangeの時
    if ([currentStage.currentStage isEqualToString:@"partChange"]) {
        if (indexPath.section == 0 && indexPath.row == 1) { // パート変更のcell
            [self addFrame:cell];
            return;
        }
    }
    // addChildの時
    else if ([currentStage.currentStage isEqualToString:@"addChild"]) {
        if (indexPath.section == 0 && indexPath.row == 1) { // パート変更cellのswitchを無効にする TODO なんかうまく動いてない
            for (UIView *v in [cell subviews]) {
                NSLog(@"view in cell : %@", v);
                if (![v isKindOfClass:[UISegmentedControl class]]) {
                    continue;
                }
                NSLog(@"segment control found");
                
                UISegmentedControl *seg = (UISegmentedControl *)v;
                for (int i = 0; i < seg.numberOfSegments;  i++) {
                    [seg setEnabled:NO forSegmentAtIndex:i];
                }
            }
        }
        if (indexPath.section == 1 && indexPath.row == 0) { // こどもを追加のcell
            [self addFrame:cell];
            return;
        }
    }
}

- (void)addFrame:(UITableViewCell *)cell
{
    cell.layer.borderWidth = 5.0f;
    cell.layer.borderColor = [[UIColor redColor] CGColor];
    cell.layer.cornerRadius = 5.0f;
}

- (BOOL)forbiddenSelectForTutorial:(NSIndexPath *)indexPath
{
    TutorialStage *currentStage = [Tutorial currentStage];
    // partChangeの時
    if ([currentStage.currentStage isEqualToString:@"partChange"]) {
        if (indexPath.section == 0 && indexPath.row == 1) { // パート変更のcell
            return NO;
        }
        return YES;
    }
    // addChildの時
    else if ([currentStage.currentStage isEqualToString:@"addChild"]) {
        if (indexPath.section == 1 && indexPath.row == 0) { // こどもを追加のcell
            return NO;
        }
        return YES;
    }
    return YES;
}


@end
