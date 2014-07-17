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
#import "MBProgressHUD.h"
#import "PushNotification.h"

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
    
    // Parseから画像を非同期に読み取ってサムネイルを作成 collectionViewをreload (viewDidAppearに移動)
    //[self updateImagesFromParse];

    
    // role で出し分けるものたち
    NSLog(@"%@ %@", [PFUser currentUser][@"familyId"], [PFUser currentUser][@"role"]);
    if ([[FamilyRole selfRole] isEqualToString:@"uploader"]) {
        _explainLabel.text = @"あなたは写真をアップロードする人です(ベストショットは選べません)";
    } else if ([[FamilyRole selfRole] isEqualToString:@"chooser"]) {
        _explainLabel.text = @"あなたはベストショットを決める人です(アップロードは出来ません)";
    }
    
    if ([_childImageArray count] > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_childImageArray count]-1 inSection:0];
        [_multiUploadedImages scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
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
    
    _myTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                target:self
                                              selector:@selector(doTimer:)
                                              userInfo:nil
                                               repeats:YES
    ];
    _isTimperExecuting = NO;
    _needTimer = YES;
    [_myTimer fire];
    NSLog(@"timer info %hhd, %hhd", [_myTimer isValid], _needTimer);
}

- (void)viewWillDisappear:(BOOL)animated
{
    // super
    [super viewWillAppear:animated];
    
    [_myTimer invalidate];
}

- (void) doTimer:(NSTimer *)timer
{
    NSLog(@"DoTimer!!! %hhd", _isTimperExecuting);
    if (!_isTimperExecuting) {
        NSLog(@"DoingTimer!!! %hhd", _isTimperExecuting);
        _isTimperExecuting = YES;
        //NSLog(@"timer fire");
        if (_needTimer) {
            [self updateImagesFromParse];
        } else {
            [_myTimer invalidate];
        }
    }
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
    
    // uploaderはアップロード用の画像も最後にはめる
    if ([[FamilyRole selfRole] isEqualToString:@"uploader"]) {
        [_childCachedImageArray addObject:[NSString stringWithFormat:@"ForUploadImage"]];
    }
    
    _childImageArray = _childCachedImageArray;
    
    [_multiUploadedImages reloadData];
}

- (IBAction)multiUploadViewBackButton:(id)sender {
    BOOL isTableView = NO;
    for (UIView *view in self.view.subviews) {
        if([view isEqual:_albumTableView]){
            isTableView = YES;
        }
    }
    
    if (isTableView) {
        [_albumTableView removeFromSuperview];
    } else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
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
    if ([[_childCachedImageArray objectAtIndex:cell.tag] isEqualToString:@"ForUploadImage"]) {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UploadImageLabel"]];
        UITapGestureRecognizer *uploadGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleUploadGesture:)];
        uploadGesture.numberOfTapsRequired = 1;
        [cell addGestureRecognizer:uploadGesture];
    } else {
        // ローカルに保存されていたサムネイル画像を貼付け
        NSData *tmpImageData = [ImageCache getCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, indexPath.row]];
        // 仮に入れている小さい画像の方はまだアップロード中のものなのでクルクルを出す
        if ([tmpImageData length] > 100) {
            cell.backgroundColor = [UIColor blackColor];
            cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageWithData:tmpImageData]]];
    
            UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
            doubleTapGestureRecognizer.numberOfTapsRequired = 2;
            [cell addGestureRecognizer:doubleTapGestureRecognizer];

            UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
            singleTapGestureRecognizer.numberOfTapsRequired = 1;
            // ダブルタップに失敗した時だけシングルタップとする
            [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
            [cell addGestureRecognizer:singleTapGestureRecognizer];
        } else {
            // ローカルにキャッシュがないのにcellが作られようとしている -> アップロード中の画像
            cell.backgroundColor = [UIColor blackColor];
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:cell animated:YES];
            hud.labelText = @"Uploading...";
            hud.margin = 0;
            hud.labelFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15];
        }
    }
    
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
    //NSLog(@"updateImagesFromParse");
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
            // 詳細画像表示用
            _childDetailImageArray = [[NSMutableArray alloc] initWithArray:objects];
            //再起的にgetDataしてキャッシュを保存する
            _indexForCache = 0;
            _tmpCacheCount = 0;

            [self setCacheOfParseImage:[[NSMutableArray alloc] initWithArray:objects]];
        }
    }];
}

-(void)setCacheOfParseImage:(NSMutableArray *)objects
{
    if ([objects count] > 0) {
        PFObject *object = [objects objectAtIndex:0];
        if ([object[@"bestFlag"] isEqualToString:@"choosed"]) {
            _bestImageIndex = _indexForCache;
        }
        [object[@"imageFile"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if(!error){
                if (data) {
                    if ([data length] < 2) {
                        // こんなに小さい画像はない。なので初期アップロード時に入れた仮のtxtファイル
                        // 小さい画像(67byte)をcacheにセット
                        [ImageCache setCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, _indexForCache] image:UIImagePNGRepresentation([UIImage imageNamed:@"OnePx"])];
                        _tmpCacheCount++;
                    } else {
                        UIImage *thumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:data]];
                        [ImageCache setCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, _indexForCache] image:UIImageJPEGRepresentation(thumbImage, 0.7f)];
                    }
                    _indexForCache++;
                    [objects removeObjectAtIndex:0];
                    _uploadPregressBar.progress = (float)_indexForCache/ (float)([_childCachedImageArray count] + 1);
                    [self setCacheOfParseImage:objects];
                }
            } else {
                NSLog(@"error %@", error);
            }
        }];
    } else {
        //NSLog(@"setCacheOfParseImage2 %d", _tmpCacheCount);
        //古いキャッシュは消す
        if ([_childCachedImageArray count] > [_childImageArray count]) {
            NSLog(@"remove old cache");
            for (int i = [_childImageArray count]; i < [_childCachedImageArray count]; i++){
                [ImageCache removeCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, i]];
            }
        }
        _uploadPregressBar.progress = 1.0f;
        NSLog(@"reloadData!");
        [self showCacheImages];
        
        if ([_childImageArray count] > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_childImageArray count]-1 inSection:0];
            [_multiUploadedImages scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
        }
        
        _uploadProgressView.hidden = YES;
        
        NSLog(@"_tmpCacheCount %d", _tmpCacheCount);
        if (_tmpCacheCount == 0){
            _needTimer = NO;
        }
        
        _isTimperExecuting = NO;
    }
}

-(void)handleUploadGesture:(id) sender {
    if ([[FamilyRole selfRole] isEqualToString:@"uploader"]) {
        _albumTableView = [[UITableView alloc] init];
        _albumTableView.delegate = self;
        _albumTableView.dataSource = self;
        _albumTableView.backgroundColor = [UIColor whiteColor];
        CGRect frame = self.view.frame;
        frame.origin.y += 50;
        frame.size.height -= 50;
        _albumTableView.frame = frame;
        [self.view addSubview:_albumTableView];
    }
}

-(void)handleDoubleTap:(id) sender {
    NSLog(@"double tap %d", [[sender view] tag]);
    
    // role bbbのみダブルタップ可能
    if ([[FamilyRole selfRole] isEqualToString:@"chooser"]) {
        
        _bestImageIndex = [[sender view] tag];
        
        // change label
        if ([sender view].frame.size.width < self.view.frame.size.width/2) {
            _bestShotLabelView.frame = [sender view].frame;
            [_multiUploadedImages addSubview:_bestShotLabelView];
        } else {
            CGRect frame = [sender view].frame;
            frame.origin = CGPointMake(0, 0);
            frame.size.height = frame.size.width;
            _bestShotLabelView.frame = frame;
            [[sender view] addSubview:_bestShotLabelView];
        }
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
                [PushNotification sendInBackground:@"bestshotChosen" withOptions:nil];
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
    
    _detailedImageIndex = [[sender view] tag];
    [self openUploadedDetailImage];
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

// 大きい写真を見るPageView用
-(void) openUploadedDetailImage
{
    // PageViewController追加
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageViewController.dataSource = self;
    
    CGRect frame = _pageViewController.view.frame;
    _pageViewController.view.frame = frame;
    
    UIViewController *startingViewController = [self viewControllerAtIndex:_detailedImageIndex];
    NSArray *viewControllers = @[startingViewController];
    [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [_pageViewController didMoveToParentViewController:self];
}

// provides the view controller after the current view controller. In other words, we tell the app what to display for the next screen.
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger index = viewController.view.tag;
    NSLog(@"viewControllerBeforeViewController %d", index);
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    NSLog(@"index-- :%d", index);
    return [self viewControllerAtIndex:index];
}

// provides the view controller before the current view controller. In other words, we tell the app what to display when user switches back to the previous screen.
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger index = viewController.view.tag;
    NSLog(@"viewControllerAfterViewController %d", index);
    
    // Uploaderの場合には_childImageArrayの最後にアップロード用のラベルがついているからそこも除外する(-2)
    if ([[FamilyRole selfRole] isEqualToString:@"uploader"]) {
        if (index >= [_childImageArray count] - 2 || index == NSNotFound) {
            return nil;
        }
    // 通常は -1
    } else {
        if (index >= [_childImageArray count] - 1 || index == NSNotFound) {
            return nil;
        }
    }
    
    index++;
    NSLog(@"index++ :%d", index);
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index
{
    NSLog(@"viewControllerAtIndex");

    UIViewController *detailImageViewController = [[UIViewController alloc] init];
    CGRect tmpFrame = self.view.frame;
    detailImageViewController.view.frame = tmpFrame;
    detailImageViewController.view.backgroundColor = [UIColor blackColor];
    
    
    UIImageView *detailImageView = [[UIImageView alloc] init];
    // ローカルに保存されていたサムネイル画像を貼付け
    NSData *tmpImageData = [ImageCache getCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, index]];

    detailImageView.backgroundColor = [UIColor blackColor];
    UIImage *tmpImage = [UIImage imageWithData:tmpImageData];
    detailImageView.image = tmpImage;
        
    float imageViewAspect = self.view.frame.size.width/self.view.frame.size.height;
    float imageAspect = tmpImage.size.width/tmpImage.size.height;
        
    // 横長バージョン
    // 枠より、画像の方が横長、枠の縦を縮める
    CGRect frame = self.view.frame;
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
    detailImageView.frame = frame;
    NSLog(@"cache image set done");

    // 画像が小さくなければ本画像
    if ([tmpImageData length] > 100) {
        NSLog(@"uploaded images");
        
        PFObject *object = [_childDetailImageArray objectAtIndex:index];
        NSLog(@"get PFObject %@", object);
        [object[@"imageFile"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (data) {
                NSLog(@"set detailData");
                detailImageView.image = [UIImage imageWithData:data];
            } else {
                NSLog(@"error %@", error);
            }
        }];
        
        detailImageView.userInteractionEnabled = YES;
        detailImageView.tag = index;
        UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        [detailImageView addGestureRecognizer:doubleTapGestureRecognizer];
     
    } else {
        // 仮に入れている小さい画像の方はまだアップロード中のものなのでクルクルを出す
        NSLog(@"uploading images");
        detailImageView.backgroundColor = [UIColor blackColor];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:detailImageView animated:YES];
        hud.frame = detailImageView.frame;
        hud.labelText = @"Uploading...";
        hud.margin = 0;
        hud.labelFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15];
    }
    [detailImageViewController.view addSubview:detailImageView];
    
    detailImageViewController.view.tag = index;
    
    // bestShotラベル貼る
    if (_bestImageIndex == index) {
        CGRect frame = detailImageView.frame;
        frame.size.height = frame.size.width;
        frame.origin = CGPointMake(0, 0);
        _bestShotLabelView.frame = frame;
        [detailImageView addSubview:_bestShotLabelView];
    }
    
    // 戻るボタン設置
    UILabel *backLabel = [[UILabel alloc] init];
    backLabel.text = @"終了";
    backLabel.userInteractionEnabled = YES;
    backLabel.layer.cornerRadius = 10;
    backLabel.textColor = [UIColor whiteColor];
    backLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    backLabel.layer.borderWidth = 2;
    backLabel.textAlignment = NSTextAlignmentCenter;
    UITapGestureRecognizer *backGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backFromDetailImage:)];
    backGesture.numberOfTapsRequired = 1;
    [backLabel addGestureRecognizer:backGesture];
    
    CGRect labelFrame = CGRectMake(self.view.frame.size.width - 60, 20, 50, 30);
    backLabel.frame = labelFrame;
    [detailImageViewController.view addSubview:backLabel];

    return detailImageViewController;
}

// 全体で何ページあるか返す Delegate Method コメント外すとPageControlがあらわれる
/*
- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [_childImageArray count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return _detailedImageIndex;
}
*/

-(void)backFromDetailImage:(id) sender
{
    [_pageViewController.view removeFromSuperview];
    [_pageViewController removeFromParentViewController];
    
    [self viewDidAppear:(BOOL)YES];
}

@end
