//
//  ChildSwitchView.m
//  babyry
//
//  Created by hirata.motoi on 2014/12/27.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ChildSwitchView.h"
#import "UIColor+Hex.h"

@implementation ChildSwitchView;

- (void)awakeFromNib
{
    [super awakeFromNib];
}

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    ChildSwitchView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.iconView.layer.cornerRadius = view.iconView.frame.size.width/2;
    view.iconView.layer.masksToBounds = YES;
    [view.iconView.layer setBorderWidth:2.0f];
    [view.iconView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:view action:@selector(tagGesture)];
    gesture.numberOfTapsRequired = 1;
    [view addGestureRecognizer:gesture];
  
    view.overlay.layer.cornerRadius = view.overlay.frame.size.width/2;
    view.overlay.hidden = YES;
    
    return view;
}

- (void)setParams:(id)value forKey:(NSString *)key
{
    if ([key isEqualToString:@"childName"]) {
        _childNameLabel.text = (NSString *)value;
    } else if ([key isEqualToString:@"childObjectId"]) {
        _childObjectId = value;
    }
}

- (void)switch:(BOOL)active
{
    _active = active;
    _overlay.hidden = _active;
    NSString *textColor = (_active) ? @"FFFFFF" : @"A9A9A9";
    _childNameLabel.textColor = [UIColor_Hex colorWithHexString:textColor alpha:1.0f];
}

- (void)tagGesture
{
    // _switchAvailable:true -> こどもアイコンがopenになっている状態
    // _switchAvailable:false -> こどもアイコンが閉じている状態
    if (_switchAvailable) {
        // こども切り替え
        [_delegate switchChildSwitchView:_childObjectId];
    } else {
        [_delegate openChildSwitchViews];
    }
}

@end
