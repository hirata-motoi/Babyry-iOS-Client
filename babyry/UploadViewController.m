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
#import "ImageTrimming.h"
#import "CommentViewController.h"
#import "Navigation.h"
#import "AWSCommon.h"
#import "NotificationHistory.h"
#import "Config.h"
#import "Logger.h"
#import "ChildProperties.h"
#import "DateUtils.h"
#import "ImageCache.h"

@interface UploadViewController ()

@end

@implementation UploadViewController
{
    BOOL openCommentView;
}

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
    
    _configuration = [AWSCommon getAWSServiceConfiguration:@"S3"];
    
    _defaultImageViewFrame = _uploadedImageView.frame;
    
    if (_uploadedImage) {
        CGRect imageRect = [self getUploadedImageFrame:_uploadedImage];
        _uploadedImageView.frame = CGRectMake( (self.view.frame.size.width - imageRect.size.width)/2, (self.view.frame.size.height - imageRect.size.height)/2, imageRect.size.width, imageRect.size.height);
        _uploadedImageView.image = _uploadedImage;
    }
    
    if ([[TransitionByPushNotification getInfo][@"event"] isEqualToString:@"commentPosted"]) {
        openCommentView = YES;
        [TransitionByPushNotification removeInfo];
    }
    [self setupOperationView];
    
    // zoom
    _scrollView.minimumZoomScale = 1.0f;
    _scrollView.maximumZoomScale = 5.0f;
    _scrollView.delegate = self;
    
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:_childObjectId];
    
    // Parseからちゃんとしたサイズの画像を取得
    // ImagePageViewControllerからimageInfoをもらう
    // Push経由で即このviewControllerに来た場合にはimageInfoが無いので、Parseの情報から組み立てる
    if (_imageInfo) {
        AWSS3GetObjectRequest *getRequest = [AWSS3GetObjectRequest new];
        getRequest.bucket = [Config config][@"AWSBucketName"];
        getRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]], _imageInfo.objectId];
        getRequest.responseCacheControl = @"no-cache";
        AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:_configuration];
        [[awsS3 getObject:getRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
            if (!task.error && task.result) {
                AWSS3GetObjectOutput *getResult = (AWSS3GetObjectOutput *)task.result;
                UIImage *s3Image = [UIImage imageWithData:getResult.body];
                _uploadedImageView.image = s3Image;
                CGRect imageRect = [self getUploadedImageFrame:s3Image];
                _uploadedImageView.frame = CGRectMake( (self.view.frame.size.width - imageRect.size.width)/2, (self.view.frame.size.height - imageRect.size.height)/2, imageRect.size.width, imageRect.size.height);
                [self updateThumbmail:_imageInfo[@"date"] objectId:_imageInfo.objectId imageData:getResult.body bestFlag:_imageInfo[@"bestFlag"]];
            } else {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getRequest in UploadViewController : %@", task.error]];
            }
            return nil;
        }];
        [self setupOperationView];
    } else {
        MBProgressHUD *hud;
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"画像ダウンロード中";
        PFQuery *originalImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]]];
        originalImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
        [originalImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
        [originalImageQuery whereKey:@"date" equalTo:[NSNumber numberWithInteger:[_date integerValue]]];
        [originalImageQuery orderByDescending:@"updatedAt"];
        [originalImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if ([objects count] == 0) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"画像がありません"
                                                                message:[NSString stringWithFormat:@"%@の画像が存在しません、パートナーにより削除されている可能性があります。トップに戻ってご確認ください。", _date]
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil
                                      ];
                [alert show];
                return;
            }
            if ([objects count] > 0) {
                PFObject *object;
                for (PFObject *tmpObject in objects) {
                    if ([tmpObject[@"bestFlag"] isEqualToString:@"choosed"]) {
                        object = tmpObject;
                        break;
                    }
                }
                
                // Pushで呼ばれた場合のパターン
                // 1. imageUpload : imageUploadでUploadViewControllerが呼ばれるのは2日以上前なのでかならずbestFlagがたっている
                // 2. commentPosted : commentPostedで表示するUploadViewController(CommentView付き)で表示するのは、bestShotがあればbestShot、無ければアップロードされている中の最新のものとする
                //                    ただし、1に書いてある通りbestShotが無いのは、2以内に限られる
                
                if (!object) {
                    // 正常系の動作であれば要らない判定、過去の写真が削除されたりした場合にここに入る事があるかも
                    if([_date isEqualToString:[[DateUtils getTodayYMD] stringValue]] || [_date isEqualToString:[[DateUtils getYesterdayYMD] stringValue]]) {
                        // 1. Pushで飛んでくるとここに来る時がある。
                        //    複数アップロードされて、かつ、コメントが付けられた場合にBSが決まっていなくても何かの画像を出さないと行けないので配列の一番最初の画像を入れてあげる。
                        object = [objects objectAtIndex:0];
                    } else {
                        // 2. そうでない場合には、画像が削除されているので、アラートを出してあげる。
                        //    お知らせから飛んでくる場合にここがあり得るので、notificationHistoryも消してあげる。
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"画像がありません"
                                                                        message:[NSString stringWithFormat:@"%@の画像が存在しません、パートナーにより削除されている可能性があります。トップに戻ってご確認ください。", _date]
                                                                       delegate:nil
                                                              cancelButtonTitle:nil
                                                              otherButtonTitles:@"OK", nil
                                              ];
                        [alert show];
                        [NotificationHistory removeNotificationsWithChild:_childObjectId withDate:_date withStatus:nil];
                        return;
                    }
                }
                
                AWSS3GetObjectRequest *getRequest = [AWSS3GetObjectRequest new];
                getRequest.bucket = [Config config][@"AWSBucketName"];
                getRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]], object.objectId];
                getRequest.responseCacheControl = @"no-cache";
                AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:_configuration];
                [[awsS3 getObject:getRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                    if (!task.error && task.result) {
                        AWSS3GetObjectOutput *getResult = (AWSS3GetObjectOutput *)task.result;
                        UIImage *s3Image = [UIImage imageWithData:getResult.body];
                        _uploadedImageView.image = s3Image;
                        CGRect imageRect = [self getUploadedImageFrame:s3Image];
                        _uploadedImageView.frame = CGRectMake( (self.view.frame.size.width - imageRect.size.width)/2, (self.view.frame.size.height - imageRect.size.height)/2, imageRect.size.width, imageRect.size.height);
                    } else {
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getRequest in UploadViewController(new image) : %@", task.error]];
                    }
                    [hud hide:YES];
                    return nil;
                }];
                _imageInfo = object;
                return;
            }
            if (error) {
                [hud hide:YES];
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in findObject in UploadViewController(new image) : %@", error]];
            }
        }];
    }
    [self disableNotificationHistories];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveRemoteNotification) name:@"didReceiveRemoteNotification" object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // super
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidReceiveRemoteNotification
{
    [self viewDidAppear:YES];
}

- (void)closeView:(id)sender
{
    _operationView.hidden = YES;
}

- (void)setupOperationView
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
    _operationViewController.uploadedImage = _uploadedImage;
    _operationViewController.uploadViewController  = self;
    _operationViewController.holdedBy = _holdedBy;
    _operationViewController.imageInfo = _imageInfo;
    _operationViewController.fromMultiUpload = _fromMultiUpload;
    _operationViewController.imageFrame = _uploadedImageView.frame;
    _operationViewController.bestImageIndexArray = _bestImageIndexArray;
    _operationViewController.pageIndex = _pageIndex;
    _operationViewController.myRole = _myRole;
    _operationViewController.indexPath = _indexPath;
    
    // push通知でここに来た場合には、コメントを開く為のフラグをたてる
    if (openCommentView) {
        _operationViewController.openCommentView = YES;
    } else {
        _operationViewController.openCommentView = NO;
    }
    
    [self addChildViewController:_operationViewController];
    [_operationViewController didMoveToParentViewController:self];
    [self.view addSubview:_operationViewController.view];
    _operationView = _operationViewController.view;
}

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

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    CGRect rect = view.frame;
    if (rect.size.height < scrollView.frame.size.height) {
        rect.origin.y = (scrollView.frame.size.height - rect.size.height)/2;
    } else {
        rect.origin.y = 0;
    }
    view.frame = rect;
}

- (void)disableNotificationHistories
{
    NSArray *notificationTypes = @[@"imageUploaded", @"bestShotChanged", @"requestPhoto"];
    [NotificationHistory disableDisplayedNotificationsWithUser:[PFUser currentUser][@"userId"] withChild:_childObjectId withDate:_date withType:notificationTypes];
}

- (void)updateThumbmail:(NSNumber *)date objectId:(NSString *)objectId imageData:(NSData *)imageData bestFlag:(NSString *) bestFlag
{
    // 今日or昨日の場合には、candidateに突っ込む
    if ([date isEqualToNumber:[DateUtils getYesterdayYMD]] || [date isEqualToNumber:[DateUtils getTodayYMD]]) {
        [ImageCache setCache:objectId
                       image:UIImageJPEGRepresentation([ImageCache makeThumbNail:[UIImage imageWithData:imageData]], 0.7f)
                         dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", _childObjectId, date]
         ];
        [ImageCache setCache:objectId
                       image:imageData
                         dir:[NSString stringWithFormat:@"%@/candidate/%@/fullsize", _childObjectId, date]
         ];
    }
    
    // bestFlag = choosedの場合にはbestShotに突っ込む
    if ([bestFlag isEqualToString:@"choosed"]) {
        [ImageCache setCache:[date stringValue]
                       image:UIImageJPEGRepresentation([ImageCache makeThumbNail:[UIImage imageWithData:imageData]], 0.7f)
                         dir:[NSString stringWithFormat:@"%@/bestShot/thumbnail", _childObjectId]
         ];
    }
    
    // 今日 かつ bestshotならfullsizeにする
    if ([date isEqualToNumber:[DateUtils getTodayYMD]] && [bestFlag isEqualToString:@"choosed"]) {
        [ImageCache setCache:[date stringValue]
                       image:imageData
                         dir:[NSString stringWithFormat:@"%@/bestShot/fullsize", _childObjectId]
         ];
    }
}

@end
