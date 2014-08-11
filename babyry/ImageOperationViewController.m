//
//  ImageOperationViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageOperationViewController.h"
#import "ViewController.h"
#import "CommentViewController.h"
#import "PageContentViewController.h"
#import "UploadViewController.h"
#import "ImageCache.h"
#import "TagEditViewController.h"
#import "ImageTrimming.h"
#import "PushNotification.h"
#import "Navigation.h"
#import "UploadPickerViewController.h"
#import "ImageToolbarViewController.h"

@interface ImageOperationViewController ()

@end

@implementation ImageOperationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // タップでoperationViewを非表示にする
    UITapGestureRecognizer *hideOperationViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideOperationView:)];
    hideOperationViewTapGestureRecognizer.numberOfTapsRequired = 1;
    self.view.userInteractionEnabled = YES;
    [self.view addGestureRecognizer:hideOperationViewTapGestureRecognizer];

    // 画像がなければコメントは出来ない
    // プリロード(サムネイルだけで本画像ではない)時もコメントは出さない(出せない)
    if (_imageInfo && !_isPreload) {
        [self setupCommentView];
    }
    [self setupNavigation];
    
    // 画像削除、保存、コメントは全部toolbar経由にする
    [self setupToolbar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openPhotoLibrary
{
    UploadPickerViewController *uploadPickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UploadPickerViewController"];
    uploadPickerViewController.month = _month;
    uploadPickerViewController.childObjectId = _childObjectId;
    uploadPickerViewController.date = _date;
    uploadPickerViewController.uploadViewController = _uploadViewController;
    [self.navigationController pushViewController:uploadPickerViewController animated:YES];
    return;
}

- (void)hideOperationView:(id)sender
{
    self.view.hidden = YES;
}

- (void)setupCommentView
{
    CommentViewController *commentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CommentViewController"];
    commentViewController.childObjectId = _childObjectId;
    commentViewController.name = _name;
    commentViewController.date = _date;
    commentViewController.month = _month;
    commentViewController.imageInfo = _imageInfo;
    _commentView = commentViewController.view;
    _commentView.hidden = NO;
    _commentView.frame = CGRectMake(self.view.frame.size.width, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height -44 -20 -44);
    [self addChildViewController:commentViewController];
    [self.view addSubview:_commentView];
}

// NavigationController(self.navigationController)を使うとPageViewControllerがずれるため
// self.navigationControllerは非表示にして、自前でnavigationを作る
- (void)setupNavigation
{
    [self setColorForNavigation];
   
    // back button
    UIButton *backButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 6, 44, 32)];
    [backButton setBackgroundImage:[UIImage imageNamed:@"angleLeftReverse"] forState:UIControlStateNormal];
    UITapGestureRecognizer *back = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doBack)];
    [backButton addGestureRecognizer:back];
    [_navbar addSubview:backButton];
    
    // 写真変更ボタン
    UIButton *openPhotoLibraryButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [openPhotoLibraryButton setBackgroundImage:[UIImage imageNamed:@"imageIcon"] forState:UIControlStateNormal];
    [openPhotoLibraryButton addTarget:self action:@selector(openPhotoLibrary) forControlEvents:UIControlEventTouchUpInside];
    _navbarItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:openPhotoLibraryButton];
   
    // title
    NSString *yyyy =  [_date substringWithRange:NSMakeRange(0, 4)];
    NSString *mm   =  [_date substringWithRange:NSMakeRange(4, 2)];
    NSString *dd   =  [_date substringWithRange:NSMakeRange(6, 2)];
    
    [Navigation setTitle:_navbarItem withTitle:[NSString stringWithFormat:@"%@年%@月%@日", yyyy, mm, dd] withSubtitle:_uploadViewController.promptText withFont:nil withFontSize:0 withColor:nil];
}

- (void)setupToolbar
{
    ImageToolbarViewController *imageToolbarViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ImageToolbarViewController"];
    imageToolbarViewController.commentView = _commentView;
    _toolbarView = imageToolbarViewController.view;
    _toolbarView.hidden = NO;
    CGRect frame = CGRectMake(0, self.view.frame.size.height - imageToolbarViewController.view.frame.size.height, imageToolbarViewController.view.frame.size.width, imageToolbarViewController.view.frame.size.height);
    _toolbarView.frame = frame;
    [self addChildViewController:imageToolbarViewController];
    [self.view addSubview:_toolbarView];
}

- (void)setColorForNavigation
{
    [Navigation setNavbarColor:_navbar withColor:nil withEtcElements:@[_statusBarCoverView]];
}

- (void)doBack
{
    [self.navigationController popViewControllerAnimated:YES];
    [self.navigationController setNavigationBarHidden:NO];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
