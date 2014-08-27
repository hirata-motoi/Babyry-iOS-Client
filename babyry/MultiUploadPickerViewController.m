//
//  MultiUploadPickerViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/02.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "MultiUploadPickerViewController.h"
#import <Parse/Parse.h>
#import "ImageCache.h"
#import "ImageTrimming.h"
#import "AWSS3Utils.h"
#import "NotificationHistory.h"
#import "Partner.h"
#import "PushNotification.h"
#import "Config.h"

@interface MultiUploadPickerViewController ()

@end

@implementation MultiUploadPickerViewController

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
    
    int currentNum = [[_totalImageNum objectAtIndex:_indexPath.row] intValue];
    
    _picNumLabel.text = [NSString stringWithFormat:@"%d枚アップロード済み、残り%d枚", currentNum, 15 - currentNum];
    
    _configuration = [AWSS3Utils getAWSServiceConfiguration];
    
    _albumImageCollectionView.delegate = self;
    _albumImageCollectionView.dataSource = self;
    [_albumImageCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"MultiUploadPickerViewControllerCell"];
    
    _selectedImageCollectionView.delegate = self;
    _selectedImageCollectionView.dataSource = self;
    [_selectedImageCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"MultiUploadPickerViewControllerSelectedCell"];
    
    // set scroll to buttom;
    NSInteger item = [self collectionView:_albumImageCollectionView numberOfItemsInSection:0] - 1;
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:item inSection:0];
    if (item > 0) {
        [_albumImageCollectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    }
        
    // initialize checkedImageFragArray
    _checkedImageFragArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < [_alAssetsArr count]; i++){
        [_checkedImageFragArray addObject:@"NO"];
    }
    _checkedImageArray = [[NSMutableArray alloc] init];
    
    _backLabel.layer.cornerRadius = 10;
    _backLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    _backLabel.layer.borderWidth = 2;
    
    _sendImageLabel.layer.cornerRadius = 10;
    _sendImageLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    _sendImageLabel.layer.borderWidth = 2;
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

// セルの数を指定するメソッド
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView.tag == 1) {
        return [_alAssetsArr count];
    } else if (collectionView.tag == 2) {
        // _checkedImageArrayにはフォトアルバム一覧でタッチしたもののindexPathを突っ込む
        // タッチ順に追加していく仕様
        /*
        int count = 0;
        for (int i = 0; i < [_checkedImageFragArray count]; i++) {
            if ([[_checkedImageFragArray objectAtIndex:i] isEqualToString:@"YES"]) {
                [_checkedImageArray addObject:[_alAssetsArr objectAtIndex:i]];
                count++;
            }
        }*/
        
        
        return [_checkedImageArray count];
    }
    return 0;
}

// セルの大きさを指定するメソッド
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.view.frame.size.width/4 -3, self.view.frame.size.width/4 -3);
}

// 指定された場所のセルを作るメソッド
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag == 1) {
        //セルを再利用 or 再生成
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MultiUploadPickerViewControllerCell" forIndexPath:indexPath];
        for (UIView *view in [cell subviews]) {
            [view removeFromSuperview];
        }
    
        cell.tag = indexPath.row;

        // 画像を貼付け
        cell.backgroundColor = [UIColor blueColor];
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:[[_alAssetsArr objectAtIndex:indexPath.row] thumbnail]]];
        
        // check icon
        UIImage *checkIcon = [UIImage imageNamed:@"ImageCheckIcon"];
        UIImageView *checkIconView = [[UIImageView alloc] initWithImage:checkIcon];
        CGRect frame = cell.frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        checkIconView.frame = frame;
        [cell addSubview:checkIconView];
        if ([[_checkedImageFragArray objectAtIndex:indexPath.row] isEqualToString:@"NO"]){
            checkIconView.hidden = YES;
        } else {
            checkIconView.hidden = NO;
        }
        
        return cell;
        
    } else if (collectionView.tag == 2) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MultiUploadPickerViewControllerSelectedCell" forIndexPath:indexPath];
        for (UIView *view in [cell subviews]) {
            [view removeFromSuperview];
        }
        cell.tag = indexPath.row;
        cell.backgroundColor = [UIColor blueColor];
        // _checkedImageArrayにはindexPathが入っているので、その画像を取り出す
        NSIndexPath *albumImageIndex = [_checkedImageArray objectAtIndex:indexPath.row];
        UIImage *img = [UIImage imageWithCGImage:[[_alAssetsArr objectAtIndex:albumImageIndex.row] thumbnail]];
        cell.backgroundView = [[UIImageView alloc] initWithImage:img];

        return cell;
    }
    
    return nil;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag == 1) {
        int index = indexPath.row;
        if([[_checkedImageFragArray objectAtIndex:index] isEqualToString:@"NO"]){
            [_checkedImageArray addObject:indexPath];
            [_checkedImageFragArray replaceObjectAtIndex:index withObject:@"YES"];
        } else {
            [_checkedImageFragArray replaceObjectAtIndex:index withObject:@"NO"];
            // _checkedImageFragArrayから抜く
            int i = 0;
            // forでまわしているときにremoveするとforがおかしくなるのでいったんremoveKeyに入れてあとでremoveする
            int removeKey = -1;
            for (NSIndexPath *index in _checkedImageArray) {
                if ([index isEqual:indexPath]) {
                    removeKey = i;
                }
                i++;
            }
            if (removeKey > -1) {
                [_checkedImageArray removeObjectAtIndex:removeKey];
            }
        }
        [_albumImageCollectionView reloadData];
        [_selectedImageCollectionView reloadData];
        
        // scroll to last
        NSInteger item = [self collectionView:_selectedImageCollectionView numberOfItemsInSection:0] - 1;
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:item inSection:0];
        if (item > 1) {
            [_selectedImageCollectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
        }
    } else if (collectionView.tag == 2) {
    }
}

- (IBAction)sendImageButton:(id)sender {
    
    if ([_checkedImageArray count] + [[_totalImageNum objectAtIndex:_indexPath.row] intValue] > 15) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"上限数を超えています"
                                                        message:[NSString stringWithFormat:@"1日あたりアップロード可能なベストショット候補の写真は15枚です。既に%d枚アップロード済みです。アップロード済みの写真は拡大画面から削除も可能です", [[_totalImageNum objectAtIndex:_indexPath.row] intValue]]
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
        return;
    }
    
    if ([_checkedImageArray count] == 0) {
        return;
    }
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.labelText = @"データ準備中";
    //_hud.margin = 0;
    //_hud.labelFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15];
    
    int __block saveCount = 0;
    
    // imageFileをフォアグランドで_uploadImageDataArrayに用意しておく
    // backgroundでセットしようとするとセット前の画像が解放されてしまうので
    _uploadImageDataArray = [[NSMutableArray alloc] init];
    _uploadImageDataTypeArray = [[NSMutableArray alloc] init];
    NSIndexPath *lastIndexPath = _checkedImageArray[_checkedImageArray.count - 1];
    for (NSIndexPath *indexPath in _checkedImageArray) {
        ALAsset *asset = [_alAssetsArr objectAtIndex:indexPath.row];
        ALAssetRepresentation *representation = [asset defaultRepresentation];
        NSURL *assetURL = [[asset valueForProperty:ALAssetPropertyURLs] objectForKey:[[asset defaultRepresentation] UTI]];
        NSString *fileExtension = [[assetURL path] pathExtension];
        
        UIImage *originalImage = [UIImage imageWithCGImage:[representation fullResolutionImage] scale:[representation scale] orientation:(UIImageOrientation)[representation orientation]];
        UIImage *resizedImage = [ImageTrimming resizeImageForUpload:originalImage];
        
        NSData *imageData = [[NSData alloc] init];
        NSString *imageType = [[NSString alloc] init];
        if ([fileExtension isEqualToString:@"PNG"]) {
            imageData = UIImagePNGRepresentation(resizedImage);
            imageType = @"image/png";
        } else {
            imageData = UIImageJPEGRepresentation(resizedImage, 0.7f);
            imageType = @"image/jpeg";
        }
        //PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@%@", _childObjectId, _date] data:imageData];
        [_uploadImageDataArray addObject:imageData];
        [_uploadImageDataTypeArray addObject:imageType];

        PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]]];
        // tmpData = @"TRUE" にセットしておく画像はあとからあげる
        childImage[@"date"] = [NSNumber numberWithInteger:[_date integerValue]];
        childImage[@"imageOf"] = _childObjectId;
        childImage[@"bestFlag"] = @"unchoosed";
        childImage[@"isTmpData"] = @"TRUE";
        [childImage saveInBackgroundWithBlock:^(BOOL succeed, NSError *error){
            saveCount++;
            if ([_checkedImageArray count] == saveCount) {
                [_hud hide:YES];
                if (_totalImageNum) {
                    [_totalImageNum replaceObjectAtIndex:_indexPath.row withObject:[NSNumber numberWithInt:saveCount]];
                }
                _uploadedImageCount = 0; // initialize
                [self saveToParseInBackground];
                [self dismissViewControllerAnimated:YES completion:NULL];
                
                //アルバム表示のViewも消す
                UINavigationController *naviController = (UINavigationController *)self.presentingViewController;
                [naviController popViewControllerAnimated:YES];
            }
        }];
    }
}

// 再起的にbackgroundでuploadする
-(void)saveToParseInBackground
{
    // _uploadImageDataArray に上げる画像が入っている
    // これが count 0になるまで再起実行
    if ([_uploadImageDataArray count] != 0){
        // isTmpDataがついているレコードを探す
        PFQuery *tmpImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]]];
        [tmpImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
        [tmpImageQuery whereKey:@"isTmpData" equalTo:@"TRUE"];
        [tmpImageQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
            // objectが見つかれば上書き
            if (object) {
                // S3に上げる
                AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
                putRequest.bucket = [Config config][@"AWSBucketName"];
                putRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]], object.objectId];
                putRequest.body = [_uploadImageDataArray objectAtIndex:0];
                putRequest.contentLength = [NSNumber numberWithLong:[[_uploadImageDataArray objectAtIndex:0] length]];
                putRequest.contentType = [_uploadImageDataTypeArray objectAtIndex:0];
                putRequest.cacheControl = @"no-cache";
                AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:_configuration];
                [[awsS3 putObject:putRequest] continueWithBlock:^id(BFTask *task) {
                    if (!task.error) {
                        // エラーがなければisTmpDataを更新
                        object[@"isTmpData"] = @"FALSE";
                        [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                            [_uploadImageDataArray removeObjectAtIndex:0];
                            [_uploadImageDataTypeArray removeObjectAtIndex:0];
                            _uploadedImageCount++;
                            [self saveToParseInBackground];
                        }];
                    } else {
                        // 失敗したらレコードごと消す(でいいのかな？リトライ？)
                        [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                            [_uploadImageDataArray removeObjectAtIndex:0];
                            [_uploadImageDataTypeArray removeObjectAtIndex:0];
                            [self saveToParseInBackground];
                        }];
                    }
                    return nil;
                }];
            } else {
                // objectが見つからなければ新たに作成
                PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]]];
                childImage[@"date"] = [NSNumber numberWithInteger:[_date integerValue]];
                childImage[@"imageOf"] = _childObjectId;
                childImage[@"bestFlag"] = @"unchoosed";
                [childImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                    if(succeeded) {
                        // S3に上げる
                        AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
                        putRequest.bucket = [Config config][@"AWSBucketName"];
                        putRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]], childImage.objectId];
                        putRequest.body = [_uploadImageDataArray objectAtIndex:0];
                        putRequest.contentLength = [NSNumber numberWithLong:[[_uploadImageDataArray objectAtIndex:0] length]];
                        putRequest.contentType = [_uploadImageDataTypeArray objectAtIndex:0];
                        putRequest.cacheControl = @"no-cache";
                        AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:_configuration];
                        [[awsS3 putObject:putRequest] continueWithBlock:^id(BFTask *task) {
                                if (!task.error) {
                                    // エラーがなければisTmpDataを更新
                                    [_uploadImageDataArray removeObjectAtIndex:0];
                                    [_uploadImageDataTypeArray removeObjectAtIndex:0];
                                    _uploadedImageCount++;
                                    [self saveToParseInBackground];
                                }
                                return nil;
                            }];
                    }
                }];
            }
        }];
    } else {
        // もしisTmpData = TRUEが残っていればそれは消す
        PFQuery *tmpImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]]];
        [tmpImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
        [tmpImageQuery whereKey:@"isTmpData" equalTo:@"TRUE"];
        [tmpImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
            for (PFObject *object in objects) {
                [object deleteInBackground];
            }
        }];
        
        // 全ての画像の処理が完了 かつ 1枚以上画像がuploadされた場合は通知を送る
        if (_uploadedImageCount > 0) {
            // NotificationHistoryに登録
            PFObject *partner = (PFObject *)[Partner partnerUser];
            [NotificationHistory createNotificationHistoryWithType:@"imageUploaded" withTo:partner[@"userId"] withChild:_childObjectId withDate:[_date integerValue]];
        
            // push通知
            NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
            options[@"data"] = [[NSMutableDictionary alloc]initWithObjects:@[@"Increment"] forKeys:@[@"badge"]];
            [PushNotification sendInBackground:@"imageUpload" withOptions:options];
        }
    }
}

- (IBAction)backButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
