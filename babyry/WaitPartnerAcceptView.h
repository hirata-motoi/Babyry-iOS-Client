//
//  WaitPartnerAcceptView.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WaitPartnerAcceptView : UIView
@property (strong, nonatomic) IBOutlet UIButton *withdrawLabel;
- (IBAction)withdrawAction:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *applyingMailLabel;

+ (instancetype)view;

@end
