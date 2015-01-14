//
//  GenderSegmentControl.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/11.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GenderSegmentControl : UISegmentedControl

@property NSString *childObjectId;

- (GenderSegmentControl *)initWithParams:(NSMutableDictionary *)params;

@end
