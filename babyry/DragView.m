//
//  DragView.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "DragView.h"
#import "UIColor+Hex.h"

const NSInteger dragViewHideInterval = 4;

@implementation DragView
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIBezierPath *maskPath;
        maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                         byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerTopLeft)
                                               cornerRadii:CGSizeMake(25.0, 25.0)];
        
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.bounds;
        maskLayer.path = maskPath.CGPath;
        self.layer.mask = maskLayer;
        
        
        self.backgroundColor = [UIColor_Hex colorWithHexString:@"ffbd22" alpha:0.6f];
        _dragViewLabel = [[UILabel alloc]init];
        _dragViewLabel.hidden = YES;
        [self addSubview:_dragViewLabel];
        
        _arrow = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"arrowUpperLower"]];
        _arrow.frame = CGRectMake(self.frame.size.width - 25, (self.frame.size.height - 25) / 2, 25, 25);
        [self addSubview:_arrow];
       
        _lastTachDate = [NSDate date];
        [NSTimer scheduledTimerWithTimeInterval:dragViewHideInterval target:self selector:@selector(hideDragView:) userInfo:nil repeats:NO];
        
        UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(drag:)];
        [self addGestureRecognizer:gesture];
    }
    return self;
}


- (void)dragBegin:(UIPanGestureRecognizer *)sender
{
    _startLocation = [sender locationInView:self];
    
    CGRect rect = self.frame;
    rect.size.width = 150;
    rect.origin.x = self.superview.frame.size.width - rect.size.width;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, 150, self.bounds.size.height)
                                     byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerTopLeft)
                                           cornerRadii:CGSizeMake(25.0, 25.0)];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    
    _lastTachDate = [NSDate date];
    
    [UIView animateWithDuration:0.3f
                 animations:^{
                     self.frame = rect;
                     self.layer.mask = maskLayer;
                     _arrow.frame = CGRectMake(rect.size.width - 25, (self.frame.size.height - 25) / 2, 25, 25);
                 }
                 completion:^(BOOL finished){
                     _dragViewLabel.frame = CGRectMake(10, 0, rect.size.width - 10, self.frame.size.height);
                     _dragViewLabel.hidden = NO;
                 }];
}

- (void)dragChanged:(UIPanGestureRecognizer *)sender
{
    CGPoint pt = [sender locationInView:self];
	CGRect frame = [self frame];
	frame.origin.y += pt.y - _startLocation.y;
    
    if (frame.origin.y < _dragViewUpperLimitOffset) {
        frame.origin.y = _dragViewUpperLimitOffset;
    }                    
    if (frame.origin.y >= _dragViewLowerLimitOffset) {
        frame.origin.y = _dragViewLowerLimitOffset;
    }
	[self setFrame:frame];
    [_delegate drag:self];
    _lastTachDate = [NSDate date];
}

- (void)dragEnded:(UIPanGestureRecognizer *)sender
{
    CGRect rect = self.frame;
    rect.size.width = 70;
    rect.origin.x = self.superview.frame.size.width - rect.size.width;
    [UIView animateWithDuration:0.3f
                 animations:^{
                     self.frame = rect;
                     _arrow.frame = CGRectMake(rect.size.width - 25, (self.frame.size.height - 25) / 2, 25, 25);
                 }
                 completion:^(BOOL finished){
                     _dragViewLabel.hidden = YES;
                 }];
    _lastTachDate = [NSDate date];
    
    // 4秒後にviewをhideにする
    // ただしlast tapからの時間が4秒未満の場合はskip
    [NSTimer scheduledTimerWithTimeInterval:dragViewHideInterval target:self selector:@selector(hideDragView:) userInfo:nil repeats:NO];
}

- (void)hideDragView:(id)sender
{
    NSDate *currentDate = [NSDate date];
    if ( [currentDate timeIntervalSinceDate:_lastTachDate] >= dragViewHideInterval ) {
        self.hidden = YES;
    }
}

- (void)drag:(UIPanGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self dragBegin:sender];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        [self dragChanged:sender];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        [self dragEnded:sender];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
