//
//  DragView.h
//  babyry
//
//  Created by hirata.motoi on 2014/08/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DragView;
@protocol DragViewDelegate <NSObject>
- (void)drag:(DragView *)dragView;
@end

@interface DragView : UIView
{
    id<DragViewDelegate>delegate;
}
@property (nonatomic,assign) id<DragViewDelegate> delegate;

@property UILabel *dragViewLabel;
@property UIImageView *arrow;
@property CGPoint startLocation;
@property CGFloat dragViewLowerLimitOffset;
@property CGFloat dragViewUpperLimitOffset;
@property NSDate *lastTachDate;
                             
@end
