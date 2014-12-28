//
//  ChildSwitchView.h
//  babyry
//
//  Created by hirata.motoi on 2014/12/27.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

@protocol ChildSwitchViewDelegate <NSObject>

- (void)openChildSwitchViews;

@end

#import <UIKit/UIKit.h>

@interface ChildSwitchView : UIView

+ (instancetype)view;
- (void)setValue:(id)value forKey:(NSString *)key;
- (void)switch:(BOOL)active;

@property (nonatomic,assign) id<ChildSwitchViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *childNameLabel;
@property BOOL active;
@property NSString *childObjectId;
@property BOOL switchAvailable;

@end
