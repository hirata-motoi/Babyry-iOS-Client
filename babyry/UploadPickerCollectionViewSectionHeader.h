//
//  UploadPickerCollectionViewSectionHeader.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UploadPickerCollectionViewSectionHeader : UIView

@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

+ (instancetype)view;
- (void)setDate:(NSString *)dateText;

@end
