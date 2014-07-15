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
    
    [self.closeUploadViewControllerButton addTarget:self action:@selector(closeUploadViewController) forControlEvents:UIControlEventTouchUpInside];
    [self.openPhotoLibraryButton addTarget:self action:@selector(openPhotoLibrary) forControlEvents:UIControlEventTouchUpInside];
    [self.openCommentViewButton addTarget:self action:@selector(openCommentView) forControlEvents:UIControlEventTouchUpInside];
    [self.openTagViewButton addTarget:self action:@selector(openTagView) forControlEvents:UIControlEventTouchUpInside];
    

    [self setStyle];
    
    // day
    NSString *dd = [_date substringWithRange:NSMakeRange(6, 2)];
    _dayLabel.text = [NSString stringWithFormat:@"%@", dd];
    
    // year & month
    NSString *yyyy = [_month substringToIndex:4];
    NSString *mm = [_month substringWithRange:NSMakeRange(4, 2)];
    _yearMonthLabel.text = [NSString stringWithFormat:@"%@/%@", yyyy, mm];
    
    // name
    _childNameLabel.text = _name;
    
    // タップでoperationViewを非表示にする
    UITapGestureRecognizer *hideOperationViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideOperationView:)];
    hideOperationViewTapGestureRecognizer.numberOfTapsRequired = 1;
    self.view.userInteractionEnabled = YES;
    [self.view addGestureRecognizer:hideOperationViewTapGestureRecognizer];

    // commentViewを生成
    CommentViewController *commentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CommentViewController"];
    
    commentViewController.childObjectId = _childObjectId;
    commentViewController.name = _name;
    commentViewController.date = _date;
    commentViewController.month = _month;
    
    [self addChildViewController:commentViewController];
    _commentView = commentViewController.view;
    _commentView.hidden = YES; // 最初は隠しておく
    
    [self.view addSubview:commentViewController.view];
    [self setupTagEditView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)closeUploadViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openPhotoLibrary
{
    // インタフェース使用可能なら
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
	{
        // UIImageControllerの初期化
		UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
		[imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
		[imagePickerController setAllowsEditing:NO];
		[imagePickerController setDelegate:self];
		
        [self presentViewController:imagePickerController animated:YES completion: nil];
	}
	else
	{
		NSLog(@"photo library invalid.");
	}
}

- (void)openCommentView
{
    _commentView.hidden = FALSE;
}

- (void)setupTagEditView
{
    TagEditViewController *tagEditViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TagEditViewController"];
    tagEditViewController.imageInfo = self.uploadedViewController.imageInfo;
    
    _tagEditView = tagEditViewController.view;
    _tagEditView.hidden = YES;
    _tagEditView.frame = CGRectMake(10, 0, 320, 500);
    [self addChildViewController:tagEditViewController];
    [self.view addSubview:_tagEditView];
}

- (void)openTagView
{
    _tagEditView.hidden = NO;
}

- (void)hideOperationView:(id)sender
{
    self.view.hidden = YES;
}



- (void)setStyle
{
    _openPhotoLibraryButton.layer.cornerRadius = 20;
    _openPhotoLibraryButton.clipsToBounds = YES;
    _openCommentViewButton.layer.cornerRadius = 20;
    _openCommentViewButton.clipsToBounds = YES;
    _openTagViewButton.layer.cornerRadius = 20;
    _openTagViewButton.clipsToBounds = YES;
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
    self.uploadedViewController.uploadedImageView.frame = [self getUploadedImageFrame:resizedImage];
    [self.uploadedViewController.uploadedImageView setImage:resizedImage];
    
    NSLog(@"Make PFFile");
    NSData *imageData = [[NSData alloc] init];
    // PNGは透過しないとだめなのでやる
    // その他はJPG
    // TODO 画像圧縮率
    if ([fileExtension isEqualToString:@"PNG"]) {
        imageData = UIImagePNGRepresentation(resizedImage);
    } else {
        imageData = UIImageJPEGRepresentation(resizedImage, 0.7f);
    }
    NSLog(@"resize %f %f", originalImage.size.width, resizedImage.size.width);

    PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@%@", _childObjectId, _date] data:imageData];
    
    // Parseに既に画像があるかどうかを確認
    PFQuery *imageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
    [imageQuery whereKey:@"imageOf" equalTo:_childObjectId];
    [imageQuery whereKey:@"date" equalTo:[NSString stringWithFormat:@"D%@", _date]];
    [imageQuery whereKey:@"bestFlag" equalTo:@"choosed"];
    
    NSArray *imageArray = [imageQuery findObjects];
    // imageArrayが一つ以上あったら(objectId指定だから一つしか無いはずだけど)上書き
    if ([imageArray count] > 1) {
        NSLog(@"これはあり得ないエラー");
    } else if ([imageArray count] == 1) {
        //NSLog(@"image objectId%@", imageArray[0]);
        imageArray[0][@"imageFile"] = imageFile;
        //ほんとはいらないけど念のため
        imageArray[0][@"bestFlag"] = @"choosed";
        [imageArray[0] saveInBackground];
    // 一つもないなら新たに追加
    } else {
        NSLog(@"Insert To Parse");
        PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
        childImage[@"imageFile"] = imageFile;
        // D(文字)つけないとwhere句のfieldに指定出来ないので付ける
        childImage[@"date"] = [NSString stringWithFormat:@"D%@", _date];
        childImage[@"imageOf"] = _childObjectId;
        childImage[@"bestFlag"] = @"choosed";
        [childImage saveInBackground];
    }
    
    // Cache set use thumbnail (フォトライブラリにあるやつは正方形になってるし使わない)
    UIImage *thumbImage = [ImageCache makeThumbNail:resizedImage];
    [ImageCache setCache:[NSString stringWithFormat:@"%@%@thumb", _childObjectId, _date] image:UIImageJPEGRepresentation(thumbImage, 0.7f)];
    
    // topのviewに設定する
    // このやり方でいいのかは不明 (MultiUploadViewControllerと同じ処理、ここなおすならそっちも直す)
    ViewController *pvc = (ViewController *)[self presentingViewController];
    if (pvc) {
        int childIndex = pvc.currentPageIndex;
        for (int i = 0; i < [[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"date"] count]; i++){
            if ([[[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"date"] objectAtIndex:i] isEqualToString:_date]) {
                //NSLog(@"%@",[[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"date"] objectAtIndex:i]);
                //NSLog(@"%@",[[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"thumbImages"] objectAtIndex:i]);
                [[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"thumbImages"] replaceObjectAtIndex:i withObject:thumbImage];
                //NSLog(@"%@",[[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"orgImages"] objectAtIndex:i]);
                [[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"orgImages"] replaceObjectAtIndex:i withObject:resizedImage];
            }
        }
    }
    
    NSLog(@"saved");
}

-(CGRect) getUploadedImageFrame:(UIImage *) image
{
    float imageViewAspect = self.uploadedViewController.defaultImageViewFrame.size.width/self.uploadedViewController.defaultImageViewFrame.size.height;
    float imageAspect = image.size.width/image.size.height;
    
    // 横長バージョン
    // 枠より、画像の方が横長、枠の縦を縮める
    CGRect frame = self.uploadedViewController.defaultImageViewFrame;
    if (imageAspect >= imageViewAspect){
        frame.size.height = frame.size.width/imageAspect;
    // 縦長バージョン
    // 枠より、画像の方が縦長、枠の横を縮める
    } else {
        frame.size.width = frame.size.height*imageAspect;
    }

    frame.origin.x = (self.view.frame.size.width - frame.size.width)/2;
    frame.origin.y = (self.view.frame.size.height - frame.size.height)/2;

    NSLog(@"frame %@", NSStringFromCGRect(frame));
    return frame;
    
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
