//
//  UploadViewController.h
//  babyrydev
//
//  Created by kenjiszk on 2014/06/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface UploadViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate
>


@property (weak, nonatomic) IBOutlet UIImageView *uploadedImageView;
//- (IBAction)openPhotoLibrary:(UIButton *)sender;
//- (IBAction)uploadViewBackButton:(UIButton *)sender;
//- (IBAction)uploadViewCommentButton:(UIButton *)sender;

//@property (weak, nonatomic) IBOutlet UIButton *openPhotoLibraryLabel;
//@property (weak, nonatomic) IBOutlet UIButton *uploadViewBackLabel;
//@property (weak, nonatomic) IBOutlet UIButton *uploadViewCommentLabel;

//@property (weak, nonatomic) IBOutlet UILabel *uploadMonthLabel;
//@property (weak, nonatomic) IBOutlet UILabel *uploadDateLabel;
//@property (weak, nonatomic) IBOutlet UILabel *uploadNameLabel;

//@property (weak, nonatomic) IBOutlet UIScrollView *commentView;
//@property (weak, nonatomic) IBOutlet UITableView *commentTableView;
//@property (weak, nonatomic) IBOutlet UITextView *commentTextField;
//@property (weak, nonatomic) IBOutlet UIButton *commentSendButton;

@property NSString *childObjectId;
@property NSString *month;
@property NSString *date;
@property UIImage *uploadedImage;
@property NSString *bestFlag;
@property NSString *name;

@property NSMutableArray *cellHeightArray;

@property BOOL keyboradObserving;

@property CGRect defaultCommentViewRect;

@property NSArray *commentArray;
@property UIView *operationView;
@property UIView *commentView;
@property UITableView *commentTable;
@property UIScrollView *commentScrollView;
@property UITextField *commentTextField;
@property UIButton *commentSubmitButton;
@property UILabel *commentViewCloseButton;
@property PFObject *imageInfo;
@end
