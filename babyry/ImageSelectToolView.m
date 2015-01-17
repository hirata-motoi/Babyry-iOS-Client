//
//  ImageSelectToolView.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/09.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ImageSelectToolView.h"

@implementation ImageSelectToolView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    ImageSelectToolView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    
    UITapGestureRecognizer *cancelGesture = [[UITapGestureRecognizer alloc]initWithTarget:view action:@selector(cancel)];
    cancelGesture.numberOfTapsRequired = 1;
    [view.cancelButton addGestureRecognizer:cancelGesture];
    
    UITapGestureRecognizer *submitGesture = [[UITapGestureRecognizer alloc]initWithTarget:view action:@selector(submit)];
    cancelGesture.numberOfTapsRequired = 1;
    [view.submitButton addGestureRecognizer:submitGesture];
    
    view.submitButton.layer.cornerRadius = 6.0f;
    view.submitButton.layer.masksToBounds = YES;
    view.cancelButton.layer.cornerRadius = 6.0f;
    view.cancelButton.layer.masksToBounds = YES;
    
    return view;
}

- (void)cancel
{
    [_delegate cancel];
}

- (void)submit
{
    [_delegate submit];
}


@end
