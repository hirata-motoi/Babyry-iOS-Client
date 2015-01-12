//
//  DatePickerView.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/11.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DatePickerViewDelegate <NSObject>

- (void)saveBirthday:(NSString *)childObjectId;

@end

@interface DatePickerView : UIView
+ (instancetype)view;

@property (weak, nonatomic) IBOutlet UIDatePicker *datepicker;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UILabel *childNameLabel;


@property (nonatomic,assign) id<DatePickerViewDelegate> delegate;
@property NSString *childObjectId;

@end
