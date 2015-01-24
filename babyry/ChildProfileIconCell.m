//
//  ChildProfileIconCell.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/22.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ChildProfileIconCell.h"
#import "ChildSwitchView.h"

@implementation ChildProfileIconCell

- (void)awakeFromNib {
    
    UITapGestureRecognizer *iconEditGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openIconEdit)];
    iconEditGesture.numberOfTapsRequired = 1;
    [_iconContainer addGestureRecognizer:iconEditGesture];
    
    ChildSwitchView *iconView = [ChildSwitchView view];
    [iconView setParams:@"" forKey:@"childName"];
    [iconView setup];
    [iconView removeGestures];
    iconView.childNameLabel.hidden = YES;
    
    [_iconContainer addSubview:iconView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setIcon:) name:@"childIconSelectedForNewChild" object:nil];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)openIconEdit
{
    [_delegate showIconEditActionSheet:nil];
}

//- (void)setIconImageWithData:(NSData *)imageData
//{
//    for (id iconView in [_iconContainer subviews]) {
//        if ([iconView isKindOfClass:[ChildSwitchView class]]) {
//            [iconView reloadIconWithImageData:imageData];
//        }
//    }
//}

- (void)setIcon:(NSNotification *)notification
{
    _imageData = [notification userInfo][@"imageData"];
    
    for (id iconView in [_iconContainer subviews]) {
        if ([iconView isKindOfClass:[ChildSwitchView class]]) {
            [iconView reloadIconWithImageData:_imageData];
        }
    }
}


@end
