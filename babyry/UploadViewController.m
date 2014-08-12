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
#import "TagEditViewController.h"
#import "ImageTrimming.h"
#import "CommentViewController.h"
#import "Navigation.h"
#import "AWSS3Utils.h"

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
    
    _configuration = [AWSS3Utils getAWSServiceConfiguration];
    
    _defaultImageViewFrame = _uploadedImageView.frame;
    
    _uploadedImageView.frame = [self getUploadedImageFrame:_uploadedImage];
    _uploadedImageView.image = _uploadedImage;
    
    BOOL __block isPreload = YES;
    [self setupOperationView:isPreload];
    
    // zoom
    _scrollView.minimumZoomScale = 1.0f;
    _scrollView.maximumZoomScale = 3.0f;
    _scrollView.delegate = self;
    
    // Parseからちゃんとしたサイズの画像を取得
    // ImagePageViewControllerからimageInfoをもらう
    // 万が一imageInfoが空だった時のことを考えて、一応、位置から組み立てるロジックも入れておくが、ImagePageViewController側でNoImageを省くようになったら不要になる(TODO)。
    if (_imageInfo) {
        [[AWSS3Utils getObject:[NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%@", _month], _imageInfo.objectId] configuration:_configuration] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
            if (!task.error && task.result) {
                AWSS3GetObjectOutput *getResult = (AWSS3GetObjectOutput *)task.result;
                _uploadedImageView.image = [UIImage imageWithData:getResult.body];
            } else {
                [_imageInfo[@"imageFile"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error){
                    if(!error){
                        _uploadedImageView.image = [UIImage imageWithData:data];
                    }
                }];
            }
            return nil;
        }];
        isPreload = NO;
        [self setupOperationView:isPreload];
    } else {
        PFQuery *originalImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
        originalImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
        [originalImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
        [originalImageQuery whereKey:@"bestFlag" equalTo:@"choosed"];
        [originalImageQuery whereKey:@"date" equalTo:[NSString stringWithFormat:@"D%@", _date]];
        [originalImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if ([objects count] > 0) {
                PFObject * object = [objects objectAtIndex:0];
                [[AWSS3Utils getObject:[NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%@", _month], object.objectId] configuration:_configuration] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                    if (!task.error && task.result) {
                        AWSS3GetObjectOutput *getResult = (AWSS3GetObjectOutput *)task.result;
                        _uploadedImageView.image = [UIImage imageWithData:getResult.body];
                    } else {
                        [object[@"imageFile"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error){
                            if(!error){
                                _uploadedImageView.image = [UIImage imageWithData:data];
                            }
                        }];
                    }
                    return nil;
                }];
                _imageInfo = object;
                isPreload = NO;
                [self setupOperationView:isPreload];
            }
        }];
    }
}

- (void)openOperationView:(id)sender
{
    _operationView.hidden = NO;
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
    [super viewDidAppear:animated];
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

- (void)setupOperationView:(BOOL) isPreload
{
    if (_operationViewController) {
        //既にあったら一度消す
        [_operationViewController removeFromParentViewController];
        [_operationView removeFromSuperview];
    } else {
        // 画像をタップするとoperationViewControllerが表示される
        UITapGestureRecognizer *openOperationViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openOperationView:)];
        openOperationViewTapGestureRecognizer.numberOfTapsRequired = 1;
        [self.view addGestureRecognizer:openOperationViewTapGestureRecognizer];
    }
    
    _operationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"OperationView"];
    _operationViewController.childObjectId = _childObjectId;
    _operationViewController.name          = _name;
    _operationViewController.date          = _date;
    _operationViewController.month         = _month;
    _operationViewController.uploadViewController  = self;
    _operationViewController.holdedBy = _holdedBy;
    _operationViewController.imageInfo = _imageInfo;
    _operationViewController.isPreload = isPreload;
    _operationViewController.child = _child;
    
    [self addChildViewController:_operationViewController];
    [_operationViewController didMoveToParentViewController:self];
    [self.view addSubview:_operationViewController.view];
    _operationView = _operationViewController.view;
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

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _uploadedImageView;
}

@end
