//
//  UploadViewController.h
//  babyrydev
//
//  Created by kenjiszk on 2014/06/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface UploadViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *uploadedImageView;
- (IBAction)openPhotoLibrary:(UIButton *)sender;
- (IBAction)uploadViewBackButton:(UIButton *)sender;

//@property NSUInteger pageIndex;
@property NSString *childObjectId;
@property NSString *month;
@property NSString *date;
@property UIImage *uploadedImage;

@end
