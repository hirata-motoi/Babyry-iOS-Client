//
//  NicknameEditViewController.h
//  babyry
//
//  Created by 平田基 on 2014/07/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@protocol ProfileEditViewDelegate <NSObject>

- (void)changeNickname:(NSString *)nickname;
- (void)changeEmail:(NSString *)email;

@end

@interface ProfileEditViewController : UIViewController
{
    id<ProfileEditViewDelegate>delegate;
}
@property (nonatomic, assign) id<ProfileEditViewDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIView *profileCellContainer;
@property (weak, nonatomic) IBOutlet UITextField *profileEditTextField;
@property (strong, nonatomic) IBOutlet UILabel *profileEditSaveLabel;

@property NSString *profileType;

@property CGRect profileCellRect;

@end
