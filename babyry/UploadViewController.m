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
    
    // set uploadedImage
    _uploadedImageView.image = _uploadedImage;
    
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
		[imagePickerController setAllowsEditing:YES];
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
    
    NSArray *imageArray = [imageQuery findObjects];
    // imageArrayが一つ以上あったら(objectId指定だから一つしか無いはずだけど)上書き
    if ([imageArray count] > 0) {
        NSLog(@"image objectId%@", imageArray[0]);
        imageArray[0][@"imageFile"] = imageFile;
        [imageArray[0] saveInBackground];
    // 一つもないなら新たに追加
    } else {
        NSLog(@"Insert To Parse");
        PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
        childImage[@"imageFile"] = imageFile;
        // D(文字)つけないとwhere句のfieldに指定出来ないので付ける
        childImage[@"date"] = [NSString stringWithFormat:@"D%@", _date];
        childImage[@"imageOf"] = _childObjectId;
        childImage[@"bestFlag"] = @"unchoosed";
        [childImage saveInBackground];
    }
    NSLog(@"saved");
}

@end
