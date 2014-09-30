//
//  ChildListCell.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChildListCell : UIView

@property (strong, nonatomic) IBOutlet UILabel *childName;
@property (strong, nonatomic) IBOutlet UILabel *childDeleteLabel;
@property (strong, nonatomic) IBOutlet UILabel *childBirthday;

@property NSString *childObjectId;

+ (instancetype)view;

@end
