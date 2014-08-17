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
#import "FamilyRole.h"
#import "MBProgressHUD.h"
#import "PushNotification.h"
#import "Navigation.h"
#import "AWSS3Utils.h"
#import "NotificationHistory.h"
#import "Partner.h"
#import "ImagePageViewController.h"
#import "DateUtils.h"
#import "UIColor+Hex.h"
#import "ColorUtils.h"

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
    
    // role で出し分けるものたち
    _myRole = [[NSString alloc] init];
    _instructionLabel.backgroundColor = [ColorUtils getBackgroundColor];
    _instructionLabel.textColor = [UIColor whiteColor];
    _instructionLabel.font = [UIFont systemFontOfSize:14];
    if ([[FamilyRole selfRole] isEqualToString:@"uploader"]) {
        _myRole = @"uploader";
        _instructionLabel.text = @"写真をアップロードしましょう(上限15枚)。\n[ここをタップして画像を選択]";
        _instructionLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *uploadGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleUploadGesture:)];
        uploadGesture.numberOfTapsRequired = 1;
        [_instructionLabel addGestureRecognizer:uploadGesture];
    } else if ([[FamilyRole selfRole] isEqualToString:@"chooser"]) {
        _myRole = @"chooser";
        _instructionLabel.text = @"ベストショットを選択しましょう。\n[写真の星マークをタップして選択できます]";
    }
    
    _configuration = [AWSS3Utils getAWSServiceConfiguration];
    _imageLoadComplete = NO;
    _currentUser = [PFUser currentUser];
    
    // Draw collectionView
    [self createCollectionView];
    [self showCacheImages];
    
    
    // set label
    NSString *yyyy = [_month substringToIndex:4];
    NSString *mm = [_month substringWithRange:NSMakeRange(4, 2)];
    NSString *dd = [_date substringWithRange:NSMakeRange(6, 2)];
    [Navigation setTitle:self.navigationItem withTitle:_child[@"name"] withSubtitle:[NSString stringWithFormat:@"%@年%@月%@日", yyyy, mm, dd] withFont:nil withFontSize:0 withColor:nil];
                                                                     
    // set cell size
    _cellHeight = 100.0f;
    _cellWidth = 100.0f;
    
    // best shot asset
    //_bestShotLabelView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BestShotLabel"]];
    _selectedBestshotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SelectedBestshot"]];
    
    _bestImageIndex = -1;

    if ([_childCachedImageArray count] > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_childCachedImageArray count]-1 inSection:0];
        [_multiUploadedImages scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
    }
   
    [self disableNotificationHistory];
    [self setupBestShotReply];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.labelText = @"データ同期中";
    
    _myTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                target:self
                                              selector:@selector(doTimer:)
                                              userInfo:nil
                                               repeats:YES
    ];
    _isTimperExecuting = NO;
    _needTimer = YES;
    [_myTimer fire];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self showBestShotFixLimitLabel];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // super
    [super viewWillAppear:animated];
    
    [_myTimer invalidate];
}

- (void) doTimer:(NSTimer *)timer
{
    if (!_isTimperExecuting) {
        _isTimperExecuting = YES;
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
        [_childCachedImageArray addObject:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, i]];
        i++;
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
    if ([_childCachedImageArray count] > [_childImageArray count]) {
        return [_childCachedImageArray count];
    } else {
        return [_childImageArray count];
    }
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
    for (UIView *view in [cell subviews]) {
        [view removeFromSuperview];
    }
    for (UIGestureRecognizer *gesture in [cell gestureRecognizers]) {
        [cell removeGestureRecognizer:gesture];
    }
    // ローカルに保存されていたサムネイル画像を貼付け
    NSData *tmpImageData = [ImageCache getCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, indexPath.row]];
    // 仮に入れている小さい画像の方はまだアップロード中のものなのでクルクルを出す
    if ([tmpImageData length] > 100) {
        cell.backgroundColor = [UIColor blackColor];
        cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageWithData:tmpImageData]]];
        
        // 小さい画像の時は、、、みたいな分岐がselectedだと面倒そうだったのでここでgestureつける
        UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTapGestureRecognizer.numberOfTapsRequired = 1;
        [cell addGestureRecognizer:singleTapGestureRecognizer];
        
        // 以下の処理は一番最後 (gestureが一番上にくるように)
        CGRect unSelectetFrame = CGRectMake(cell.frame.size.width*2/3, cell.frame.size.height*2/3, cell.frame.size.width/3, cell.frame.size.height/3);
        // choiceの場合だけunselectedは基本付ける
        if (![_myRole isEqualToString:@"uploader"]) {
            UIImageView *unSelectedBestshotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UnSelectedBestshot"]];
            unSelectedBestshotView.frame = unSelectetFrame;
            [cell addSubview:unSelectedBestshotView];
            
            unSelectedBestshotView.tag = indexPath.row;
            unSelectedBestshotView.userInteractionEnabled = YES;
            UITapGestureRecognizer *selectBestShotGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectBestShot:)];
            selectBestShotGesture.numberOfTapsRequired = 1;
            [unSelectedBestshotView addGestureRecognizer:selectBestShotGesture];
        }
        if (_bestImageIndex > -1 && _bestImageIndex == indexPath.row) {
            _selectedBestshotView.frame = unSelectetFrame;
            [cell addSubview:_selectedBestshotView];
        }
        cell.tag = indexPath.row;
    } else {
        // ローカルにキャッシュがないのにcellが作られようとしている -> アップロード中の画像
        cell.backgroundColor = [UIColor blackColor];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:cell animated:YES];
        hud.labelText = @"Uploading...";
        hud.margin = 0;
        hud.labelFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15];
    }
    
    return cell;
}

-(void)updateImagesFromParse
{
    // Parseから画像をとる
    PFQuery *childImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]]];
    childImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [childImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
    [childImageQuery whereKey:@"date" equalTo:[NSNumber numberWithInteger:[_date integerValue]]];
    [childImageQuery orderByAscending:@"createdAt"];
    [childImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if(!error) {
            [_totalImageNum replaceObjectAtIndex:_indexPath.row withObject:[NSNumber numberWithInt:[objects count]]];
            
            // 注意 : ここは深いコピーをしないとだめ
            _childImageArray = [[NSMutableArray alloc] initWithArray:objects];
            // 詳細画像表示用
            _childDetailImageArray = [[NSMutableArray alloc] initWithArray:objects];
            //再起的にgetDataしてキャッシュを保存する
            _indexForCache = 0;
            _tmpCacheCount = 0;

            _imageLoadComplete = NO;
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
        
        if ([object[@"isTmpData"] isEqualToString:@"TRUE"]) {
            [ImageCache setCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, _indexForCache] image:UIImagePNGRepresentation([UIImage imageNamed:@"OnePx"])];
            _tmpCacheCount++;
            
            _indexForCache++;
            [objects removeObjectAtIndex:0];
            [self setCacheOfParseImage:objects];
        } else {
            AWSS3GetObjectRequest *getRequest = [AWSS3GetObjectRequest new];
            getRequest.bucket = @"babyrydev-images";
            getRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]], object.objectId];
            AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:_configuration];
            [[awsS3 getObject:getRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                if (!task.error && task.result) {
                    AWSS3GetObjectOutput *getResult = (AWSS3GetObjectOutput *)task.result;
                    UIImage *thumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:getResult.body]];
                    [ImageCache setCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, _indexForCache] image:UIImageJPEGRepresentation(thumbImage, 0.7f)];
                    
                    _indexForCache++;
                    [objects removeObjectAtIndex:0];
                    [self setCacheOfParseImage:objects];
                } else {
                    [object[@"imageFile"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                        if (!error && data) {
                            UIImage *thumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:data]];
                            [ImageCache setCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, _indexForCache] image:UIImageJPEGRepresentation(thumbImage, 0.7f)];
                            
                            _indexForCache++;
                            [objects removeObjectAtIndex:0];
                            [self setCacheOfParseImage:objects];
                        }
                    }];
                }
                return nil;
            }];
        }
    } else {
        //古いキャッシュは消す
        if ([_childCachedImageArray count] > [_childImageArray count]) {
            for (int i = [_childImageArray count]; i < [_childCachedImageArray count]; i++){
                [ImageCache removeCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, i]];
            }
        }
        _imageLoadComplete = YES;
        [self showCacheImages];
        
        if ([_childImageArray count] > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_childImageArray count]-1 inSection:0];
            [_multiUploadedImages scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
        }
        
        if (_tmpCacheCount == 0){
            _needTimer = NO;
            [_myTimer invalidate];
        }
        
        [_hud hide:YES];
        
        _isTimperExecuting = NO;
    }
}

-(void)handleUploadGesture:(id) sender {
    if ([_myRole isEqualToString:@"uploader"]) {
        [self openPhotoAlbumList];
    }
}

-(void)openPhotoAlbumList
{
    MultiUploadAlbumTableViewController *multiUploadAlbumTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadAlbumTableViewController"];
    multiUploadAlbumTableViewController.childObjectId = _childObjectId;
    multiUploadAlbumTableViewController.date = _date;
    multiUploadAlbumTableViewController.month = _month;
    multiUploadAlbumTableViewController.child = _child;
    multiUploadAlbumTableViewController.totalImageNum = _totalImageNum;
    multiUploadAlbumTableViewController.indexPath = _indexPath;
    [self.navigationController pushViewController:multiUploadAlbumTableViewController animated:YES];
}

-(void)selectBestShot:(id) sender {
    
    if ([_myRole isEqualToString:@"chooser"] && _imageLoadComplete) {
        _bestImageIndex = [[sender view] tag];
        
        // _multiUploadedImagesにのってるパネルにBestshot付ける
        for (UIView *view in _multiUploadedImages.subviews) {
            if (view.tag == [[sender view] tag] && [view isKindOfClass:[UICollectionViewCell class]]) {
                for (UIView *subview in view.subviews) {
                    if (subview.tag == [[sender view] tag] && subview.frame.size.width < view.frame.size.width) {
                        [_selectedBestshotView removeFromSuperview];
                        [view addSubview:_selectedBestshotView];
                    }
                }
            }
        }
        
        // update Parse
        PFQuery *childImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[_child[@"childImageShardIndex"] integerValue]]];
        childImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;                                                   
        [childImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
        [childImageQuery whereKey:@"date" equalTo:[NSNumber numberWithInteger:[_date integerValue]]];
        [childImageQuery orderByAscending:@"createdAt"];
        [childImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if(!error) {
                int index = 0;
                for (PFObject *object in objects) {
                    if (index == [[sender view] tag]) {
                        if (![object[@"bestFlag"] isEqualToString:@"choosed"]) {
                            object[@"bestFlag"] =  @"choosed";
                            [object saveInBackground];
                        }
                    } else {
                        if (![object[@"bestFlag"] isEqualToString:@"unchoosed"]) {
                            object[@"bestFlag"] =  @"unchoosed";
                            [object saveInBackground];
                        }
                    }
                    index++;
                }
                PFObject *partner = (PFUser *)[Partner partnerUser];
                if (partner != nil) {
                    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
                    options[@"formatArgs"] = partner[@"nickName"];
                    options[@"data"] = [[NSMutableDictionary alloc]initWithObjects:@[@"Increment"] forKeys:@[@"badge"]];
                    [PushNotification sendInBackground:@"bestshotChosenTest" withOptions:options];
                    [self createNotificationHistory:@"bestShotChanged"];
                }
                
            } else {
                NSLog(@"error at double tap %@", error);
            }
        }];

        // set image cache
        NSData *thumbData = [ImageCache getCache:[NSString stringWithFormat:@"%@%@-%d", _childObjectId, _date, [[sender view] tag]]];
        UIImage *thumbImage = [UIImage imageWithData:thumbData];
        [ImageCache setCache:[NSString stringWithFormat:@"%@%@thumb", _childObjectId, _date] image:UIImageJPEGRepresentation(thumbImage, 0.7f)];
    }
}

-(void)handleSingleTap:(UIGestureRecognizer *) sender {
    _detailImageIndex = [[sender view] tag];
    [self openImagePageView:_detailImageIndex];
}

- (void) openImagePageView:(int)detailImageIndex
{
    if ([_childImageArray count] > 0) {
        NSMutableArray *childImages = [[NSMutableArray alloc] init];
        NSMutableDictionary *section = [[NSMutableDictionary alloc] init];
        NSArray *images = [[NSArray alloc] initWithArray:_childImageArray];
        [section setObject:images forKey:@"images"];
        [childImages addObject:[[NSDictionary alloc] initWithDictionary:section]];
        
        ImagePageViewController *pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ImagePageViewController"];
        pageViewController.childImages = childImages;
        pageViewController.currentSection = 0;
        pageViewController.currentRow = detailImageIndex;
        pageViewController.childObjectId = _childObjectId;
        pageViewController.fromMultiUpload = YES;
        pageViewController.myRole = _myRole;
        pageViewController.bestImageIndexNumber = [NSNumber numberWithInt:_bestImageIndex];
        pageViewController.showPageNavigation = YES;
        NSMutableDictionary *imagesCountDic = [[NSMutableDictionary alloc] init];
        [imagesCountDic setObject:[NSNumber numberWithInt:[_childImageArray count]] forKey:@"imagesCountNumber"];
        pageViewController.imagesCountDic = imagesCountDic;
        pageViewController.child = _child;
        pageViewController.notificationHistory = _notificationHistoryByDay;
        [self.navigationController setNavigationBarHidden:YES];
        [self.navigationController pushViewController:pageViewController animated:YES];
    }
}

-(void)backFromDetailImage:(id) sender
{
    [_pageViewController.view removeFromSuperview];
    [_pageViewController removeFromParentViewController];
    
    [self viewDidAppear:(BOOL)YES];
}

- (void)createNotificationHistory:(NSString *)type
{
    [NSThread detachNewThreadSelector:@selector(executeNotificationHistory:) toTarget:self withObject:[[NSMutableDictionary alloc]initWithObjects:@[type] forKeys:@[@"type"]]];
    
}

- (void)executeNotificationHistory:(id)param
{
    NSString *type = [param objectForKey:@"type"];
    PFObject *partner = (PFUser *)[Partner partnerUser];
    [NotificationHistory createNotificationHistoryWithType:type withTo:partner[@"userId"] withChild:_childObjectId withDate:[_date integerValue]];
}

- (void)setupBestShotReply
{
    if (![_myRole isEqualToString:@"uploader"]) {
        PFQuery *query = [PFQuery queryWithClassName:@"BestShotReply"];
        [query whereKey:@"toUserId" equalTo:[PFUser currentUser][@"userId"]];
        [query whereKey:@"date" equalTo:[NSNumber numberWithInteger:[_date integerValue]]];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
            if (!error && objects.count > 0) {
                // bestShotもらい済
                [self showReceivedBestShotReply];
            }
        }];
        
        return;
    }
   
    _bestShotReplyIcon = [[UIButton alloc]init];
    _bestShotReplyIcon.frame = [self buttonRect];
    [_bestShotReplyIcon setImage:[UIImage imageNamed:@"GoodGray"] forState:UIControlStateNormal];
    [_headerView addSubview:_bestShotReplyIcon];
    
    PFQuery *query = [PFQuery queryWithClassName:@"BestShotReply"];
    [query whereKey:@"fromUserId" equalTo:[PFUser currentUser][@"userId"]];
    [query whereKey:@"date" equalTo:[NSNumber numberWithInteger:[_date integerValue]]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error && objects.count > 0) {
            // 既にbestShotReply済
            [self showalreadyReplyedButton];
        }
    }];
}

- (void)showalreadyReplyedButton
{
    UIButton *alreadyReplyedIcon = [[UIButton alloc] initWithFrame:[self buttonRect]];
    [alreadyReplyedIcon setBackgroundImage:[UIImage imageNamed:@"GoodBlue"] forState:UIControlStateNormal];
    [alreadyReplyedIcon setImage:[UIImage imageNamed:@"GoodBlue"] forState:UIControlStateNormal];
    //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:alreadyReplyedIcon];
    _bestShotReplyIcon = alreadyReplyedIcon;
    [_headerView addSubview:_bestShotReplyIcon];
}

- (void)sendBestShotReply
{
    // ボタンを押下済のものに変更
    [self showalreadyReplyedButton];
   
    PFObject *partner = (PFObject *)[Partner partnerUser];
    PFObject *obj = [PFObject objectWithClassName:@"BestShotReply"];
    obj[@"fromUserId"] = [PFUser currentUser][@"userId"];
    obj[@"toUserId"] = partner[@"userId"];
    obj[@"date"] = [NSNumber numberWithInteger:[_date integerValue]];
    [obj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
            options[@"formatArgs"] = [PFUser currentUser][@"nickName"];
            options[@"data"] = [[NSMutableDictionary alloc]initWithObjects:@[@"Increment"] forKeys:@[@"badge"]];
            [PushNotification sendInBackground:@"bestshotReply" withOptions:options];
    
            [self createNotificationHistory:@"bestShotReply"];
        }
    }];
}

- (void)showReceivedBestShotReply
{
    // アイコンを画面右上に表示する
    UIImageView *iv = [[UIImageView alloc]initWithFrame:[self buttonRect]];
    iv.image = [UIImage imageNamed:@"GoodBlue"];
    [self.view addSubview:iv];
}

// imageUploaded, bestShotChanged, bestShotReplyはページを開いた時点で無効にする
- (void)disableNotificationHistory
{
    NSArray *targetTypes = [NSArray arrayWithObjects:@"imageUploaded", @"bestShotChanged", @"bestShotReply", nil];
    
    for (NSString *type in targetTypes) {
        if (_notificationHistoryByDay && _notificationHistoryByDay[type]) {
            for (PFObject *notificationHistory in _notificationHistoryByDay[type]) {
                [NotificationHistory disableDisplayedNotificationsWithObject:notificationHistory];
            }
            [_notificationHistoryByDay[type] removeAllObjects];
        }
    }
}

// bestShotFixLimitLabelを更新
// limitの時刻 + 文言
- (void)showBestShotFixLimitLabel
{
    // 帯の色設定
    _headerView.backgroundColor = [ColorUtils getSectionHeaderColor];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    
    // limit時刻
    NSDateComponents *targetDateComps = [[NSDateComponents alloc]init];
    targetDateComps.year  = [[_date substringWithRange:NSMakeRange(0, 4)] integerValue];
    targetDateComps.month = [[_date substringWithRange:NSMakeRange(4, 2)] integerValue];
    targetDateComps.day   = [[_date substringWithRange:NSMakeRange(6, 2)] integerValue];
    
    NSDateComponents *limitComps = [DateUtils addDateComps:targetDateComps withUnit:@"day" withValue:2];
    NSDate *limitDate = [DateUtils setSystemTimezone: [cal dateFromComponents:limitComps]];
    
    // 現在時刻
    NSDate *todayDate = [DateUtils setSystemTimezone:[NSDate date]];
    
    if ([limitDate timeIntervalSinceDate:todayDate] > 0) {
        CGFloat diff = [limitDate timeIntervalSinceDate:todayDate];
        CGFloat diffHour = floor( diff / (60 * 60) );
        CGFloat diffMinute = floor( (diff - diffHour * 60 * 60) / 60 ); // 切り捨て必須。10分後と表記して11分後に消えるのはOKだが、逆はアウトなので。
        
        NSString *remainedTimeText = (diffHour > 0) ? [NSString stringWithFormat:@"%d時間%d分", (int)diffHour, (int)diffMinute] : [NSString stringWithFormat:@"%d分", (int)diffMinute];
        NSString * text = [NSString stringWithFormat:@"あと%@", remainedTimeText];
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:text];
        // 色
        [str addAttribute:NSForegroundColorAttributeName
                    value: [UIColor_Hex colorWithHexString:@"ff7f7f" alpha:1.0f]
                    range:NSMakeRange(0, text.length)];
        // font
        [str addAttribute:NSFontAttributeName
                    value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0f]
                    range:NSMakeRange(0, text.length)];
                                          
        [_bestShotFixLimitLabel setAttributedText:str];
        [self.view addSubview:_bestShotFixLimitLabel];
    }
    
}

- (CGRect)buttonRect
{
    return CGRectMake(_headerView.frame.size.width - 30 - 5, (_headerView.frame.size.height - 30) / 2, 30, 30);
}

@end
