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
#import "AWSCommon.h"
#import "NotificationHistory.h"
#import "Partner.h"
#import "ImagePageViewController.h"
#import "DateUtils.h"
#import "UIColor+Hex.h"
#import "ColorUtils.h"
#import "Config.h"
#import "Logger.h"
#import "MultiUploadViewController+Logic.h"
#import "MultiUploadViewController+Logic+Tutorial.h"
#import "Tutorial.h"
#import "TutorialNavigator.h"
#import "ChildProperties.h"
#import "AlbumTableViewController.h"
#import "ImageUploadInBackground.h"

@interface MultiUploadViewController ()

@end

@implementation MultiUploadViewController {
    MultiUploadViewController_Logic *logic;
    MultiUploadViewController_Logic_Tutorial *logicTutorial;
    TutorialNavigator *tn;
    NSMutableDictionary *childProperty;
}

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
    
    childProperty = [ChildProperties getChildProperty:_childObjectId];
    
    if ([Tutorial shouldShowDefaultImage]) {
        logicTutorial = [[MultiUploadViewController_Logic_Tutorial alloc]init];
        logicTutorial.multiUploadViewController = self;
    } else {
        logic = [[MultiUploadViewController_Logic alloc]init];
        logic.multiUploadViewController = self;
    }
    
    // role で出し分けるものたち
    _myRole = [[NSString alloc] init];
    _instructionLabel.backgroundColor = [ColorUtils getBackgroundColor];
    _instructionLabel.textColor = [UIColor whiteColor];
    _instructionLabel.font = [UIFont systemFontOfSize:14];
    if ([[FamilyRole selfRole:@"useCache"] isEqualToString:@"uploader"]) {
        _myRole = @"uploader";
        _instructionLabel.text = @"写真をアップロードしましょう(上限15枚)。\n[ここをタップして画像を選択]";
        _instructionLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *uploadGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleUploadGesture:)];
        uploadGesture.numberOfTapsRequired = 1;
        [_instructionLabel addGestureRecognizer:uploadGesture];
    } else if ([[FamilyRole selfRole:@"useCache"] isEqualToString:@"chooser"]) {
        _myRole = @"chooser";
        _instructionLabel.text = @"ベストショットを選択しましょう。\n[写真の星マークをタップして選択できます]";
    }
    
    _configuration = [AWSCommon getAWSServiceConfiguration:@"S3"];
    _imageLoadComplete = NO;
    _currentUser = [PFUser currentUser];
    
    // Draw collectionView
    [self createCollectionView];
    [[self logic] showCacheImages];
    
    // set label
    NSString *yyyy = [_month substringToIndex:4];
    NSString *mm = [_month substringWithRange:NSMakeRange(4, 2)];
    NSString *dd = [_date substringWithRange:NSMakeRange(6, 2)];
    [Navigation setTitle:self.navigationItem withTitle:childProperty[@"name"] withSubtitle:[NSString stringWithFormat:@"%@年%@月%@日", yyyy, mm, dd] withFont:nil withFontSize:0 withColor:nil];
    
    // set cell size
    _cellHeight = 100.0f;
    _cellWidth = 100.0f;
    
    // best shot asset
    _selectedBestshotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SelectedBestshot"]];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadComplete) name:@"downloadCompleteFromS3" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(partialDownloadComplete) name:@"partialDownloadCompleteFromS3" object:nil];
    
    [self disableNotificationHistories];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
	[_multiUploadedImages reloadData];
    [super viewDidAppear:animated];
    
    [[self logic] disableNotificationHistory];
    
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
    [super viewWillAppear:animated];
    childProperty = [ChildProperties getChildProperty:_childObjectId];
    [self showBestShotFixLimitLabel];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // super
    [super viewWillDisappear:animated];

    [tn removeNavigationView];
    [_myTimer invalidate];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) doTimer:(NSTimer *)timer
{
    if (!_isTimperExecuting) {
        _isTimperExecuting = YES;
        if (_needTimer) {
            [[self logic] updateImagesFromParse];
        } else {
            [_myTimer invalidate];
        }
    }
}

- (id)logic
{
    return
        (logicTutorial) ? logicTutorial :
        (logic)         ? logic         : nil;
}

- (void)applicationDidReceiveRemoteNotification
{
    [self viewDidAppear:YES];
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
		if ([[_totalImageNum objectAtIndex:_indexPath.row] intValue] > [_childCachedImageArray count]) {
			return [[_totalImageNum objectAtIndex:_indexPath.row] intValue];
		} else {
			return [_childCachedImageArray count];
		}
    } else {
		if ([[_totalImageNum objectAtIndex:_indexPath.row] intValue] > [_childImageArray count]) {
			return [[_totalImageNum objectAtIndex:_indexPath.row] intValue];
		} else {
			return [_childImageArray count];
		}
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
	
	// _childCachedImageArrayの配列数よりrowが大きくなった場合には、まだキャッシュがセットされていないという事でクルクルを出す
	if ([_childCachedImageArray count] == 0 || [_childCachedImageArray count] <= indexPath.row) {
		cell.backgroundColor = [UIColor blackColor];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:cell animated:YES];
        hud.labelText = @"Loading...";
        hud.margin = 0;
        hud.labelFont = [UIFont systemFontOfSize:12];
	} else {
		// 仮に入れている小さい画像の方はまだアップロード中のものなのでクルクルを出す
		NSArray *splitForTmpArray = [[_childCachedImageArray objectAtIndex:indexPath.row] componentsSeparatedByString:@"-"];
		NSString *splitForTmp = [splitForTmpArray lastObject];
		
		if (![splitForTmp isEqualToString:@"tmp"]) {
			NSData *tmpImageData = [ImageCache
									getCache:[_childCachedImageArray objectAtIndex:indexPath.row]
									dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", _childObjectId, _date]];
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
				
				// for tutorial
				if (indexPath.row == 0) {
					_firstCellUnselectedBestShotView = unSelectedBestshotView;
				}
			}
			
			NSArray *tmpArray = [[_childCachedImageArray objectAtIndex:indexPath.row] componentsSeparatedByString:@"-"];
			_selectedBestshotView.frame = unSelectetFrame;
			if ([_bestImageId isEqualToString:[tmpArray lastObject]]) {
				[cell addSubview:_selectedBestshotView];
			}
			cell.tag = indexPath.row;
		} else {
			// ローカルにキャッシュがないのにcellが作られようとしている -> アップロード中の画像
			cell.backgroundColor = [UIColor blackColor];
			MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:cell animated:YES];
			hud.labelText = @"Loading...";
			hud.margin = 0;
			hud.labelFont = [UIFont systemFontOfSize:12];
		}
	}
    
    [[self logic] prepareForTutorial:cell withIndexPath:indexPath];
    
    return cell;
}

-(void) downloadComplete
{
    _imageLoadComplete = YES;
    [[self logic] showCacheImages];
    
    if ([ImageUploadInBackground getUploadingQueueCount] == 0){
        _needTimer = NO;
        [_myTimer invalidate];
    }
    
    _isTimperExecuting = NO;
}

-(void) partialDownloadComplete
{
    [[self logic] showCacheImages];
}

-(void)handleUploadGesture:(id) sender {
    if ([_myRole isEqualToString:@"uploader"]) {
        [self openPhotoAlbumList];
    }
}

-(void)openPhotoAlbumList
{
    AlbumTableViewController *albumTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumTableViewController"];
    albumTableViewController.childObjectId = _childObjectId;
    albumTableViewController.date = _date;
    albumTableViewController.month = _month;
    albumTableViewController.totalImageNum = _totalImageNum;
    albumTableViewController.indexPath = _indexPath;
    albumTableViewController.uploadType = @"multi";
    [self.navigationController pushViewController:albumTableViewController animated:YES];
}

-(void)selectBestShot:(id)sender
{
    if ( !([_myRole isEqualToString:@"chooser"] && _imageLoadComplete) ) {
        return;
    }
    
    // この辺りもmethodに切り出ししたい
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
    
    // bestshotId更新
    _bestImageId = [[[_childCachedImageArray objectAtIndex:[sender view].tag] componentsSeparatedByString:@"-"] lastObject];

    [[self logic] updateBestShot];
    
    // set image cache
    NSData *fullsizeImageData = [ImageCache
                                 getCache:_bestImageId
                                 dir:[NSString stringWithFormat:@"%@/candidate/%@/fullsize", _childObjectId, _date]];
    [ImageCache
        setCache:_date
        image:fullsizeImageData
        dir:[NSString stringWithFormat:@"%@/bestShot/fullsize", _childObjectId]
    ];
    // thumbnailも更新する
    NSData *thumbnailImageData = [ImageCache
                                 getCache:_bestImageId
                                 dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", _childObjectId, _date]];
    UIImage *thumbImage = [UIImage imageWithData:thumbnailImageData];
    [ImageCache
        setCache:_date
        image:UIImageJPEGRepresentation(thumbImage, 0.7f)
        dir:[NSString stringWithFormat:@"%@/bestShot/thumbnail", _childObjectId]
    ];
    
    [[self logic] finalizeSelectBestShot];
}

-(void)handleSingleTap:(UIGestureRecognizer *) sender {
    _detailImageIndex = [[sender view] tag];
    [self openImagePageView:_detailImageIndex forceOpenBestShot:NO];
}

- (void) openImagePageView:(int)detailImageIndex forceOpenBestShot:(BOOL)forceOpenBestShot
{
    // _childImageArrayを_childImageCacheArrayのならびにそろえる (ソートの関係でそろわない可能性あり)
    // ついでにtmp省く
    int i = 0;
    int bestIndex = -1;
    NSMutableArray *childImageArraySorted = [[NSMutableArray alloc] init];
    for (NSString *cacheName in _childCachedImageArray) {
        NSArray *splitArray = [cacheName componentsSeparatedByString:@"-"];
        if (![[splitArray lastObject] isEqualToString:@"tmp"]) {
            for (PFObject *object in _childImageArray) {
                if ([object.objectId isEqualToString:[splitArray lastObject]]) {
                    [childImageArraySorted addObject:object];
                }
            }
        }
        if ([_bestImageId isEqualToString:[splitArray lastObject]]) {
            bestIndex = i;
        }
        i++;
    }
    
    if ([childImageArraySorted count] > 0) {
        NSMutableArray *childImages = [[NSMutableArray alloc] init];
        NSMutableDictionary *section = [[NSMutableDictionary alloc] init];
        NSArray *images = [[NSArray alloc] initWithArray:childImageArraySorted];
        [section setObject:images forKey:@"images"];
        [childImages addObject:[[NSDictionary alloc] initWithDictionary:section]];
        
        ImagePageViewController *pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ImagePageViewController"];
        pageViewController.childImages = childImages;
        pageViewController.currentSection = 0;
        if (forceOpenBestShot && bestIndex != -1) {
            pageViewController.currentRow = bestIndex;
        } else {
            pageViewController.currentRow = detailImageIndex;
        }
        pageViewController.childObjectId = _childObjectId;
        pageViewController.fromMultiUpload = YES;
        pageViewController.myRole = _myRole;
        pageViewController.childCachedImageArray = _childCachedImageArray;
        pageViewController.bestImageIndexNumber = [NSNumber numberWithInt:bestIndex];
        pageViewController.showPageNavigation = YES;
        NSMutableDictionary *imagesCountDic = [[NSMutableDictionary alloc] init];
        [imagesCountDic setObject:[NSNumber numberWithInt:[childImageArraySorted count]] forKey:@"imagesCountNumber"];
        pageViewController.imagesCountDic = imagesCountDic;
        [self.navigationController setNavigationBarHidden:YES];
        [self.navigationController pushViewController:pageViewController animated:YES];
    }
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
            } else {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in BestShotReply(chooser) : %@", error]];
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
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in BestShotReply : %@", error]];
        }
    }];
}

- (void)showalreadyReplyedButton
{
    UIButton *alreadyReplyedIcon = [[UIButton alloc] initWithFrame:[self buttonRect]];
    [alreadyReplyedIcon setBackgroundImage:[UIImage imageNamed:@"GoodBlue"] forState:UIControlStateNormal];
    [alreadyReplyedIcon setImage:[UIImage imageNamed:@"GoodBlue"] forState:UIControlStateNormal];
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
            options[@"formatArgs"] = [NSArray arrayWithObject:[PFUser currentUser][@"nickName"]];
            options[@"data"] = [[NSMutableDictionary alloc]initWithObjects:@[@"Increment"] forKeys:@[@"badge"]];
            [PushNotification sendInBackground:@"bestshotReply" withOptions:options];
    
            [[self logic] createNotificationHistory:@"bestShotReply"];
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in sendBestShotReply %@", error]];
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

// bestShotFixLimitLabelを更新
// limitの時刻 + 文言
- (void)showBestShotFixLimitLabel
{
    if ([[Tutorial currentStage].currentStage isEqualToString:@"familyApplyExec"]) {
        for (UIView *view in _headerView.subviews) {
            [view removeFromSuperview];
        }
        _headerView.backgroundColor = [ColorUtils getSectionHeaderColor];
        UILabel *tutorialLabel = [[UILabel alloc] init];
        tutorialLabel.frame = _headerView.frame;
        tutorialLabel.textColor = [ColorUtils getSunDayCalColor];
        tutorialLabel.textAlignment = NSTextAlignmentCenter;
        tutorialLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        tutorialLabel.numberOfLines = 2;
        tutorialLabel.text = @"パートナーと利用開始するまでは、\nベストショットは自動に決定されます";
        [_headerView addSubview:tutorialLabel];
        
        return;
    }
    
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
                    value: [UIColor_Hex colorWithHexString:@"ffffff" alpha:1.0f]
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

- (void)showTutorialNavigator
{      
    if (tn) {
        [tn removeNavigationView];
        tn = nil;
    }
    tn = [[TutorialNavigator alloc]init];
    tn.targetViewController = self;
    [tn showNavigationView];
}

- (void)removeNavigationView
{
    if (tn) {
        [tn removeNavigationView];
        tn = nil;
    }
}

- (void)forwardNextTutorial
{
    [[self logic] forwardNextTutorial];
}

- (void)disableNotificationHistories
{
    NSArray *notificationTypes = @[@"imageUploaded", @"bestShotChanged", @"requestPhoto"];
    [NotificationHistory disableDisplayedNotificationsWithUser:[PFUser currentUser][@"userId"] withChild:_childObjectId withDate:_date withType:notificationTypes];
}

@end
