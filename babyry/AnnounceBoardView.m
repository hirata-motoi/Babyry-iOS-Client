//
//  AnnounceBoardView.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AnnounceBoardView.h"
#import "UIColor+Hex.h"
#import "ProfileViewController.h"
#import "UserRegisterViewController.h"
#import "ChildProfileViewController.h"
#import "ChildProperties.h"

NSString *announceTitle;
NSString *announceMessage;
NSString *announceKey;

@implementation AnnounceBoardView

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

- (IBAction)okButton:(id)sender {
    if ([announceKey isEqualToString:@"childBirthday"]){
        [self openChildProfile];
    } else if ([announceKey isEqualToString:@"registerAccount"]) {
        [self openEmailVerifyView];
    }
    [self close];
}

-(void)openChildProfile
{
    ChildProfileViewController *childProfileViewController = [_pageContentViewController.storyboard instantiateViewControllerWithIdentifier:@"ChildProfileViewController"];
    // 一人も誕生日を入れていない時にここにくるから、自分のこどもであればどのchildObjectIdでもいい
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:_childObjectId];
    childProfileViewController.childObjectId = childProperty[@"objectId"];
    [_pageContentViewController.navigationController pushViewController:childProfileViewController animated:YES];
}

-(void)openEmailVerifyView
{
    UserRegisterViewController * userRegisterViewController = [_pageContentViewController.storyboard instantiateViewControllerWithIdentifier:@"UserRegisterViewController"];
    [_pageContentViewController.navigationController pushViewController:userRegisterViewController animated:YES];
}

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    AnnounceBoardView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.7];
    view.layer.cornerRadius = 5;
    
    UITapGestureRecognizer *closeGesture = [[UITapGestureRecognizer alloc]initWithTarget:view action:@selector(close)];
    closeGesture.numberOfTapsRequired = 1;
    [view.closeLabel addGestureRecognizer:closeGesture];
    view.closeLabel.userInteractionEnabled = YES;
        
    return view;
}

- (void)close
{
    [self removeAnnounceInfo];
    [self.superview removeFromSuperview];
    [self removeFromSuperview];
}

+ (void)setAnnounceInfo:(NSString *)key title:(NSString *)title message:(NSString *)message
{
    if (!key || !title || !message) {
        return;
    }

    announceTitle = title;
    announceMessage = message;
    announceKey = key;
}

+ (NSDictionary *) getAnnounceInfo
{
    if (!announceTitle || !announceMessage || !announceKey) {
        return nil;
    }
    return [[NSDictionary alloc] initWithObjects:@[announceKey, announceTitle, announceMessage] forKeys:@[@"key", @"title", @"message"]];
}

- (void)removeAnnounceInfo
{
    announceTitle = nil;
    announceMessage = nil;
    announceKey = nil;
}

@end
