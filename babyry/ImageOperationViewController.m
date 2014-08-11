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
    NSLog(@"setupCommentView");
    CommentViewController *commentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CommentViewController"];
    commentViewController.childObjectId = _childObjectId;
    commentViewController.name = _name;
    commentViewController.date = _date;
    commentViewController.month = _month;
    commentViewController.imageInfo = _imageInfo;
    _commentView = commentViewController.view;
    _commentView.hidden = NO;
    _commentView.frame = CGRectMake(self.view.frame.size.width - 50, self.view.frame.size.height - 50, self.view.frame.size.width, self.view.frame.size.height -44 -20);
    [self addChildViewController:commentViewController];
    [self.view addSubview:_commentView];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    // 拡張子取得
    NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    NSString *fileExtension = [[assetURL path] pathExtension];
    
    // オリジナルイメージ取得
	UIImage *originalImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];

    // リサイズ
    UIImage *resizedImage = [ImageTrimming resizeImageForUpload:originalImage];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    // ImageViewにセット
    self.uploadViewController.uploadedImageView.frame = [self getUploadedImageFrame:resizedImage];
    [self.uploadViewController.uploadedImageView setImage:resizedImage];
    
    NSData *imageData = [[NSData alloc] init];
    NSString *imageType = [[NSString alloc] init];
    // PNGは透過しないとだめなのでやる
    // その他はJPG
    // TODO 画像圧縮率
    if ([fileExtension isEqualToString:@"PNG"]) {
        imageData = UIImagePNGRepresentation(resizedImage);
        imageType = @"image/png";
    } else {
        imageData = UIImageJPEGRepresentation(resizedImage, 0.7f);
        imageType = @"image/jpeg";
    }

    //PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@%@", _childObjectId, _date] data:imageData];
    
    // Parseに既に画像があるかどうかを確認
    PFQuery *imageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", [_child[@"childImageShardIndex"] integerValue]]];
    [imageQuery whereKey:@"imageOf" equalTo:_childObjectId];
    [imageQuery whereKey:@"date" equalTo:[NSString stringWithFormat:@"D%@", _date]];
    [imageQuery whereKey:@"bestFlag" equalTo:@"choosed"];
    
    NSArray *imageArray = [imageQuery findObjects];
    // imageArrayが一つ以上あったら(objectId指定だから一つしか無いはずだけど)上書き
    if ([imageArray count] > 1) {
        NSLog(@"これはあり得ないエラー");
    } else if ([imageArray count] == 1) {
        PFObject *tmpImageObject = imageArray[0];
        //imageArray[0][@"imageFile"] = imageFile;
        //ほんとはいらないけど念のため
        imageArray[0][@"bestFlag"] = @"choosed";
        [imageArray[0] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (succeeded) {
                NSLog(@"save to s3");
                [[AWSS3Utils putObject:
                  [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", [_child[@"childImageShardIndex"] integerValue]], tmpImageObject.objectId]
                             imageData:imageData
                             imageType:imageType] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                    if (task.error) {
                        NSLog(@"save error to S3 %@", task.error);
                    }
                    return nil;
                }];
            }
        }];
    // 一つもないなら新たに追加
    } else {
        PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%ld", [_child[@"childImageShardIndex"] integerValue]]];
        //childImage[@"imageFile"] = imageFile;
        // D(文字)つけないとwhere句のfieldに指定出来ないので付ける
        childImage[@"date"] = [NSString stringWithFormat:@"D%@", _date];
        childImage[@"imageOf"] = _childObjectId;
        childImage[@"bestFlag"] = @"choosed";
        [childImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (succeeded) {
                NSLog(@"save to s3");
                [[AWSS3Utils putObject:
                  [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", [_child[@"childImageShardIndex"] integerValue]], childImage.objectId]
                             imageData:imageData
                             imageType:imageType] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                    if (task.error) {
                        NSLog(@"save error to S3 %@", task.error);
                    }
                    return nil;
                }];
            }
        }];
    }
    
    // Cache set use thumbnail (フォトライブラリにあるやつは正方形になってるし使わない)
    UIImage *thumbImage = [ImageCache makeThumbNail:resizedImage];
    [ImageCache setCache:[NSString stringWithFormat:@"%@%@thumb", _childObjectId, _date] image:UIImageJPEGRepresentation(thumbImage, 0.7f)];
    
    [PushNotification sendInBackground:@"imageUpload" withOptions:nil];
    NSLog(@"saved");
}

-(CGRect) getUploadedImageFrame:(UIImage *) image
{
    float imageViewAspect = self.uploadViewController.defaultImageViewFrame.size.width/self.uploadViewController.defaultImageViewFrame.size.height;
    float imageAspect = image.size.width/image.size.height;
    
    // 横長バージョン
    // 枠より、画像の方が横長、枠の縦を縮める
    CGRect frame = self.uploadViewController.defaultImageViewFrame;
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

// NavigationController(self.navigationController)を使うとPageViewControllerがずれるため
// self.navigationControllerは非表示にして、自前でnavigationを作る
- (void)setupNavigation
{
    [self setColorForNavigation];
   
    // back button
    UIButton *backButton = [UIButton buttonWithType:101];
    [backButton addTarget:self action:@selector(doBack) forControlEvents:UIControlEventTouchUpInside]; [backButton setTitle:@"戻る" forState:UIControlStateNormal];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    _navbarItem.leftBarButtonItem = backItem;
                                                 
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
