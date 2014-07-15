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
    //NSLog(@"numberOfItemsInSection %d", collectionView.tag);
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
    //NSLog(@"sizeForItemAtIndexPath %d", collectionView.tag);
    return CGSizeMake(self.view.frame.size.width/4 -3, self.view.frame.size.width/4 -3);
}

// 指定された場所のセルを作るメソッド
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"cellForItemAtIndexPath %d", collectionView.tag);
    if (collectionView.tag == 1) {
        //セルを再利用 or 再生成
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MultiUploadPickerViewControllerCell" forIndexPath:indexPath];
        for (UIView *view in [cell subviews]) {
            //NSLog(@"remove cell's child view");
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
            //NSLog(@"remove cell's child view");
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
    //NSLog(@"didSelectItemAtIndexPath %d", collectionView.tag);
    if (collectionView.tag == 1) {
        NSLog(@"selected %d", indexPath.row);
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
        NSLog(@"selected %d", indexPath.row);
    }
}

- (IBAction)sendImageButton:(id)sender {
    NSLog(@"send image!");
    
    if ([_checkedImageArray count] == 0) {
        return;
    }
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.labelText = @"データ準備中";
    //_hud.margin = 0;
    //_hud.labelFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15];
    
    int __block saveCount = 0;
    
    // imageFileをフォアグランドで用意しておく
    _uploadImageDataArray = [[NSMutableArray alloc] init];
    for (NSIndexPath *indexPath in _checkedImageArray) {
        ALAsset *asset = [_alAssetsArr objectAtIndex:indexPath.row];
        ALAssetRepresentation *representation = [asset defaultRepresentation];
        NSLog(@"asset %@ %d", asset, [representation orientation]);
        NSURL *assetURL = [[asset valueForProperty:ALAssetPropertyURLs] objectForKey:[[asset defaultRepresentation] UTI]];
        NSString *fileExtension = [[assetURL path] pathExtension];
        
        UIImage *originalImage = [UIImage imageWithCGImage:[representation fullResolutionImage] scale:[representation scale] orientation:(UIImageOrientation)[representation orientation]];
        UIImage *resizedImage = [ImageTrimming resizeImageForUpload:originalImage];
        
        NSData *imageData = [[NSData alloc] init];
        if ([fileExtension isEqualToString:@"PNG"]) {
            imageData = UIImagePNGRepresentation(resizedImage);
        } else {
            imageData = UIImageJPEGRepresentation(resizedImage, 0.7f);
        }
        PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@%@", _childObjectId, _date] data:imageData];
        [_uploadImageDataArray addObject:imageFile];
        

        PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
        
        // 適当な小さいtxtファイルであげておく (あとから大きな画像は非同期で送る)
        NSData *tmpData = [@"a" dataUsingEncoding:NSUTF8StringEncoding];
        
        childImage[@"imageFile"] = [PFFile fileWithName:@"NowUploading.txt" data:tmpData];
        childImage[@"date"] = [NSString stringWithFormat:@"D%@", _date];
        childImage[@"imageOf"] = _childObjectId;
        childImage[@"bestFlag"] = @"unchoosed";
        childImage[@"isTmpData"] = @"TRUE";
        [childImage saveInBackgroundWithBlock:^(BOOL succeed, NSError *error){
            saveCount++;
            NSLog(@"saved %d", saveCount);
            if ([_checkedImageArray count] == saveCount) {
                [_hud hide:YES];
                [self saveToParseInBackground];
                [self dismissViewControllerAnimated:YES completion:NULL];
                
                int last = [[self presentingViewController].view.subviews count] - 1;
                UIView *view = [[self presentingViewController].view.subviews objectAtIndexedSubscript:last];
                [view removeFromSuperview];
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
        PFQuery *tmpImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
        [tmpImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
        [tmpImageQuery whereKey:@"isTmpData" equalTo:@"TRUE"];
        [tmpImageQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
            // objectが見つかれば上書き
            if (object) {
                object[@"isTmpData"] = @"FALSE";
                object[@"imageFile"] = [_uploadImageDataArray objectAtIndex:0];
                object[@"date"] = [NSString stringWithFormat:@"D%@", _date];
                object[@"bestFlag"] = @"unchoosed";
                [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                    [_uploadImageDataArray removeObjectAtIndex:0];
                    [self saveToParseInBackground];
                }];
            } else {
                // objectが見つからなければ新たに作成
                PFFile *imageFile = [_uploadImageDataArray objectAtIndex:0];
                PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
                childImage[@"imageFile"] = imageFile;
                childImage[@"date"] = [NSString stringWithFormat:@"D%@", _date];
                childImage[@"imageOf"] = _childObjectId;
                childImage[@"bestFlag"] = @"unchoosed";
                [childImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                    [_uploadImageDataArray removeObjectAtIndex:0];
                    [self saveToParseInBackground];
                }];
            }
        }];
    } else {
        // もしisTmpData = TRUEが残っていればそれは消す
        PFQuery *tmpImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
        [tmpImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
        [tmpImageQuery whereKey:@"isTmpData" equalTo:@"TRUE"];
        [tmpImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
            for (PFObject *object in objects) {
                [object deleteInBackground];
            }
        }];
    }
}

- (IBAction)backButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
