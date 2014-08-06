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
#import "Navigation.h"
#import "AWSS3Utils.h"

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
    
    _currentUser = [PFUser currentUser];
    
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
    
    // role で出し分けるものたち
    // チュートリアルの場合は両方やってもらう
    if (![_currentUser objectForKey:@"tutorialStep"] || [[_currentUser objectForKey:@"tutorialStep"] intValue] < 100) {
        [_currentUser refresh];
        if ([[_currentUser objectForKey:@"tutorialStep"] intValue] <= 2) {
            NSLog(@"%@ is under tutorialStep %@", _currentUser[@"userId"], _currentUser[@"tutorialStep"]);
            _tutorialStep = [NSNumber numberWithInt:2];
            _currentUser[@"tutorialStep"] = [NSNumber numberWithInt:2];
            [_currentUser saveInBackground];
            _explainLabel.text = @"";
        } else if ([[_currentUser objectForKey:@"tutorialStep"] intValue] == 4) {
            NSLog(@"%@ is under tutorialStep %@", _currentUser[@"userId"], _currentUser[@"tutorialStep"]);
            _tutorialStep = [NSNumber numberWithInt:4];
            _explainLabel.text = @"";
        }
    } else {
        if ([[FamilyRole selfRole] isEqualToString:@"uploader"]) {
            _explainLabel.text = @"あなたは写真をアップロードする人です(ベストショットは選べません)";
        } else if ([[FamilyRole selfRole] isEqualToString:@"chooser"]) {
            _explainLabel.text = @"あなたはベストショットを決める人です(アップロードは出来ません)";
        }
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
    
    // tutorial用
    if ([_tutorialStep intValue] == 3) {
        _overlay = [[ICTutorialOverlay alloc] init];
        _overlay.hideWhenTapped = NO;
        _overlay.animated = YES;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 170, 300, 200)];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.numberOfLines = 0;
        label.text = @"アップロードの方法(Step 6/13)\n\nアップロードが完了しました。\nこれでアップローダーのチュートリアルは終わりです。\n次は、チューザー機能のチュートリアルになります。画面をタップしてください。";
        [_overlay addSubview:label];
        [_overlay show];
        
        UITapGestureRecognizer *tuto3gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTuto3Gesture:)];
        tuto3gesture.numberOfTapsRequired = 1;
        [_overlay addGestureRecognizer:tuto3gesture];
    } else if ([_tutorialStep intValue] == 4) {
        // チューザーのチュートリアル
        _overlay = [[ICTutorialOverlay alloc] init];
        _overlay.hideWhenTapped = NO;
        _overlay.animated = YES;
        [_overlay addHoleWithView:_multiUploadedImages padding:-10.0f offset:CGSizeMake(0, 0) form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 300, 150)];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.shadowColor = [UIColor blackColor];
        label.shadowOffset = CGSizeMake(0.f, 1.f);
        label.numberOfLines = 0;
        label.text = @"チューザー機能(Step 8/13)\n\nベストショットと思う画像をダブルタップしてください。";
        [_overlay addSubview:label];
        [_overlay show];
    }
    
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
    
    [_overlay removeFromSuperview];
    
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
    
    // アップロード用の画像を最後にはめる、ただし、
    // uploader もしくは tutorialStep = 2(アップロードのチュートリアル) の場合かつ、
    // uploader かつ tutorialStepが4(チューザーのチュートリアル)じゃない場合
    if (([[FamilyRole selfRole] isEqualToString:@"uploader"] || [_tutorialStep intValue] == 2)
        && ([[FamilyRole selfRole] isEqualToString:@"uploader"] && [_tutorialStep intValue] != 4)) {
        [_childCachedImageArray addObject:[NSString stringWithFormat:@"ForUploadImage"]];
    }
    
    _childImageArray = _childCachedImageArray;
    
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
    if ([[_childCachedImageArray objectAtIndex:cell.tag] isEqualToString:@"ForUploadImage"]) {
        _uploadUppeLimit = indexPath.row;
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UploadImageLabel"]];
        UITapGestureRecognizer *uploadGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleUploadGesture:)];
        uploadGesture.numberOfTapsRequired = 1;
        [cell addGestureRecognizer:uploadGesture];
        if ([_tutorialStep intValue] == 2) {
            _plusCellForTutorial = cell;
            [self setTutorialStep2];
        }
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
            [self setupCommentView:object];
        }
        if ([object[@"isTmpData"] isEqualToString:@"TRUE"]) {
            NSLog(@"本画像が上がってない場合 普通の写真ではあり得ない小さい画像(67byte)をcacheにセット -> あとでcache画像サイズ確認して小さければクルクル出す cacheNO:%d", _tmpCacheCount);
            [ImageCache setCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, _indexForCache] image:UIImagePNGRepresentation([UIImage imageNamed:@"OnePx"])];
            _tmpCacheCount++;
            
            _indexForCache++;
            [objects removeObjectAtIndex:0];
            _uploadPregressBar.progress = (float)_indexForCache/ (float)([_childCachedImageArray count] + 1);
            [self setCacheOfParseImage:objects];
        } else {
            NSLog(@"本画像が上がっている場合 S3から取る");
            NSString *ymd = [object[@"date"] substringWithRange:NSMakeRange(1, 8)];
            NSString *month = [ymd substringWithRange:NSMakeRange(0, 6)];
            [[AWSS3Utils getObject:[NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%@", month], object.objectId]] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                if (!task.error && task.result) {
                    AWSS3GetObjectOutput *getResult = (AWSS3GetObjectOutput *)task.result;
                    UIImage *thumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:getResult.body]];
                    [ImageCache setCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, _indexForCache] image:UIImageJPEGRepresentation(thumbImage, 0.7f)];
                    
                    _indexForCache++;
                    [objects removeObjectAtIndex:0];
                    _uploadPregressBar.progress = (float)_indexForCache/ (float)([_childCachedImageArray count] + 1);
                    [self setCacheOfParseImage:objects];
                } else {
                    NSLog(@"S3にないならParseから");
                    [object[@"imageFile"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                        if (!error && data) {
                            UIImage *thumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:data]];
                            [ImageCache setCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, _indexForCache] image:UIImageJPEGRepresentation(thumbImage, 0.7f)];
                            
                            _indexForCache++;
                            [objects removeObjectAtIndex:0];
                            _uploadPregressBar.progress = (float)_indexForCache/ (float)([_childCachedImageArray count] + 1);
                            [self setCacheOfParseImage:objects];
                        }
                    }];
                }
                return nil;
            }];
        }
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

-(void)handleTuto3Gesture:(id) sender {
    NSLog(@"handleTuto3Gesture");
    
    _tutorialStep = [NSNumber numberWithInt:4];
    _currentUser[@"tutorialStep"] = [NSNumber numberWithInt:4];
    [_currentUser save];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)handleUploadGesture:(id) sender {
    if ([[FamilyRole selfRole] isEqualToString:@"uploader"] || [_tutorialStep intValue] == 2) {
        [_overlay hide];
        [_overlay removeFromSuperview];
        _albumTableView = [[UITableView alloc] init];
        _albumTableView.delegate = self;
        _albumTableView.dataSource = self;
        _albumTableView.backgroundColor = [UIColor whiteColor];
        CGRect frame = self.view.frame;
        frame.origin.y += 64;
        frame.size.height -= 64;
        _albumTableView.frame = frame;
        UIViewController *albumTableViewController = [[UIViewController alloc] init];
        albumTableViewController.view = _albumTableView;
        [self.navigationController pushViewController:albumTableViewController animated:YES];

        if ([_tutorialStep intValue] == 2) {
            _overlay = [[ICTutorialOverlay alloc] init];
            _overlay.hideWhenTapped = NO;
            _overlay.animated = YES;
            [_overlay addHoleWithView:_albumTableView padding:-10.0f offset:CGSizeMake(0, 0) form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
        
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, self.view.frame.size.height/2, 240, 150)];
            label.backgroundColor = [UIColor clearColor];
            label.textColor = [UIColor blackColor];
            label.numberOfLines = 0;
            label.text = @"アップロードの方法(Step 3/13)\n\nアルバムを選択してください。";
            [_overlay addSubview:label];
            [_overlay show];
        }
    }
}

-(void)handleDoubleTap:(id) sender {
    NSLog(@"double tap %d", [[sender view] tag]);
    
    // role bbbのみダブルタップ可能
    // チュートリアルStep 4でも可
    if ([[FamilyRole selfRole] isEqualToString:@"chooser"] || [_tutorialStep intValue] == 4) {
        
        _bestImageIndex = [[sender view] tag];
        
        // _multiUploadedImagesにのってるパネルにBestshot付ける
        for (UIView *view in _multiUploadedImages.subviews) {
            if (view.tag == [[sender view] tag] && [view isKindOfClass:[UICollectionViewCell class]]) {
                CGRect frame = view.frame;
                frame.origin = CGPointMake(0, 0);
                frame.size.height = frame.size.width;
                _bestShotLabelView.frame = frame;
                [view addSubview:_bestShotLabelView];
            }
        }
        
        // 大きく表示された(Cell)以外のパネル。これにもベストラベル付ける
        if (![[sender view] isKindOfClass:[UICollectionViewCell class]]) {
            CGRect frame = [sender view].frame;
            frame.origin = CGPointMake(0, 0);
            frame.size.height = frame.size.width;
            UIImageView *bestShotExtraLabelView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BestShotLabel"]];
            bestShotExtraLabelView.frame = frame;
            [[sender view] addSubview:bestShotExtraLabelView];
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
                            [self setupCommentView:object];
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
                    [[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"thumbImages"] replaceObjectAtIndex:i withObject:thumbImage];
                    // サムネイル(キャッシュ)をとりあえず入れる
                    [[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"orgImages"] replaceObjectAtIndex:i withObject:[UIImage imageWithData:thumbData]];
                }
            }
        }
        // チュートリアル中だったらこれで終わり
        if ([_tutorialStep intValue] == 4) {
            _currentUser[@"tutorialStep"] = [NSNumber numberWithInt:5];
            [_currentUser save];
            [self dismissViewControllerAnimated:YES completion:NULL];
        }
    }
}

-(void)handleSingleTap:(UIGestureRecognizer *) sender {
    _detailedImageIndex = [[sender view] tag];
    [self openModalImageView];
}

-(void)handleSingleTapInModalView:(UIGestureRecognizer *) sender {
    // モーダルViewをクリックされたら次の画像に移る。最後まで言ったら消える
    _detailedImageIndex = [[sender view] tag] + 1;
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    
    // アップの場合にはアップロードボタン分だけ少なくなるので
    if (_uploadUppeLimit) {
        if (_uploadUppeLimit > _detailedImageIndex) {
            [self openModalImageView];
        }
    } else {
        if ([_childImageArray count] > _detailedImageIndex) {
            [self openModalImageView];
        }
    }
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
    if ([_tutorialStep intValue] == 2) {
        multiUploadPickerViewController.tutorialStep = [NSNumber numberWithInt:2];
    }
    [self presentViewController:multiUploadPickerViewController animated:YES completion:NULL];
}

-(void)openModalImageView
{
    UIViewController *detailViewController = [[UIViewController alloc] init];
    detailViewController.view.frame = CGRectMake(20, 60, self.view.frame.size.width - 40, self.view.frame.size.height - 80);
    detailViewController.view.backgroundColor = [UIColor whiteColor];
    
    UIImageView *detailImageView = [[UIImageView alloc] init];
    // ローカルに保存されていたサムネイル画像を貼付け
    NSData *cacheImageData = [ImageCache getCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, _detailedImageIndex]];
    detailImageView.backgroundColor = [UIColor blackColor];
    UIImage *cacheImage = [UIImage imageWithData:cacheImageData];
    detailImageView.image = cacheImage;
    
    float imageViewAspect = detailViewController.view.frame.size.width/detailViewController.view.frame.size.height;
    float imageAspect = cacheImage.size.width/cacheImage.size.height;
    
    // 横長バージョン
    // 枠より、画像の方が横長、枠の縦を縮める
    CGRect frame = detailViewController.view.frame;
    if (imageAspect >= imageViewAspect){
        frame.size.height = frame.size.width/imageAspect;
        // 縦長バージョン
        // 枠より、画像の方が縦長、枠の横を縮める
    } else {
        frame.size.width = frame.size.height*imageAspect;
    }
    
    frame.origin.x = (detailViewController.view.frame.size.width - frame.size.width)/2;
    frame.origin.y = (detailViewController.view.frame.size.height - frame.size.height)/2;
    
    detailViewController.view.frame = frame;
    frame.origin = CGPointMake(0, 0);
    detailImageView.frame = frame;
    [detailViewController.view addSubview:detailImageView];
    [self presentPopupViewController:detailViewController animationType:MJPopupViewAnimationFade];
    
    PFObject *object = [_childDetailImageArray objectAtIndex:_detailedImageIndex];
    // まずはS3に接続
    NSString *ymd = [object[@"date"] substringWithRange:NSMakeRange(1, 8)];
    NSString *month = [ymd substringWithRange:NSMakeRange(0, 6)];
    [[AWSS3Utils getObject:[NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%@", month], object.objectId]] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        if (!task.error && task.result) {
            AWSS3GetObjectOutput *getResult = (AWSS3GetObjectOutput *)task.result;
            // 本画像を上にのせる
            UIImageView *orgImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:getResult.body]];
            orgImageView.frame = frame;
            
            // ベストショットラベル付ける
            if (_bestImageIndex == _detailedImageIndex) {
                CGRect extraFrame = frame;
                extraFrame.origin = CGPointMake(0, 0);
                extraFrame.size.height = frame.size.width;
                UIImageView *bestShotExtraLabelView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BestShotLabel"]];
                bestShotExtraLabelView.frame = extraFrame;
                [orgImageView addSubview:bestShotExtraLabelView];
            }
            
            [detailViewController.view addSubview:orgImageView];
        } else {
            // S3になければParseに (そのうち消す)
            [object[@"imageFile"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if (data) {
                    // 本画像を上にのせる
                    UIImageView *orgImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:data]];
                    orgImageView.frame = frame;
            
                    // ベストショットラベル付ける
                    if (_bestImageIndex == _detailedImageIndex) {
                        CGRect extraFrame = frame;
                        extraFrame.origin = CGPointMake(0, 0);
                        extraFrame.size.height = frame.size.width;
                        UIImageView *bestShotExtraLabelView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BestShotLabel"]];
                        bestShotExtraLabelView.frame = extraFrame;
                        [orgImageView addSubview:bestShotExtraLabelView];
                    }
            
                    [detailViewController.view addSubview:orgImageView];
                } else {
                    NSLog(@"error %@", error);
                }
            }];
        }
        return nil;
    }];
    
    detailViewController.view.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *detailImageDoubleTGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    detailViewController.view.tag = _detailedImageIndex;
    detailImageDoubleTGR.numberOfTapsRequired = 2;
    [detailViewController.view addGestureRecognizer:detailImageDoubleTGR];
    
    UITapGestureRecognizer *detailImageSingleTGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapInModalView:)];
    detailImageSingleTGR.numberOfTapsRequired = 1;
    // ダブルタップに失敗した時だけシングルタップとする
    [detailImageSingleTGR requireGestureRecognizerToFail:detailImageDoubleTGR];
    [detailViewController.view addGestureRecognizer:detailImageSingleTGR];
}

-(void)backFromDetailImage:(id) sender
{
    [_pageViewController.view removeFromSuperview];
    [_pageViewController removeFromParentViewController];
    
    [self viewDidAppear:(BOOL)YES];
}

-(void)setTutorialStep2
{
    _overlay = [[ICTutorialOverlay alloc] init];
    _overlay.hideWhenTapped = NO;
    _overlay.animated = YES;
    CGRect frame = _plusCellForTutorial.frame;
    frame.origin.x += 10;
    frame.origin.y += 105;
    frame.size.width -=10;
    frame.size.height -= 10;
    [_overlay addHoleWithRect:frame form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height/2, 300, 200)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 0;
    label.text = @"アップロードの方法(Step 2/13)\n\nアップローダーの場合は、今日のパネルをタップするとこの画像アップロード画面が開きます。\nアップロードボタンを押して画像をアップロードしてみましょう。";
    [_overlay addSubview:label];
    
    [_overlay show];
}

-(void)setupCommentView:(PFObject *) imageInfo;
{
    CGRect defFrame;
    if (_commentView) {
        defFrame = _commentView.frame;
    } else {
        defFrame = CGRectMake(self.view.frame.size.width -50, self.view.frame.size.height-50, self.view.frame.size.width, self.view.frame.size.height -44 -20);
    }
    
    [_commentViewController removeFromParentViewController];
    [_commentView removeFromSuperview];
    
    _commentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CommentViewController"];
    _commentViewController.childObjectId = _childObjectId;
    _commentViewController.name = _name;
    _commentViewController.date = _date;
    _commentViewController.month = _month;
    _commentViewController.imageInfo = imageInfo;
    _commentView = _commentViewController.view;
    _commentView.hidden = NO;
    _commentView.frame = defFrame;
    [self addChildViewController:_commentViewController];
    [self.view addSubview:_commentView];
}
    
@end
