//
//  ChildProfileEditViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@protocol ChildProfileEditViewDelegate <NSObject>

- (void)reloadChildProfile;

@end

@interface ChildProfileEditViewController : UIViewController
{
    id<ChildProfileEditViewDelegate>delegate;
}
@property (nonatomic, assign) id<ChildProfileEditViewDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIView *childNicknameCellContainer;
@property (strong, nonatomic) IBOutlet UITextField *childNicknameEditTextField;
@property (strong, nonatomic) IBOutlet UILabel *childNicknameSaveLabel;

@property (strong, nonatomic) IBOutlet UIDatePicker *childBirthdayDatePicker;
@property (strong, nonatomic) IBOutlet UILabel *childBirthdaySaveLabel;
@property (strong, nonatomic) IBOutlet UIView *childBirthdayDatePickerContainer;

@property NSString *childObjectId;
@property NSDate *childBirthday;

@property NSString *editTarget;
@property CGRect childNicknameCellRect;
@property CGPoint childBirthdayCellPoint;

@end
