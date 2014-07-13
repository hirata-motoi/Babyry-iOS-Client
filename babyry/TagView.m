//
//  TagView.m
//  babyry
//
//  Created by 平田基 on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TagView.h"

@implementation TagView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UITapGestureRecognizer *tagTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleTag:)];
        tagTapGestureRecognizer.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tagTapGestureRecognizer];
    }
    
    return self;
}

+ (TagView *)createTag:(PFObject *)tagInfo attached:(BOOL)attached
{
    CGRect rect = [self getFrame:tagInfo[@"tagId"]];
    TagView *tagView = [[TagView alloc]initWithFrame:rect];
    tagView.attached = attached;
    [tagView setNotificationCenter];
    tagView.userInteractionEnabled = YES;
    
    NSLog(@"created tag : %@", tagView);
    
    // id
    tagView.tagId = tagInfo[@"tagId"];

    // 形
//    tagView.layer.cornerRadius = 20;
//    tagView.clipsToBounds = YES;

    // 色
//    tagView.opaque = NO;
//    NSString *colorString = tagInfo[@"color"];
//    UIColor *color = [self getColor:colorString];
//    if (tagView.attached) {
//        color = [color colorWithAlphaComponent:0.5];
//    }
//    tagView.backgroundColor = color;
    
    
    NSString *imageName;
    if ([tagInfo[@"color"] isEqualToString:@"red"]) {
        imageName = @"badgeRed";
    } else if ([tagInfo[@"color"] isEqualToString:@"blue"]) {
        imageName = @"badgeBlue";
    }
    
    UIImage *image = [UIImage imageNamed:imageName];
    tagView.image = image;
    if (tagView.attached) {
        tagView.alpha = 1.0;
    } else {
        tagView.alpha = 0.3;
    }

    return tagView;
}

+ (CGRect)getFrame:(NSNumber *)tagId
{
    int width  = 40;
    int height = 40;
    int y      = 10;
    int x      = 10 + ([tagId intValue] - 1) * (40 + 10);
    
    CGRect rect = CGRectMake(x, y, width, height);
    return rect;
}

// tagEditViewの上にtagViewが乗っているが、
// tagEditViewにUIGestureRecognizerでイベントを登録しているため
// tagViewをtapしてもtouchesEndedがキャッチされない。
// 仕方ないのでgesture recognizerでイベントを登録する
- (void)toggleTag:(id)sender
{
    
    if (self.tagEditViewController.tagTouchDisabled) {
        return;
    }
    
    [self toggleTagLocalStatus];
    
    [self notifyTagUpdate];
}

// tagのlocalな状態(attached, tagの色)を変える
- (void)toggleTagLocalStatus
{
    if (!self.attached) {
        self.alpha = 0.3;
        self.attached = YES;
    } else {
        self.alpha = 1;
        self.attached = NO;
    }
}

+ (UIColor *)getColor:(NSString *)colorString
{
    UIColor *color;
    if ([colorString isEqualToString:@"red"]) {
        color = [UIColor redColor];
    } else if ([colorString isEqualToString:@"blue"]) {
        color = [UIColor blackColor];
    }
    return color;
}

- (void)notifyTagUpdate
{
    //tagUpdateを通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateTag" object:self userInfo:nil];
}

- (void)setNotificationCenter
{
    NSString *notificationName = [NSString stringWithFormat:@"updateTagFailed:%@", [self.tagId stringValue]];
    // NotificationCenter
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(revertTag:) name:notificationName object:nil];
}

- (void)revertTag:(NSNotification *)notification
{
    [self toggleTagLocalStatus];
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
