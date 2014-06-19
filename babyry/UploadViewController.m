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
    
    float imageViewAspect = _uploadedImageView.frame.size.width/_uploadedImageView.frame.size.height;
    float imageAspect = _uploadedImage.size.width/_uploadedImage.size.height;
    //NSLog(@"aspect %f", imageViewAspect);
    
    // 横長バージョン
    // 枠より、画像の方が横長、枠の縦を縮める
    if (imageAspect >= imageViewAspect){
        CGRect frame = _uploadedImageView.frame;
        frame.size.height = frame.size.width/imageAspect;
        _uploadedImageView.frame = frame;
    // 縦長バージョン
    // 枠より、画像の方が縦長、枠の横を縮める
    } else {
        CGRect frame = _uploadedImageView.frame;
        frame.size.width = frame.size.height*imageAspect;
        _uploadedImageView.frame = frame;
    }
    
    // set uploadedImage
    //NSLog(@"_uploadedImage %f %f", _uploadedImage.size.width, _uploadedImage.size.height);
    //NSLog(@"_uploadedImageView %f %f", _uploadedImageView.frame.size.width, _uploadedImageView.frame.size.height);
    CGRect frame = _uploadedImageView.frame;
    frame.origin.x = (self.view.frame.size.width - _uploadedImageView.frame.size.width)/2;
    frame.origin.y = (self.view.frame.size.height - _uploadedImageView.frame.size.height)/2;
    _uploadedImageView.frame = frame;
    _uploadedImageView.image = _uploadedImage;
    
    // set label
    NSString *yyyy = [_month substringToIndex:4];
    NSString *mm = [_month substringWithRange:NSMakeRange(4, 2)];
    NSString *dd = [_date substringWithRange:NSMakeRange(6, 2)];
    _uploadMonthLabel.text = [NSString stringWithFormat:@"%@/%@", yyyy, mm];
    _uploadDateLabel.text = [NSString stringWithFormat:@"%@", dd];
    _uploadNameLabel.text = _name;
    
    // set button shape
    _openPhotoLibraryLabel.layer.cornerRadius = _openPhotoLibraryLabel.frame.size.height/2;
    _uploadViewBackLabel.layer.cornerRadius = _uploadViewBackLabel.frame.size.height/2;
    _uploadViewCommentLabel.layer.cornerRadius = _uploadViewCommentLabel.frame.size.height/2;
    
    // get pageIndex, imageIndex
    NSLog(@"received childObjectId:%@ month:%@ date:%@ image:%@", _childObjectId, _month, _date, _uploadedImageView.image);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)openPhotoLibrary:(UIButton *)sender {
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

- (IBAction)uploadViewBackButton:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)uploadViewCommentButton:(UIButton *)sender {
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // オリジナル画像
    NSLog(@"imagePickerController");
	UIImage *originalImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
    // ImageViewにセット
    [self.uploadedImageView setImage:originalImage];
    
    NSLog(@"Make PFFile");
    // TODO jpegのみになってる
    NSData *imageData = UIImageJPEGRepresentation(originalImage, 0.8f);
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
        NSLog(@"image objectId%@", imageArray[0]);
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
    NSLog(@"saved");
}

@end
