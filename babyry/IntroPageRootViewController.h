//
//  IntroPageRootViewController.h
//  babyry
//
//  Created by hirata.motoi on 2014/08/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@protocol IntroPageRootViewControllerDelegate <NSObject>
- (void)openLoginView;
- (void)skipToLast:(NSInteger)currentIndex;
@end

@interface IntroPageRootViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *skipFromFirst;
@property (weak, nonatomic) IBOutlet UILabel *skipFromSecond;
@property (weak, nonatomic) IBOutlet UILabel *skipFromThird;
@property (weak, nonatomic) IBOutlet UILabel *skipFromFourth;

@property NSInteger currentIndex;

@property (nonatomic,assign) id<IntroPageRootViewControllerDelegate> delegate;

@end
