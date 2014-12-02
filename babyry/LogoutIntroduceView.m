//
//  LogoutIntroduceView.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/12.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "LogoutIntroduceView.h"
#import "UIColor+Hex.h"

@implementation LogoutIntroduceView
@synthesize delegate = _delegate;

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
    LogoutIntroduceView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.7];
    view.layer.cornerRadius = 5;
    
    UITapGestureRecognizer *closeGesture = [[UITapGestureRecognizer alloc]initWithTarget:view action:@selector(close)];
    closeGesture.numberOfTapsRequired = 1;
    [view.closeButton addGestureRecognizer:closeGesture];
    view.closeButton.userInteractionEnabled = YES;
    view.autoresizingMask = UIViewAutoresizingNone;
    
    UITapGestureRecognizer *logoutGesture = [[UITapGestureRecognizer alloc]initWithTarget:view action:@selector(doLogout)];
    logoutGesture.numberOfTapsRequired = 1;
    [view.logoutButton addGestureRecognizer:logoutGesture];
    
    return view;
}

- (void)close
{
    [self removeFromSuperview];
}

- (void)doLogout
{
    [_delegate doLogout];
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
