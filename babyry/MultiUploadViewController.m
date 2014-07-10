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
#import "FamilyRole.h"

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
    
    NSLog(@"received childObjectId:%@ month:%@ date:%@", _childObjectId, _month, _date);
    
    // フォトアルバムからリスト取得しておく
    NSLog(@"get from photo album.");
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
    
    [self showCacheImages];
    
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
    
    _uploadProgressView.hidden = YES;
    _uploadPregressBar.progress = 0.0f;
    
    _bestImageIndex = -1;
    
    // Parseから画像を非同期に読み取ってサムネイルを作成 collectionViewをreload
    [self updateImagesFromParse];

    
    // role で出し分けるものたち
    NSLog(@"%@ %@", [PFUser currentUser][@"familyId"], [PFUser currentUser][@"role"]);
    if ([[FamilyRole selfRole] isEqualToString:@"uploader"]) {
        _explainLabel.text = @"あなたは写真をアップロードする人です(ベストショットは選べません)";
    } else if ([[FamilyRole selfRole] isEqualToString:@"chooser"]) {
        _multiUploadButtonLabel.hidden = YES;
        _explainLabel.text = @"あなたはベストショットを決める人です(アップロードは出来ません)";
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSLog(@"viewDidAppear");
    [self showCacheImages];
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

- (void) showCacheImages
{
    int i = 0;
    _childCachedImageArray = [[NSMutableArray alloc] init];
    while ([ImageCache getCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, i]]) {
        //NSLog(@"found cached image %d", i);
        [_childCachedImageArray addObject:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, i]];
        i++;
    }
    
    _childImageArray = _childCachedImageArray;
    
    [_multiUploadedImages reloadData];
}

- (IBAction)multiUploadViewBackButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)multiUploadButton:(id)sender {
    NSLog(@"multiUploadButton");
    
    if ([[FamilyRole selfRole] isEqualToString:@"uploader"]) {
        _albumTableView = [[UITableView alloc] init];
        _albumTableView.delegate = self;
        _albumTableView.dataSource = self;
        _albumTableView.backgroundColor = [UIColor whiteColor];
        CGRect frame = self.view.frame;
        frame.origin.y += 50;
        frame.size.height -= 50*2;
        _albumTableView.frame = frame;
        [self.view addSubview:_albumTableView];
    }
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

-(void)createCollectionView
{
    // UICollectionViewの土台を作成
    _multiUploadedImages.delegate = self;
    _multiUploadedImages.dataSource = self;
    [_multiUploadedImages registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"MultiUploadViewControllerCell"];
    
    [self.view addSubview:_multiUploadedImages];
}

///////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
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
    //NSLog(@"cellForItemAtIndexPath");
    //セルを再利用 or 再生成
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MultiUploadViewControllerCell" forIndexPath:indexPath];
    for (UIView *view in [cell subviews]) {
        //NSLog(@"remove cell's child view");
        [view removeFromSuperview];
    }
    for (UIGestureRecognizer *gesture in [cell gestureRecognizers]) {
        [cell removeGestureRecognizer:gesture];
    }
    
    //NSLog(@"indexPath : %@", [_childImageArray objectAtIndex:indexPath.row]);
    cell.tag = indexPath.row;
    if (_bestImageIndex > -1 && _bestImageIndex == indexPath.row) {
        _bestShotLabelView.frame = cell.frame;
        [_multiUploadedImages addSubview:_bestShotLabelView];
    }
    
    // ローカルに保存されていたサムネイル画像を貼付け
    //NSData *tmpImageData = [[_childImageArray objectAtIndex:indexPath.row][@"imageFile"] getData];
    NSData *tmpImageData = [ImageCache getCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, indexPath.row]];
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

/* ヘッターつけたかったらここにつける
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    NSLog(@"referenceSizeForHeaderInSection!!!!!!!!!!!!!!!!!!!!!!");
    return CGSizeMake(self.view.frame.size.width, 30);
    
    return CGSizeZero;
}

// ヘッダー作る
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"viewForSupplementaryElementOfKind!!!!!!!!!!!!!!!!!");
    //UICollectionReusableView *headerView = [[UICollectionReusableView alloc] init];
    
    UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"MultiUploadCellHeader" forIndexPath:indexPath];
    for (UIView *view in [headerView subviews]) {
        //NSLog(@"remove cell's child view");
        [view removeFromSuperview];
    }
    headerView.backgroundColor = [UIColor grayColor];
    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.frame = headerView.frame;
    CGRect frame = headerLabel.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    headerLabel.frame = frame;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.textColor = [UIColor whiteColor];
    if (indexPath.section == 0) {
        headerLabel.text = @"Now Uploading...";
    } else if (indexPath.section == 1){
        headerLabel.text = @"Today's Images";
    }
    [headerView addSubview:headerLabel];
    return headerView;
}
*/
/////////////////////////////////////////////////////////////////

-(void)updateImagesFromParse
{
    NSLog(@"updateImagesFromParse");
    _uploadProgressView.hidden = NO;
    
    // Parseから画像をとる
    PFQuery *childImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
    childImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [childImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
    [childImageQuery whereKey:@"date" equalTo:[NSString stringWithFormat:@"D%@", _date]];
    [childImageQuery orderByAscending:@"createdAt"];
    [childImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if(!error) {
            // 注意 : ここは深いコピーをしないとだめ
            _childImageArray = [[NSMutableArray alloc] initWithArray:objects];
            //再起的にgetDataしてキャッシュを保存する
            _indexForCache = 0;
            [self setCacheOfParseImage:(NSMutableArray *)objects];
        }
    }];
}

-(void)setCacheOfParseImage:(NSMutableArray *)objects
{
    //NSLog(@"bbbbbbbbbbbb %p %p", _childImageArray, objects);
    if ([objects count] > 0) {
        //NSLog(@"aaaaaaa %d", [objects count]);
        PFObject *object = [objects objectAtIndex:0];
        NSLog(@"index and flag %d %@", _indexForCache, object[@"bestFlag"]);
        if ([object[@"bestFlag"] isEqualToString:@"choosed"]) {
            _bestImageIndex = _indexForCache;
        }
        [object[@"imageFile"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if(!error){
                UIImage *thumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:data]];
                [ImageCache setCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, _indexForCache] image:UIImageJPEGRepresentation(thumbImage, 0.7f)];
                _indexForCache++;
                [objects removeObjectAtIndex:0];
                _uploadPregressBar.progress = (float)_indexForCache/ (float)[_childCachedImageArray count];
                [self setCacheOfParseImage:objects];
            }
        }];
    } else {
        //古いキャッシュは消す
        if ([_childCachedImageArray count] > [_childImageArray count]) {
            NSLog(@"remove old cache");
            for (int i = [_childImageArray count]; i < [_childCachedImageArray count]; i++){
                [ImageCache removeCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, i]];
            }
        }
        _uploadPregressBar.progress = 1.0f;
        [_multiUploadedImages reloadData];
        _uploadProgressView.hidden = YES;
        //NSLog(@"_multiUploadedImages reloaded. number of images %d", [_childImageArray count]);
    }
}

-(void)handleDoubleTap:(id) sender {
    NSLog(@"double tap %d", [[sender view] tag]);
    
    // role bbbのみダブルタップ可能
    if ([[FamilyRole selfRole] isEqualToString:@"chooser"]) {
        
        _bestImageIndex = [[sender view] tag];
        
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
            } else {
                NSLog(@"error at double tap %@", error);
            }
        }];
        
        // set image cache
        NSData *thumbData = [ImageCache getCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, [[sender view] tag]]];
        UIImage *thumbImage = [UIImage imageWithData:thumbData];
        [ImageCache setCache:[NSString stringWithFormat:@"%@%@thumb", _childObjectId, _date] image:UIImageJPEGRepresentation(thumbImage, 0.7f)];
        
        // topのviewに設定する
        // このやり方でいいのかは不明 (UploadViewControllerと同じ処理、ここなおすならそっちも直す)
        ViewController *pvc = (ViewController *)[self presentingViewController];
        if (pvc) {
            int childIndex = pvc.currentPageIndex;
            for (int i = 0; i < [[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"date"] count]; i++){
                if ([[[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"date"] objectAtIndex:i] isEqualToString:_date]) {
                    //NSLog(@"%@",[[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"date"] objectAtIndex:i]);
                    //NSLog(@"%@",[[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"thumbImages"] objectAtIndex:i]);
                    [[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"thumbImages"] replaceObjectAtIndex:i withObject:thumbImage];
                    //NSLog(@"%@",[[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"orgImages"] objectAtIndex:i]);
                    // サムネイル(キャッシュ)をとりあえず入れる
                    [[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"orgImages"] replaceObjectAtIndex:i withObject:[UIImage imageWithData:thumbData]];
                }
            }
        }
    }
}

-(void)handleSingleTap:(UIGestureRecognizer *) sender {
    NSLog(@"single tap %d", [[sender view] tag]);
}

/////////////////////////////////////////////////////////////////
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
    multiUploadPickerViewController.currentCachedImageNum = [_childImageArray count];
    [self presentViewController:multiUploadPickerViewController animated:YES completion:NULL];
}
/////////////////////////////////////////////////////////////////

@end
