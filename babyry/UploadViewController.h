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

@interface UploadViewController : UIViewController


@property (weak, nonatomic) IBOutlet UIImageView *uploadedImageView;

@property CGRect defaultImageViewFrame;
@property NSString *childObjectId;
@property NSString *month;
@property NSString *date;
@property UIImage *uploadedImage;
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
@property NSInteger tagAlbumPageIndex;
@end
