//
//  CommentViewController.h
//  babyry
//
//  Created by 平田基 on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "UploadViewController.h"
#import "UIPlaceHolderTextView.h"

@interface CommentViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITableView *commentTableView;
@property (weak, nonatomic) IBOutlet UIButton *commentSubmitButton;
@property (weak, nonatomic) IBOutlet UIView *commentTableContainer;
@property (strong, nonatomic) IBOutlet UIView *commentViewContainer;

@property NSString *name;
@property NSString *date;
@property NSString *month;
@property NSString *childObjectId;
@property NSMutableArray *commentArray;
@property BOOL keyboardObserving;
@property CGRect defaultCommentViewRect;
@property UploadViewController *uploadViewController;
@property UIPlaceHolderTextView *commentTextView;
@property UIView *tagViewOnCommentView;
@property NSTimer *commentTimer;
@property BOOL isGettingComment;
@property NSIndexPath *indexPath;

@end
