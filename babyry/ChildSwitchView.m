//
//  ChildSwitchView.m
//  babyry
//
//  Created by hirata.motoi on 2014/12/27.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ChildSwitchView.h"
#import "UIColor+Hex.h"

@implementation ChildSwitchView

- (void)awakeFromNib
{
    [super awakeFromNib];
}

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    ChildSwitchView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.layer.cornerRadius = view.frame.size.width/2;
    view.layer.masksToBounds = YES;
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:view action:@selector(tagGesture)];
    gesture.numberOfTapsRequired = 1;
    [view addGestureRecognizer:gesture];
    
    return view;
}

- (void)setValue:(id)value forKey:(NSString *)key
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
    
    NSString *colorString = (_active) ? @"FFFFFF" : @"000000";
    self.backgroundColor = [UIColor_Hex colorWithHexString:colorString alpha:0.7];
}

- (void)tagGesture
{
    // _switchAvailable:true -> こどもアイコンがopenになっている状態
    // _switchAvailable:false -> こどもアイコンが閉じている状態
    if (_switchAvailable) {
        // こども切り替え
    } else {
        [_delegate openChildSwitchViews];
    }
}

@end
