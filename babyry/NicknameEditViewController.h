//
//  NicknameEditViewController.h
//  babyry
//
//  Created by 平田基 on 2014/07/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@protocol NicknameEditViewDelegate <NSObject>

- (void)changeNickname:(NSString *)nickname;

@end

@interface NicknameEditViewController : UIViewController
{
    id<NicknameEditViewDelegate>delegate;
}
@property (nonatomic, assign) id<NicknameEditViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *nicknameEditTextField;

@property CGRect nicknameCellRect;

@end
