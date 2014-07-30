//
//  UploadViewController.m
//  babyrydev
//
//  Created by kenjiszk on 2014/06/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "UploadViewController.h"
#import "PageContentViewController.h"
#import "ImageCache.h"
#import "ViewController.h"
#import "ImageOperationViewController.h"
#import "TagEditViewController.h"
#import "ImageTrimming.h"
#import "CommentViewController.h"
#import "Navigation.h"

@interface UploadViewController ()

@end

@implementation UploadViewController

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
    
    _defaultImageViewFrame = _uploadedImageView.frame;
    
    _uploadedImageView.frame = [self getUploadedImageFrame:_uploadedImage];
    _uploadedImageView.image = _uploadedImage;
    [self setupCommentView];
    [self setupOperationView];
    
    // Parseからちゃんとしたサイズの画像を取得
    PFQuery *originalImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
    originalImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [originalImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
    [originalImageQuery whereKey:@"bestFlag" equalTo:@"choosed"];
    [originalImageQuery whereKey:@"date" equalTo:[NSString stringWithFormat:@"D%@", _date]];
    [originalImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ([objects count] > 0) {
            PFObject * object = [objects objectAtIndex:0];
            [object[@"imageFile"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error){
                if(!error){
                    _uploadedImageView.image = [UIImage imageWithData:data];
                }
            }];
            _imageInfo = object;
        }
    }];
}

- (void)openOperationView:(id)sender
{
    _operationView.hidden = NO;
    //[self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    // super
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    if ([[PFUser currentUser][@"tutorialStep"] intValue] == 5) {
        _overlay = [[ICTutorialOverlay alloc] init];
        _overlay.hideWhenTapped = NO;
        _overlay.animated = YES;
    
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 170, 300, 150)];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.numberOfLines = 0;
        label.text = @"過去の画像について(Step 11/13)\n\n過去の画像に関しては、画像の変更、コメントの追加、タグの付与が出来ます。\n画面タップで戻ってください。";
        [_overlay addSubview:label];
        [_overlay show];
        
        UITapGestureRecognizer *overlayGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeTuto:)];
        overlayGR.numberOfTapsRequired = 1;
        [_overlay addGestureRecognizer:overlayGR];
        
        PFUser *user = [PFUser currentUser];
        user[@"tutorialStep"] = [NSNumber numberWithInt:6];
        [user save];
    }
}

- (void)closeTuto:(id)sender
{
    NSLog(@"closeTuto");
    [_overlay hide];
    [_overlay removeFromSuperview];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // super
    [super viewWillDisappear:animated];
}

- (void)closeView:(id)sender
{
    _operationView.hidden = YES;
}

- (void)openCommentView:(id)sender
{
    
    _commentView.hidden = FALSE;
}

- (void)setupOperationView
{
    // operationView
    ImageOperationViewController *operationView = [self.storyboard instantiateViewControllerWithIdentifier:@"OperationView"];
    
    operationView.childObjectId = _childObjectId;
    operationView.name          = _name;
    operationView.date          = _date;
    operationView.month         = _month;
    operationView.uploadViewController  = self;
    operationView.holdedBy = _holdedBy;
    
    [self addChildViewController:operationView];
    [operationView didMoveToParentViewController:self];
    [self.view addSubview:operationView.view];
    _operationView = operationView.view;
 
    // 画像をタップするとoperationViewControllerが表示される
    UITapGestureRecognizer *openOperationViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openOperationView:)];
    openOperationViewTapGestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:openOperationViewTapGestureRecognizer];
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

-(CGRect) getUploadedImageFrame:(UIImage *) image
{
    float imageViewAspect = _defaultImageViewFrame.size.width/_defaultImageViewFrame.size.height;
    float imageAspect = image.size.width/image.size.height;
    
    // 横長バージョン
    // 枠より、画像の方が横長、枠の縦を縮める
    CGRect frame = _defaultImageViewFrame;
    if (imageAspect >= imageViewAspect){
        frame.size.height = frame.size.width/imageAspect;
    // 縦長バージョン
    // 枠より、画像の方が縦長、枠の横を縮める
    } else {
        frame.size.width = frame.size.height*imageAspect;
    }

    frame.origin.x = (self.view.frame.size.width - frame.size.width)/2;
    frame.origin.y = (self.view.frame.size.height - frame.size.height)/2;

    return frame;
}

- (void)setupCommentView
{
    CommentViewController *commentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CommentViewController"];
    
    commentViewController.childObjectId = _childObjectId;
    commentViewController.name = _name;
    commentViewController.date = _date;
    commentViewController.month = _month;
    commentViewController.uploadViewController = self;

    [self addChildViewController:commentViewController];
    _commentView = commentViewController.view;
    _commentView.hidden = YES; // 最初は隠しておく

    [self.view addSubview:commentViewController.view];
}

@end
