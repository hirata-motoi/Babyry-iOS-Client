//
//  MultiUploadViewController.m
//  babyry
//
//  Created by kenjiszk on 2014/06/13.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "MultiUploadViewController.h"

@interface MultiUploadViewController ()

@end

@implementation MultiUploadViewController

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
    [self createCollectionView];
    
    NSLog(@"received childObjectId:%@ month:%@ date:%@", _childObjectId, _month, _date);
    
    PFQuery *childImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
    childImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [childImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
    [childImageQuery whereKey:@"date" equalTo:[NSString stringWithFormat:@"D%@", _date]];
    _childImageArray = [childImageQuery findObjects];
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

- (IBAction)multiUploadViewBackButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)multiUploadButton:(id)sender {
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

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // オリジナル画像
    NSLog(@"imagePickerController");
	UIImage *originalImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"Make PFFile");
    // TODO jpegのみになってる
    NSData *imageData = UIImageJPEGRepresentation(originalImage, 0.8f);
    PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@%@", _childObjectId, _date] data:imageData];
    
    NSLog(@"Insert To Parse");
    PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
    childImage[@"imageFile"] = imageFile;
    // D(文字)つけないとwhere句のfieldに指定出来ないので付ける
    childImage[@"date"] = [NSString stringWithFormat:@"D%@", _date];
    childImage[@"imageOf"] = _childObjectId;
    childImage[@"bestFlag"] = @"unchoosed";
    [childImage saveInBackground];
    NSLog(@"saved");
    
    // uploadした画像をmulti image viewに反映
    [_multiUploadedImages performBatchUpdates:^{
        int currentSize = [_childImageArray count];
        _childImageArray = [_childImageArray arrayByAddingObject:childImage];
        NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
        for (int i = currentSize; i < currentSize + 1; i++) {
            [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        [_multiUploadedImages insertItemsAtIndexPaths:arrayWithIndexPaths];
    } completion:nil];
}

-(void)createCollectionView
{
    // UICollectionViewの土台を作成
    _multiUploadedImages.delegate = self;
    _multiUploadedImages.dataSource = self;
    [_multiUploadedImages registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"MultiUploadViewControllerCell"];
    
    [self.view addSubview:_multiUploadedImages];
}

// セルの数を指定するメソッド
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_childImageArray count];
}

// 指定された場所のセルを作るメソッド
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //セルを再利用 or 再生成
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MultiUploadViewControllerCell" forIndexPath:indexPath];
    
    NSLog(@"indexPath : %@", [_childImageArray objectAtIndex:indexPath.row]);
    
    // 画像を貼付け
    NSData *tmpImageData = [[_childImageArray objectAtIndex:indexPath.row][@"imageFile"] getData];
    cell.backgroundColor = [UIColor blueColor];
    cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:tmpImageData]];
    
    return cell;
}


@end
