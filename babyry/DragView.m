//
//  DragView.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "DragView.h"
#import "UIColor+Hex.h"

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
                                               cornerRadii:CGSizeMake(10.0, 10.0)];
        
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.bounds;
        maskLayer.path = maskPath.CGPath;
        self.layer.mask = maskLayer;
        
        
        self.backgroundColor = [UIColor_Hex colorWithHexString:@"ffbd22" alpha:1.0f];
        _dragViewLabel = [[UILabel alloc]init];
        _dragViewLabel.hidden = YES;
        [self addSubview:_dragViewLabel];
        
        _arrow = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"arrowUpperLower"]];
        _arrow.frame = CGRectMake(self.frame.size.width - 25, (self.frame.size.height - 25) / 2, 25, 25);
        [self addSubview:_arrow];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _startLocation = [[touches anyObject] locationInView:self];
    
    CGRect rect = self.frame;
    rect.size.width = 100;
    rect.origin.x = self.superview.frame.size.width - rect.size.width;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, 100, self.bounds.size.height)
                                     byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerTopLeft)
                                           cornerRadii:CGSizeMake(10.0, 10.0)];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    
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

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint pt = [[touches anyObject] locationInView:self];
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
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchedEnded");
    CGRect rect = self.frame;
    rect.size.width = 40;
    rect.origin.x = self.superview.frame.size.width - rect.size.width;
    [UIView animateWithDuration:0.3f
                 animations:^{
                     self.frame = rect;
                     _arrow.frame = CGRectMake(rect.size.width - 25, (self.frame.size.height - 25) / 2, 25, 25);
                 }
                 completion:^(BOOL finished){
                     _dragViewLabel.hidden = YES;
                 }];
    
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
