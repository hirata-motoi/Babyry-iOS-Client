//
//  ChildAddIconView.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/19.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ChildAddIconView.h"

@implementation ChildAddIconView

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    return [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    self.layer.cornerRadius = self.frame.size.width / 2;
    self.layer.masksToBounds = YES;
    [self.layer setBorderWidth:2.0f];
    [self.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGesture)];
    gesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:gesture];
}

- (void)setParams:(id)value forKey:(NSString *)key
{
    self.childNameLabel.text = @"";
    self.childObjectId = @"";
}

- (void)tapGesture
{
    [self.delegate openAddChild];
}
@end
