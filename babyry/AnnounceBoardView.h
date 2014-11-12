//
//  AnnounceBoardView.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PageContentViewController.h"

@interface AnnounceBoardView : UIView

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UILabel *closeLabel;
- (IBAction)okButton:(id)sender;

+ (instancetype)view;
+ (void)setAnnounceInfo:(NSString *)key title:(NSString *)title message:(NSString *)message;
+ (NSDictionary *) getAnnounceInfo;
+ (void)removeAnnounceInfoByOuter;

@property PageContentViewController *pageContentViewController;
@property NSString *childObjectId;

@end
