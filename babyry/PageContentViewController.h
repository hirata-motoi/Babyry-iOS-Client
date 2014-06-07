//
//  PageContentViewController.h
//  babyrydev
//
//  Created by kenjiszk on 2014/06/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PageContentViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *weekUImageView1;
@property (weak, nonatomic) IBOutlet UIImageView *weekUImageView2;
@property (weak, nonatomic) IBOutlet UIImageView *weekUImageView3;
@property (weak, nonatomic) IBOutlet UIImageView *weekUImageView4;
@property (weak, nonatomic) IBOutlet UIImageView *weekUImageView5;
@property (weak, nonatomic) IBOutlet UIImageView *weekUImageView6;
@property (weak, nonatomic) IBOutlet UIImageView *weekUImageView7;

@property (weak, nonatomic) IBOutlet UILabel *dateLabel1;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel2;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel3;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel4;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel5;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel6;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel7;

@property NSString *weekImage1;
@property NSString *weekImage2;
@property NSString *weekImage3;
@property NSString *weekImage4;
@property NSString *weekImage5;
@property NSString *weekImage6;
@property NSString *weekImage7;

@property NSUInteger pageIndex;
@property (strong, nonatomic) NSArray *childArray;

@end
