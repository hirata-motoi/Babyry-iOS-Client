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
#import "Logger.h"
#import "ChildProperties.h"
#import "DateUtils.h"
#import "ColorUtils.h"
#import <CustomBadge.h>

@interface ImageToolbarViewController ()

@end

@implementation ImageToolbarViewController
{
    ImageToolbarTrashIcon *trashButtonView;
    ImageToolbarSaveIcon *saveButtonView;
    ImageToolbarCommentIcon *commentButtonView;
    CustomBadge *commentBadge;
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
    
    CGRect frame = CGRectMake(0, 0, 320, 44);
    self.view.frame = frame;
    
    UITapGestureRecognizer *commentViewContainerTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(blockGesture)];
    commentViewContainerTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:commentViewContainerTap];
    
    CGRect buttonFrame = CGRectMake(0, 0, ceil(self.view.frame.size.width/3), self.view.frame.size.height);

    trashButtonView = [ImageToolbarTrashIcon view];
    trashButtonView.frame = buttonFrame;
    _imageTrashView.customView = trashButtonView;
    UITapGestureRecognizer *imageTrashViewTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageTrash)];
    imageTrashViewTap.numberOfTapsRequired = 1;
    [_imageTrashView.customView addGestureRecognizer:imageTrashViewTap];
    
    saveButtonView = [ImageToolbarSaveIcon view];
    saveButtonView.frame = buttonFrame;
    _imageSaveView.customView = saveButtonView;
    UITapGestureRecognizer *imageSaveViewTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageSave)];
    imageSaveViewTap.numberOfTapsRequired = 1;
    [_imageSaveView.customView addGestureRecognizer:imageSaveViewTap];
    
    commentButtonView = [ImageToolbarCommentIcon view];
    commentButtonView.frame = buttonFrame;
    _imageCommentView.customView = commentButtonView;
    UITapGestureRecognizer *imageCommentViewTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageComment)];
    imageCommentViewTap.numberOfTapsRequired = 1;
    [_imageCommentView.customView addGestureRecognizer:imageCommentViewTap];
    
    // 以下マジックナンバー
    _firstSpace.width = -16;
    _secondSpace.width = -9;
    _thirdSpace.width = -9;
    
    // 画像削除と保存はimageInfoが無い場合には表示させない(遅延ロードでimageInfoが取得されてから表示)
    // コメントは日付にひもづくものなのでなくても良い
    if (!_uploadViewController.imageInfo){
        _imageTrashView.customView.hidden = YES;
        _imageSaveView.customView.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    if (_openCommentView) {
        [self imageComment];
    }
    
    [NotificationHistory getNotificationHistoryObjectsByDateInBackground:[PFUser currentUser][@"userId"] withType:@"commentPosted" withChild:_childObjectId date:[NSNumber numberWithInt:[_date intValue]] withBlock:^(NSArray *objects){
        [self setCommentBadge:(int)objects.count];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    [TransitionByPushNotification setCommentViewOpenFlag:NO];
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
    
    trashButtonView.backgroundColor = [ColorUtils getPositiveButtonColor];
    trashButtonView.trashIconImage.image = [UIImage imageNamed:@"TrashWhite"];
    trashButtonView.trashIconLabel.textColor = [UIColor whiteColor];
    
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
    saveButtonView.backgroundColor = [ColorUtils getPositiveButtonColor];
    saveButtonView.saveIconImage.image = [UIImage imageNamed:@"DownloadWhite"];
    saveButtonView.saveIconLabel.textColor = [UIColor whiteColor];
    
    _hud = [MBProgressHUD showHUDAddedTo:_uploadViewController.view animated:YES];
    _hud.labelText = @"画像保存中...";
    
    AWSServiceConfiguration *configuration = [AWSCommon getAWSServiceConfiguration:@"S3"];
    
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:_childObjectId];
    
    AWSS3GetObjectRequest *getRequest = [AWSS3GetObjectRequest new];
    getRequest.bucket = [Config config][@"AWSBucketName"];
    getRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]], _uploadViewController.imageInfo.objectId];
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
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in imageSave : %@", task.error]];
        }
        saveButtonView.backgroundColor = [ColorUtils getGlobalMenuDarkGrayColor];
        saveButtonView.saveIconImage.image = [UIImage imageNamed:@"DownloadGray"];
        saveButtonView.saveIconLabel.textColor = [ColorUtils getDarkGrayColorImageIconString];
        return nil;
    }];
}

- (void)imageComment
{
    // コメントViewの出し入れだけここでやる。表示とかは別Class
    CGRect currentFrame = _commentView.frame;
    if (currentFrame.origin.y <= 20 + 44) {
        // 閉じる
        commentButtonView.backgroundColor = [ColorUtils getGlobalMenuDarkGrayColor];
        commentButtonView.commentIconImage.image = [UIImage imageNamed:@"CommentGray"];
        commentButtonView.commentIconLabel.textColor = [ColorUtils getDarkGrayColorImageIconString];
        [TransitionByPushNotification setCommentViewOpenFlag:NO];
        [TransitionByPushNotification setCurrentDate:@""];
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
        // 開く
        commentButtonView.backgroundColor = [ColorUtils getPositiveButtonColor];
        commentButtonView.commentIconImage.image = [UIImage imageNamed:@"CommentWhite"];
        commentButtonView.commentIconLabel.textColor = [UIColor whiteColor];
        [self disableNotificationHistories];
        [TransitionByPushNotification setCommentViewOpenFlag:YES];
        [TransitionByPushNotification setCurrentDate:_date];
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
                            [commentBadge removeFromSuperview];
                         }];
    }
    
}

// 画像削除確認後に呼ばれる
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // ボタンの色を戻す
    trashButtonView.backgroundColor = [ColorUtils getGlobalMenuDarkGrayColor];
    trashButtonView.trashIconImage.image = [UIImage imageNamed:@"TrashGray"];
    trashButtonView.trashIconLabel.textColor = [ColorUtils getDarkGrayColorImageIconString];
    
    switch (buttonIndex) {
        case 0:
            //１番目のボタンが押されたときの処理を記述する
            break;
        case 1: {
            // imageInfo更新
            PFObject *imageObject = _uploadViewController.imageInfo;
            BOOL isChoosed = ([imageObject[@"bestFlag"] isEqualToString:@"choosed"]) ? YES : NO;
            
            PFACL *removeACL = [PFACL ACL];
            [removeACL setPublicReadAccess:NO];
            [removeACL setPublicWriteAccess:NO];
            [imageObject setACL:removeACL];
            imageObject[@"bestFlag"] = @"removed";
            [imageObject saveInBackground];
            
            // キャッシュから消す
            NSString *childObjectId = _uploadViewController.childObjectId;
            NSString *date = _uploadViewController.date;
            if (isChoosed) {
                [ImageCache removeCache:[NSString stringWithFormat:@"%@/bestShot/thumbnail/%@", childObjectId, date]];
                [ImageCache removeCache:[NSString stringWithFormat:@"%@/bestShot/fullsize/%@", childObjectId, date]];
            }
            // bestShot未確定の場合  ファイル名を指定して消す
            [ImageCache removeCache:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail/%@", childObjectId, date, imageObject.objectId]];
            [ImageCache removeCache:[NSString stringWithFormat:@"%@/candidate/%@/fullsize/%@", childObjectId, date, imageObject.objectId]];
            
            // 画像有る無しのカウントを0にする
            //[_uploadViewController.totalImageNum replaceObjectAtIndex:_uploadViewController.currentRow withObject:[NSNumber numberWithInt:0]];
            
            // この日のnotification historyを削除
            [self removeNotificationHistory:childObjectId withDate:date];
            
            [self.navigationController setNavigationBarHidden:NO];
            [self.navigationController popViewControllerAnimated:YES];
            
            // 削除した画像を反映してリフレッシュ
            NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:n];
            
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

- (void)removeNotificationHistory:(NSString *)childObjectId withDate:(NSString *)date
{
    // 今日 or　昨日であれば画像の数を確認
    // 2日以上前の場合にはこの日のnotificationは全部消す
    if ([[DateUtils getTodayYMD] isEqual:[NSNumber numberWithInt:[date intValue]]] || [[DateUtils getYesterdayYMD] isEqual:[NSNumber numberWithInt:[date intValue]]]) {
        // アップされている枚数をキャッシュの数で確認する
        NSArray *cacheArray = [[NSMutableArray alloc] initWithArray:[ImageCache getListOfMultiUploadCache:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", _childObjectId, date]]];
        if ([cacheArray count] == 0) {
            [NotificationHistory removeNotificationsWithChild:childObjectId withDate:date withStatus:nil];
        } else {
            // 厳密には消した画像に対応するnotificationを消さないといけないけど
            [NotificationHistory removeNotificationsWithChild:childObjectId withDate:date withStatus:@"ready"];
        }
    } else {
        [NotificationHistory removeNotificationsWithChild:childObjectId withDate:date withStatus:nil];
    }
}

- (void)disableNotificationHistories
{
    NSArray *notificationTypes = @[@"imageUploaded", @"bestShotChanged", @"commentPosted", @"requestPhoto"];
    [NotificationHistory disableDisplayedNotificationsWithUser:[PFUser currentUser][@"userId"] withChild:_childObjectId withDate:_date withType:notificationTypes];
}

- (void)setCommentBadge:(int)badgeNumber
{
    if (badgeNumber < 1) {
        [commentBadge removeFromSuperview];
        return;
    } else if (badgeNumber > 99) {
        badgeNumber = 99;
    }
    commentBadge = [CustomBadge customBadgeWithString:[NSString stringWithFormat:@"%d", badgeNumber] withScale:0.8];
    CGRect badgeFrame = commentBadge.frame;
    badgeFrame.size.width = 20;
    badgeFrame.size.height = 20;
    badgeFrame.origin.x = commentButtonView.frame.size.width - 22;
    badgeFrame.origin.y = 0;
    commentBadge.frame = badgeFrame;
    [commentButtonView addSubview:commentBadge];
}

@end
