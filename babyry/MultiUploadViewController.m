//
//  MultiUploadViewController.m
//  babyry
//
//  Created by kenjiszk on 2014/06/13.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "MultiUploadViewController.h"
#import "ImageTrimming.h"
#import "ViewController.h"
#import "ImageCache.h"
#import "MultiUploadPickerViewController.h"

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
    
    // Get Album list
    _albumListArray = [[NSMutableArray alloc] init];
    _albumImageDic = [[NSMutableDictionary alloc] init];
    //NSMutableArray *assetsArray = [[NSMutableArray alloc] init];
    _library = [[ALAssetsLibrary alloc] init];
    [_library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [_albumListArray addObject:group];
            NSMutableArray *albumImageArray = [[NSMutableArray alloc] init];
            ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (result) {
                    [albumImageArray addObject:result];
                }
            };
            [group enumerateAssetsUsingBlock:assetsEnumerationBlock];
            [_albumImageDic setObject:albumImageArray forKey:[group valueForProperty:ALAssetsGroupPropertyName]];
        }
    } failureBlock:nil];
    
    // Draw collectionView
    [self createCollectionView];
    
    NSLog(@"received childObjectId:%@ month:%@ date:%@", _childObjectId, _month, _date);
    
    // set label
    NSString *yyyy = [_month substringToIndex:4];
    NSString *mm = [_month substringWithRange:NSMakeRange(4, 2)];
    NSString *dd = [_date substringWithRange:NSMakeRange(6, 2)];
    _multiUploadLabel.text = [NSString stringWithFormat:@"%@/%@/%@の%@", yyyy, mm, dd, _name];
    
    // set cell size
    _cellHeight = 100.0f;
    _cellWidth = 100.0f;
    
    // best shot asset
    _bestShotLabelView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BestShotLabel"]];
    
    PFQuery *childImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
    childImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [childImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
    [childImageQuery whereKey:@"date" equalTo:[NSString stringWithFormat:@"D%@", _date]];
    //[childImageQuery orderByAscending:@"createdAt"];
    _childImageArray = [childImageQuery findObjects];
    int index = 0;
    _bestImageIndexAtFirst = 0;
    for (PFObject *object in _childImageArray) {
        if ([object[@"bestFlag"] isEqualToString:@"choosed"]) {
            _bestImageIndexAtFirst = index;
        }
        index++;
    }
    
    //_uploadPregressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    _uploadProgressView.hidden = YES;
    _uploadPregressBar.progress = 0.0f;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    // super
    [super viewWillAppear:animated];
    
    [_albumTableView removeFromSuperview];
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
    NSLog(@"multiUploadButton");
    
    _albumTableView = [[UITableView alloc] init];
    _albumTableView.delegate = self;
    _albumTableView.dataSource = self;
    _albumTableView.backgroundColor = [UIColor whiteColor];
    CGRect frame = self.view.frame;
    frame.origin.y += 50;
    frame.size.height -= 50*2;
    _albumTableView.frame = frame;
    [self.view addSubview:_albumTableView];
    
    /*
     
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
	}*/
}

- (IBAction)testButton:(id)sender {
    NSLog(@"test pushed");
    if(_cellHeight == 100.f) {
        _cellHeight = 300.0f;
        _cellWidth = 300.0f;
    } else {
        _cellHeight = 100.0f;
        _cellWidth = 100.0f;
    }
    [_multiUploadedImages reloadData];
}

/*
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
    if ([_childImageArray count] == 0) {
        childImage[@"bestFlag"] = @"choosed";
    } else {
        childImage[@"bestFlag"] = @"unchoosed";
    }
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
}*/

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

// セルの大きさを指定するメソッド
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(_cellWidth, _cellHeight);
}

// 指定された場所のセルを作るメソッド
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //セルを再利用 or 再生成
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MultiUploadViewControllerCell" forIndexPath:indexPath];
    
    NSLog(@"indexPath : %@", [_childImageArray objectAtIndex:indexPath.row]);
    cell.tag = indexPath.row;
    if (_bestImageIndexAtFirst == indexPath.row) {
        _bestShotLabelView.frame = cell.frame;
        [_multiUploadedImages addSubview:_bestShotLabelView];
    }
    
    // 画像を貼付け
    NSData *tmpImageData = [[_childImageArray objectAtIndex:indexPath.row][@"imageFile"] getData];
    cell.backgroundColor = [UIColor blueColor];
    cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageWithData:tmpImageData]]];
    
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [cell addGestureRecognizer:doubleTapGestureRecognizer];

    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    // ダブルタップに失敗した時だけシングルタップとする
    [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
    [cell addGestureRecognizer:singleTapGestureRecognizer];
    
    return cell;
}

-(void)handleDoubleTap:(id) sender {
    NSLog(@"double tap %d", [[sender view] tag]);
    
    // change label
    _bestShotLabelView.frame = [sender view].frame;
    [_multiUploadedImages addSubview:_bestShotLabelView];
    
    // update Parse
    PFQuery *childImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
    childImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [childImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
    [childImageQuery whereKey:@"date" equalTo:[NSString stringWithFormat:@"D%@", _date]];
    [childImageQuery orderByAscending:@"createdAt"];
    [childImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error) {
            int index = 0;
            for (PFObject *object in objects) {
                if (index == [[sender view] tag]) {
                    NSLog(@"choosed %@", object.objectId);
                    if (![object[@"bestFlag"] isEqualToString:@"choosed"]) {
                        object[@"bestFlag"] =  @"choosed";
                        [object saveInBackground];
                    }
                } else {
                    NSLog(@"unchoosed %@", object.objectId);
                    if (![object[@"bestFlag"] isEqualToString:@"unchoosed"]) {
                        object[@"bestFlag"] =  @"unchoosed";
                        [object saveInBackground];
                    }
                }
                index++;
            }
        }
    }];
    
    // set image cache
    NSData *tmpImageData = [[_childImageArray objectAtIndex:[[sender view] tag]][@"imageFile"] getData];
    [ImageCache setCache:[NSString stringWithFormat:@"%@%@", _childObjectId, _date] image:tmpImageData];
}

-(void)handleSingleTap:(UIGestureRecognizer *) sender {
    NSLog(@"single tap %d", [[sender view] tag]);
}

// アルバム一覧のtableviewようのメソッド
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"album array count %d", [_albumListArray count]);
    return [_albumListArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO : ハードコード！！！
    return 70.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int index = [indexPath indexAtPosition:[indexPath length] - 1];
    NSLog(@"table cell index : %d", index);
    NSLog(@"album name %@", [[_albumListArray objectAtIndex:index] valueForProperty:ALAssetsGroupPropertyName]);
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumListTableViewCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"AlbumListTableViewCell"];
    }
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.text = [[_albumListArray objectAtIndex:index] valueForProperty:ALAssetsGroupPropertyName];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d枚", [[_albumImageDic objectForKey:cell.textLabel.text] count]];
    
    UIImage *tmpImage = [UIImage imageWithCGImage:[[[_albumImageDic objectForKey:cell.textLabel.text] lastObject] thumbnail]];
    cell.imageView.image = tmpImage;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int index = [indexPath indexAtPosition:[indexPath length] - 1];
    NSString *albumName = [[_albumListArray objectAtIndex:index] valueForProperty:ALAssetsGroupPropertyName];
    NSLog(@"selected, index : %d, album name : %@", index, albumName);
    
    MultiUploadPickerViewController *multiUploadPickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadPickerViewController"];
    multiUploadPickerViewController.alAssetsArr = [_albumImageDic objectForKey:albumName];
    multiUploadPickerViewController.month = _month;
    multiUploadPickerViewController.childObjectId = _childObjectId;
    multiUploadPickerViewController.date = _date;
    [self presentViewController:multiUploadPickerViewController animated:YES completion:NULL];
}

@end
