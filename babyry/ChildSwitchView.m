//
//  ChildSwitchView.m
//  babyry
//
//  Created by hirata.motoi on 2014/12/27.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ChildSwitchView.h"
#import "UIColor+Hex.h"
#import "ImageCache.h"
#import "ImageTrimming.h"

@implementation ChildSwitchView;

- (void)awakeFromNib
{
    [super awakeFromNib];
}

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    ChildSwitchView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
   
    return view;
}

- (void)setup
{
    [self reloadIcon];
    self.iconView.layer.cornerRadius = self.iconView.frame.size.width/2;
    self.iconView.layer.masksToBounds = YES;
    [self.iconView.layer setBorderWidth:2.0f];
    [self.iconView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tagGesture)];
    gesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:gesture];
  
    self.overlay.layer.cornerRadius = self.overlay.frame.size.width/2;
    self.overlay.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadIcon) name:@"childSwitchViewIconChanged" object:nil];
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

- (void)reloadIcon
{
    NSData *imageCacheData = [ImageCache getCache:@"icon" dir:_childObjectId];
    if (imageCacheData) {
        self.iconView.image = [ImageTrimming makeRectImage:[UIImage imageWithData:imageCacheData]];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
