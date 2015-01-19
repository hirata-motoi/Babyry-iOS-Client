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
    return [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
}

- (void)setup
{
    [self reloadIcon];
    
    self.iconView.layer.cornerRadius = self.iconView.frame.size.width/2;
    self.iconView.layer.masksToBounds = YES;
    [self.iconView.layer setBorderWidth:2.0f];
    [self.iconView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    
    self.iconContainer.layer.cornerRadius = self.iconContainer.frame.size.width/2;
    self.iconContainer.layer.masksToBounds = YES;
    [self.iconContainer.layer setBorderWidth:2.0f];
    [self.iconContainer.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    
    self.defaultIconView.layer.cornerRadius = self.defaultIconView.frame.size.width/2;
    self.defaultIconView.layer.masksToBounds = YES;
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGesture)];
    gesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:gesture];
  
    self.overlay.layer.cornerRadius = self.overlay.frame.size.width/2;
    self.overlay.layer.masksToBounds = YES;
    self.overlay.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadIcon) name:@"childSwitchViewIconChanged" object:nil];
}

- (void)setParams:(id)value forKey:(NSString *)key
{
    if ([key isEqualToString:@"childName"]) {
        _childNameLabel.text = [NSString stringWithFormat:@"%@\nちゃん", value];
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

- (void)tapGesture
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
        self.defaultIconView.hidden = YES;
        self.iconView.image = [ImageTrimming makeRectImage:[UIImage imageWithData:imageCacheData]];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)removeGestures
{
    for (UITapGestureRecognizer *gesture in [self gestureRecognizers]) {
        [self removeGestureRecognizer:gesture];
    }
}

@end
