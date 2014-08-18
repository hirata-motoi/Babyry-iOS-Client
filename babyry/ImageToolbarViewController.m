//
//  ImageToolbarViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/11.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageToolbarViewController.h"
#import "ImageToolbarTrashIcon.h"
#import "ImageToolbarSaveIcon.h"
#import "ImageToolbarCommentIcon.h"
#import "Badge.h"
#import "NotificationHistory.h"
#import "Config.h"

@interface ImageToolbarViewController ()

@end

@implementation ImageToolbarViewController

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
    
    CGRect frame = CGRectMake(0, 0, 320, 44);
    self.view.frame = frame;
    
    UITapGestureRecognizer *commentViewContainerTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(blockGesture)];
    commentViewContainerTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:commentViewContainerTap];
    
    ImageToolbarTrashIcon *trashView = [ImageToolbarTrashIcon view];
    _imageTrashView.customView = trashView;
    UITapGestureRecognizer *imageTrashViewTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageTrash)];
    imageTrashViewTap.numberOfTapsRequired = 1;
    [_imageTrashView.customView addGestureRecognizer:imageTrashViewTap];
    
    ImageToolbarSaveIcon *saveView = [ImageToolbarSaveIcon view];
    _imageSaveView.customView = saveView;
    UITapGestureRecognizer *imageSaveViewTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageSave)];
    imageSaveViewTap.numberOfTapsRequired = 1;
    [_imageSaveView.customView addGestureRecognizer:imageSaveViewTap];
    
    ImageToolbarCommentIcon *commentView = [ImageToolbarCommentIcon view];
    _imageCommentView.customView = commentView;
    UITapGestureRecognizer *imageCommentViewTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageComment)];
    imageCommentViewTap.numberOfTapsRequired = 1;
    [_imageCommentView.customView addGestureRecognizer:imageCommentViewTap];
    // commentアイコンにbadgeをつける
    if (_notificationHistoryByDay[@"commentPosted"] && [_notificationHistoryByDay[@"commentPosted"] count] > 0) {
        NSInteger count = [_notificationHistoryByDay[@"commentPosted"] count];
        [self showCommentBadge:count];
    }                    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)blockGesture
{
    // do nothing
}

- (void)imageTrash
{
    // 大きくなるようなら別Classに移動
    // 実際には消さずに、ACLで誰にも見れない設定にする & キャッシュ消す & bestFlagをとりあえずremovedにしておいてみる
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"確認"
                          message:@"削除してもよろしいですか？"
                          delegate:self
                          cancelButtonTitle:@"いいえ"
                          otherButtonTitles:@"はい", nil];
    [alert show];
}

- (void)imageSave
{
    // 大きくなるようなら別Classに移動
    
    _hud = [MBProgressHUD showHUDAddedTo:_uploadViewController.view animated:YES];
    _hud.labelText = @"画像保存中...";
    
    AWSServiceConfiguration *configuration = [AWSS3Utils getAWSServiceConfiguration];
    
    AWSS3GetObjectRequest *getRequest = [AWSS3GetObjectRequest new];
    getRequest.bucket = [Config getBucketName];
    getRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]], _uploadViewController.imageInfo.objectId];
    // no-cache必須
    getRequest.responseCacheControl = @"no-cache";
    AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
    
    [[awsS3 getObject:getRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        if(!task.error && task.result) {
            AWSS3GetObjectOutput *getResult = (AWSS3GetObjectOutput *)task.result;
            NSData *saveData = getResult.body;
            UIImage *saveImage = [UIImage imageWithData:saveData];
            UIImageWriteToSavedPhotosAlbum(saveImage, self, @selector(savingImageIsFinished:didFinishSavingWithError:contextInfo:), nil);
        } else {
            [_hud hide:YES];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"エラー"
                                                            message:@"画像の保存に失敗しました。"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil
                                  ];
            
            [alert show];
        }
        return nil;
    }];
}

- (void)imageComment
{
    // コメントViewの出し入れだけここでやる。表示とかは別Class
    CGRect currentFrame = _commentView.frame;
    if (currentFrame.origin.y <= 20 + 44) {
        currentFrame.origin.y = self.parentViewController.view.frame.size.height;
        currentFrame.origin.x = self.view.frame.size.width;

        [UIView animateWithDuration:0.3
                              delay:0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _commentView.frame = currentFrame;
                         }
                         completion:^(BOOL finished){
                         }];
    } else {
        currentFrame.origin.y = 20 + 44;
        currentFrame.origin.x = 0;
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _commentView.frame = currentFrame;
                         }
                         completion:^(BOOL finished){
                             // 未読commentのバッヂを消す
                             if (_notificationHistoryByDay[@"commentPosted"] && [_notificationHistoryByDay[@"commentPosted"] count] > 0) {
                                 for (PFObject *notification in _notificationHistoryByDay[@"commentPosted"]) {
                                     [NotificationHistory disableDisplayedNotificationsWithObject:notification];
                                 }
                                 //[_notificationHistoryByDay[@"commentPosted"] removeAllObjects];
                                 PFObject *obj = [[PFObject alloc]initWithClassName:@"NotificationHistory"];
                                 [_notificationHistoryByDay[@"commentPosted"] addObject:obj];
                                 [_commentBadge removeFromSuperview];
                             }
                         }];
    }
    
}

// 画像削除確認後に呼ばれる
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
            //１番目のボタンが押されたときの処理を記述する
            break;
        case 1: {
            // imageInfo更新
            PFObject *imageObject = _uploadViewController.imageInfo;
            PFACL *removeACL = [PFACL ACL];
            [removeACL setPublicReadAccess:NO];
            [removeACL setPublicWriteAccess:NO];
            [imageObject setACL:removeACL];
            imageObject[@"bestFlag"] = @"removed";
            [imageObject saveInBackground];
            
            // キャッシュから消す (${childId}${ymd}thumb)
            [ImageCache removeCache:[NSString stringWithFormat:@"%@%@thumb", _uploadViewController.childObjectId, _uploadViewController.date]];
            
            // 画像有る無しのカウントを0にする
            [_uploadViewController.totalImageNum replaceObjectAtIndex:_uploadViewController.currentRow withObject:[NSNumber numberWithInt:0]];
            
            [self.navigationController setNavigationBarHidden:NO];
            [self.navigationController popViewControllerAnimated:YES];
            
            break;
        }
        default:
            break;
    }
    
}

// 画像保存完了
- (void) savingImageIsFinished:(UIImage *)_image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    [_hud hide:YES];
    
    if(error){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"エラー"
                                                        message:@"画像の保存に失敗しました。"
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil
                              ];
        
        [alert show];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"画像の保存が完了しました"
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
    }
}

- (void)showCommentBadge:(NSInteger)count
{
    _commentBadge = [Badge badgeViewWithType:nil withCount:count];
    CGRect rect = _commentBadge.frame;
    rect.origin.x = _imageCommentView.customView.frame.size.width - rect.size.width/2;
    rect.origin.y = rect.size.height/2 * -1;
    _commentBadge.frame = rect;
    [_imageCommentView.customView addSubview:_commentBadge];
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
