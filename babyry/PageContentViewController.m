//
//  PageContentViewController.m
//  babyrydev
//
//  Created by kenjiszk on 2014/06/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PageContentViewController.h"
#import "ViewController.h"
#import "UploadViewController.h"
#import "MultiUploadViewController.h"
#import "AlbumTableViewController.h"
#import "ImageTrimming.h"
#import "ImageCache.h"
#import "FamilyRole.h"
#import "FamilyApply.h"
#import "ImagePageViewController.h"
#import "ArrayUtils.h"
#import "CalendarCollectionViewCell.h"
#import "DateUtils.h"
#import "DragView.h"
#import "CellImageFramePlaceHolder.h"
#import "CellImageFramePlaceHolderLarge.h"
#import "AddMonthToCalendarView.h"
#import "CalenderLabel.h"
#import "PushNotification.h"
#import "NotificationHistory.h"
#import "ColorUtils.h"
#import "Badge.h"
#import "UIColor+Hex.h"
#import "CollectionViewSectionHeader.h"
#import <AudioToolbox/AudioServices.h>
#import "ImageRequestIntroductionView.h"
#import "PageFlickIntroductionView.h"
#import "Config.h"
#import "Logger.h"
#import "AppSetting.h"
#import "PageContentViewController+Logic.h"
#import "PageContentViewController+Logic+Tutorial.h"
#import "Tutorial.h"
#import "TutorialNavigator.h"
#import "PartnerInviteViewController.h"
#import "FamilyApplyListViewController.h"
#import "PartnerWaitViewController.h"
#import "PartnerApply.h"
#import "ParseUtils.h"
#import "ChildProperties.h"
#import "Partner.h"
#import "UploadPastImagesIntroductionView.h"
#import "AnnounceBoardView.h"
#import "Comment.h"
#import "CommentNumLabel.h"
#import "ImageUtils.h"

@interface PageContentViewController ()

@end

@implementation PageContentViewController {
    PageContentViewController_Logic *logic;
    PageContentViewController_Logic_Tutorial *logicTutorial;
    NSMutableDictionary *childProperty;
    float windowWidth;
    float windowHeight;
    CGSize bigRect;
    CGSize smallRect;
    BOOL alreadyRegisteredObserver;
    NSMutableDictionary *closedCellCountBySection;
    BOOL isTogglingCells;
    UIImage *iconImage;
    NSMutableDictionary *commentNumForDate;
    NSString *requestPhotoDay;
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
    closedCellCountBySection = [[NSMutableDictionary alloc]init];
    childProperty = [ChildProperties getChildProperty:_childObjectId];
  
    logicTutorial = [[PageContentViewController_Logic_Tutorial alloc]init];
    logicTutorial.pageContentViewController = self;
    logic = [[PageContentViewController_Logic alloc]init];
    logic.pageContentViewController = self;
    
    // Do any additional setup after loading the view.
    _configuration = [AWSCommon getAWSServiceConfiguration:@"S3"];
    _isFirstLoad = 1;
    _currentUser = [PFUser currentUser];
    _imagesCountDic = [[NSMutableDictionary alloc]init];
    [self adjustChildImages];
    [self createCollectionView];
    
    windowWidth = self.view.frame.size.width;
    windowHeight = self.view.frame.size.height;
    bigRect = CGSizeMake(windowWidth, windowHeight - 44 - 20  - windowWidth*2/3);
    smallRect = CGSizeMake(windowWidth/3 - 2, windowWidth/3 - 2);
    
    alreadyRegisteredObserver = NO;
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.hidden = YES;
	
	_bestImageIds = [[NSMutableDictionary alloc] init];
    
    _rc = [[UIRefreshControl alloc] init];
    [_rc addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventValueChanged];
    [_pageContentCollectionView addSubview:_rc];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadComplete) name:@"downloadCompleteFromS3" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadComplete) name:@"partialDownloadCompleteFromS3" object:nil];
    
    // コメント数を取得
    commentNumForDate = [Comment getAllCommentNum];
}

- (void)applicationDidBecomeActive
{
    [self viewDidAppear:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    if (![PartnerApply linkComplete]) {
        if (!_instructionTimer || ![_instructionTimer isValid]){
            _instructionTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(reloadView) userInfo:nil repeats:YES];
        }
    }
    childProperty = [ChildProperties getChildProperty:_childObjectId];
    [self reloadView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initializeClosedCellCountBySection];
    
    // Notification登録
    if (!alreadyRegisteredObserver) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPageContentView) name:@"receivedCalendarAddedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillAppear:) name:@"applicationWillEnterForeground" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPageContentView) name:@"resetImage" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setImages) name:@"didUpdatedChildImageInfo" object:nil]; // for tutorial + icon change
        alreadyRegisteredObserver = YES;
    }
    
    // pushでの遷移の時はクルクルを出さない。クルクルを止める処理をする時にはViewが遷移してしまっていてUIの制御が出来なくなるような挙動をするため
    if (_isFirstLoad && [[TransitionByPushNotification getInfo] count] < 1) {
        _hud.labelText = @"データ同期中";
        _hud.hidden = NO;
    }
    
    //[self setImages];
    // 少し待ってあげないと、cellの描画がおわらないので、いま画面に映っているcellのindexPathが取得できない
    [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(setImages) userInfo:nil repeats:NO];
    
    if (!_tm || ![_tm isValid]) {
        _tm = [NSTimer scheduledTimerWithTimeInterval:60.0f target:self selector:@selector(setImages) userInfo:nil repeats:YES];
    }
//    [self showAnnounceBoard];

    [logic showGlobalMenuBadge];
    
    // 子供がいたら子供の名前にnavigationのtitleを変更
    if (childProperty[@"name"]) {
        [_delegate updateNavitagionTitle:childProperty[@"name"]];
    }
}

- (void)reloadView
{
    if ([PartnerApply linkComplete] && [_instructionTimer isValid]) {
        // この処理は一回だけで良し
        [Tutorial forwardStageWithNextStage:@"tutorialFinished"];
        [_instructionTimer invalidate];
        
        [logic updateChildProperties];
    }
    
    [FamilyRole updateCache];
    _selfRole = [FamilyRole selfRole:@"useCache"];
    childProperty = [ChildProperties getChildProperty:_childObjectId];
    [_pageContentCollectionView reloadData];
 
    // ベストショット選択を促すとき(chooseByUser)と写真のアップロードを促す時(uploadByUser)は
    // cellにholeをあてるためcell表示後にoverlayを出す必要がある
    TutorialStage *currentStage = [Tutorial currentStage];
    if ( !([currentStage.currentStage isEqualToString:@"chooseByUser"] || [currentStage.currentStage isEqualToString:@"uploadByUser"]) ) {
        [self showTutorialNavigator];
    }
}

- (void)onRefresh
{
    // 上で引っ張って更新
    // スクロールで読んで記録していたloadedComp(=dateComp)も初期化
    [_rc beginRefreshing];
    _dateComp = [logic dateComps];
    [self setImages];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];
    
    [_instructionTimer invalidate];
    
    [_tn removeNavigationView];
    _tn = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    alreadyRegisteredObserver = NO;
    
    [self removeDialogs];
}

- (id)logic:(NSString *)methodName
{
    TutorialStage *currentStage = [Tutorial currentStage];
    
    if ([methodName isEqualToString:@"setImages"]) {
        if ([Tutorial shouldShowDefaultImage]) {
            return logicTutorial;
        }
    } else if ([methodName isEqualToString:@"forbiddenSelectCell"]) {
        if ([Tutorial shouldShowDefaultImage] || [currentStage.currentStage isEqualToString:@"uploadByUser"]) {
            return logicTutorial;
        }
    } else if ([methodName isEqualToString:@"getChildImagesWithYear"]) {
        if ([Tutorial shouldShowDefaultImage]) {
            return logicTutorial;
        }
    } else {
        // underTutorialでロジックを判断
        if ([Tutorial underTutorial]) {
            return logicTutorial;
        }
    }
    return logic;
}

-(void)setImages
{
    commentNumForDate = [Comment getAllCommentNum];
    if ([[Tutorial currentStage].currentStage isEqualToString:@"uploadByUserFinished"]) {
        _hud.hidden = YES;
        return;
    }
    [[self logic:@"setImages"] setImages];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_tm invalidate];
    
    // Observerけす
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)createCollectionView
{
    // UICollectionViewの土台を作成
    _pageContentCollectionView.delegate = self;
    _pageContentCollectionView.dataSource = self;
    [_pageContentCollectionView registerClass:[CalendarCollectionViewCell class] forCellWithReuseIdentifier:@"PageContentCollectionView"];
    [_pageContentCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"viewControllerHeader"];
    
    [self.view addSubview:_pageContentCollectionView];
}

// セルの数を指定するメソッド
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger closedCellCount = 0;
    if (closedCellCountBySection[ [NSNumber numberWithInteger:section] ]) {
        closedCellCount = [closedCellCountBySection[ [NSNumber numberWithInteger:section] ] integerValue];
    }
    
    return [_childImages[section][@"images"] count] - closedCellCount;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return _childImages.count;
}

// セルの大きさを指定するメソッド
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        return bigRect;
    }
    return smallRect;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 2.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 1.0;
}

// 指定された場所のセルを作るメソッド
-(CalendarCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //セルを再利用 or 再生成
    CalendarCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PageContentCollectionView" forIndexPath:indexPath];
    for (UIView *view in [cell subviews]) {
        [view removeFromSuperview];
    }
    for (UIGestureRecognizer *gesture in [cell gestureRecognizers]) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            [cell removeGestureRecognizer:gesture];
        }
    }
   
    // indexPathの設定
    cell.currentSection = indexPath.section;
    cell.currentRow = indexPath.row;
   
    PFObject *childImage = [[[_childImages objectAtIndex:indexPath.section] objectForKey:@"images"] objectAtIndex:indexPath.row];
    
    // Cacheからはりつけ
    NSString *ymd = [childImage[@"date"] stringValue];
    NSString *imageCachePath = ([DateUtils isTodayByIndexPath:indexPath])
        ? [NSString stringWithFormat:@"%@/bestShot/fullsize/%@", _childObjectId , ymd]
        : [NSString stringWithFormat:@"%@/bestShot/thumbnail/%@", _childObjectId , ymd];

    [self setBackgroundViewOfCell:cell withImageCachePath:imageCachePath withIndexPath:indexPath withYmd:ymd];
    
    // カレンダーラベル付ける
    [cell addSubview:[self makeCalenderLabel:indexPath cellFrame:cell.frame]];
    
    // 月の2日目の時に、1日のサムネイルが中央寄せとなって表示されてしまうためorigin.xを無理矢理設定
    if (indexPath.section == 0 && indexPath.row == 1) {
        CGRect rect = cell.frame;
        rect.origin.x = 0;
        cell.frame = rect;
    }
    
    // for tutorial
    if (indexPath.section == 0 && indexPath.row == 0) {
        _cellOfToday = cell;
       
        // chooseByUser、uploadByUser以外はviewWillAppearでoverlayを表示
        TutorialStage *currentStage = [Tutorial currentStage];
        if ([currentStage.currentStage isEqualToString:@"chooseByUser"] || [currentStage.currentStage isEqualToString:@"uploadByUser"]){
            [self showTutorialNavigator];
        }
    }
    
    cell.tag = indexPath.row;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self logic:@"forbiddenSelectCell"] forbiddenSelectCell:indexPath]) {
        return;
    }
    
    // チョイスの人がアップ催促する
    // タップでアラートでて、Give Me PhotoをおくるならOK押す
    if ([_selfRole isEqualToString:@"chooser"] && [DateUtils isInTwodayByIndexPath:indexPath]) {
        if ([[self logic:@"isNoImage"] isNoImage:indexPath]) {
            // ださいんだが、alertに値を渡す方法がよくわからんのでこれに保持させる
            if (indexPath.row == 0) {
                requestPhotoDay = @"today";
            } else {
                requestPhotoDay = @"yesterday";
            }
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Give Me Photo"
                                                            message:@"アップロードをパートナーにおねがいしますか？"
                                                           delegate:self
                                                  cancelButtonTitle:@"キャンセル"
                                                  otherButtonTitles:@"おねがいする", nil
                                  ];
            [alert show];
            return;
        }
    }
    
    // チョイス側、2日より前の時にも何もしない(No Image)
    if ([_selfRole isEqualToString:@"chooser"] && ![DateUtils isInTwodayByIndexPath:indexPath]) {
        if ([[self logic:@"isNoImage"] isNoImage:indexPath]) {
            return;
        }
    }
   
    PFObject *tappedChildImage = [[[_childImages objectAtIndex:indexPath.section] objectForKey:@"images"] objectAtIndex:indexPath.row];
    // chooser
    //    upload待ち
    //    BS選択
    // uploader
    //    +ボタンがないパターン
    if ([[self logic:@"shouldShowMultiUploadView"] shouldShowMultiUploadView:indexPath]) {
        if ([[self logic:@"isNoImage"] isNoImage:indexPath]) {
            AlbumTableViewController *albumTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumTableViewController"];
            albumTableViewController.childObjectId = _childObjectId;
            albumTableViewController.date = [tappedChildImage[@"date"] stringValue];
            albumTableViewController.month = [[tappedChildImage[@"date"] stringValue] substringWithRange:NSMakeRange(0, 6)];
            
            // _childImagesを更新したいのでリファレンスを渡す(2階層くらい渡すので別の方法があれば変えたいが)。
            NSMutableDictionary *section = [_childImages objectAtIndex:indexPath.section];
            NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
            albumTableViewController.totalImageNum = totalImageNum;
            albumTableViewController.indexPath = indexPath;
            albumTableViewController.uploadType = @"multi";
            
            [self.navigationController pushViewController:albumTableViewController animated:YES];
        } else {
            [self moveToMultiUploadViewController:[tappedChildImage[@"date"] stringValue] index:indexPath];
        }
        return;
    }
    
    if (![[self logic:@"isBestImageFixed"] isBestImageFixed:indexPath]) {
        // ベストショット決まってなければ即Pickerを開く
        AlbumTableViewController *albumTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumTableViewController"];
        albumTableViewController.month = [[tappedChildImage[@"date"]  stringValue ] substringWithRange:NSMakeRange(0, 6)];
        albumTableViewController.childObjectId = _childObjectId;
        albumTableViewController.date = [tappedChildImage[@"date"] stringValue];
        
        // _childImage更新用
        NSMutableDictionary *section = [_childImages objectAtIndex:indexPath.section];
        NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
        albumTableViewController.totalImageNum = totalImageNum;
        albumTableViewController.indexPath = indexPath;
        albumTableViewController.section = section;
        albumTableViewController.uploadType = @"single";
        [self.navigationController pushViewController:albumTableViewController animated:YES];
        return;
    }
    
    [self moveToImagePageViewController:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(self.view.frame.size.width, [[Config config][@"CollectionViewSectionHeaderHeight"] intValue]);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *headerView = [_pageContentCollectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"viewControllerHeader" forIndexPath:indexPath];
    for (UIView *v in [headerView subviews]) {
        [v removeFromSuperview];
    }
    
    NSString *year = [[_childImages objectAtIndex:indexPath.section] objectForKey:@"year"];
    NSString *month = [[_childImages objectAtIndex:indexPath.section] objectForKey:@"month"];
    
    CollectionViewSectionHeader *header = [CollectionViewSectionHeader view];
    header.delegate = self;
    header.sectionIndex = indexPath.section;
    [header setParmetersWithYear:[year integerValue] withMonth:[month integerValue]];
    [header adjustStyle:[self isExpandedSection:indexPath.section]];
   
    [headerView addSubview:header];
    
    return headerView;
}

- (void) moveToMultiUploadViewController:(NSString *)date index:(NSIndexPath *)indexPath
{
    MultiUploadViewController *multiUploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadViewController"];
    multiUploadViewController.childObjectId = childProperty[@"objectId"];
    multiUploadViewController.date = date;
    multiUploadViewController.month = [date substringWithRange:NSMakeRange(0, 6)];
    multiUploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    NSMutableDictionary *section = [_childImages objectAtIndex:indexPath.section];
    NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
    multiUploadViewController.totalImageNum = totalImageNum;
    multiUploadViewController.indexPath = indexPath;
    multiUploadViewController.pCVC = self;
	if (_bestImageIds[date]) {
		multiUploadViewController.bestImageId = _bestImageIds[date];
	} else {
		multiUploadViewController.bestImageId = @"";
	}
    
    [self.navigationController pushViewController:multiUploadViewController animated:YES];
}

- (void) moveToImagePageViewController:(NSIndexPath *)indexPath
{
    ImagePageViewController *pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ImagePageViewController"];
    pageViewController.childImages = [[self logic:@"screenSavedChildImages"] screenSavedChildImages];
    pageViewController.currentSection = indexPath.section;
    pageViewController.currentRow = [[self logic:@"currentIndexRowInSavedChildImages"] currentIndexRowInSavedChildImages:indexPath];
    pageViewController.showPageNavigation = NO; // PageContentViewControllerから表示する場合、全部で何枚あるかが可変なので出さない
    pageViewController.childObjectId = _childObjectId;
    pageViewController.imagesCountDic = _imagesCountDic;
    pageViewController.indexPath = indexPath;
    [self.navigationController setNavigationBarHidden:YES];
    [self.navigationController pushViewController:pageViewController animated:YES];
}

- (UIView *) makeCalenderLabel:(NSIndexPath *)indexPath cellFrame:(CGRect)cellFrame
{
    // 下準備
    float cellWidth = cellFrame.size.width;
    float cellHeight = cellFrame.size.height;
    NSMutableArray *weekdayArray = [[_childImages objectAtIndex:indexPath.section] objectForKey:@"weekdays"];
    NSString *weekdayString = [[NSString alloc] init];
    weekdayString = [DateUtils getWeekStringFromNum:[[weekdayArray objectAtIndex:indexPath.row] intValue]];
    PFObject *childImage = [[[_childImages objectAtIndex:indexPath.section] objectForKey:@"images"] objectAtIndex:indexPath.row];
    NSString *dd = [[childImage[@"date"] stringValue] substringWithRange:NSMakeRange(6, 2)];

    // カレンダーラベル組み立て
    CalenderLabel *calLabelView = [CalenderLabel view];
    if ([DateUtils isTodayByIndexPath:indexPath]) {
        calLabelView.frame = CGRectMake(2, 2, 54, 48);
        calLabelView.calLabelTop.frame = CGRectMake(0, 0, calLabelView.frame.size.width, 16);
        calLabelView.calLabelTopBehind.frame = CGRectMake(0, calLabelView.calLabelTop.frame.size.height/2, calLabelView.frame.size.width, calLabelView.calLabelTop.frame.size.height/2);
    } else {
        calLabelView.frame = CGRectMake(2, 2, 26, 27);
        calLabelView.calLabelTop.frame = CGRectMake(0, 0, calLabelView.frame.size.width, 9);
        calLabelView.calLabelTopBehind.frame = CGRectMake(0, calLabelView.calLabelTop.frame.size.height/2, calLabelView.frame.size.width, calLabelView.calLabelTop.frame.size.height/2);
    }
    calLabelView.calLabelBack.frame = CGRectMake(0, 0, calLabelView.frame.size.width, calLabelView.frame.size.height);
    calLabelView.calLabelBack.layer.cornerRadius = 3;
    calLabelView.calLabelTop.layer.cornerRadius = 3;
    
    if ([weekdayString isEqualToString:@"SUN"]) {
        calLabelView.calLabelTop.backgroundColor = [ColorUtils getSunDayCalColor];
        calLabelView.calLabelTopBehind.backgroundColor = [ColorUtils getSunDayCalColor];
    } else if ([weekdayString isEqualToString:@"SAT"]) {
        calLabelView.calLabelTop.backgroundColor = [ColorUtils getSatDayCalColor];
        calLabelView.calLabelTopBehind.backgroundColor = [ColorUtils getSatDayCalColor];
    } else {
        calLabelView.calLabelTop.backgroundColor = [ColorUtils getWeekDayCalColor];
        calLabelView.calLabelTopBehind.backgroundColor = [ColorUtils getWeekDayCalColor];
    }
    
    // カレンダーweekラベル
    UILabel *calWeekLabel = [[UILabel alloc] initWithFrame:calLabelView.calLabelTop.frame];
    calWeekLabel.textColor = [UIColor whiteColor];
    calWeekLabel.text = weekdayString;
    calWeekLabel.textAlignment = NSTextAlignmentCenter;
    [calLabelView.calLabelTop addSubview:calWeekLabel];
    
    // 日付ラベル
    UILabel *calDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, calLabelView.frame.size.height/3, calLabelView.frame.size.width, calLabelView.frame.size.height*2/3)];
    calDateLabel.textColor = [ColorUtils getCalenderNumberColor];
    calDateLabel.text = dd;
    calDateLabel.textAlignment = NSTextAlignmentCenter;
    [calLabelView.calLabelBack addSubview:calDateLabel];
    
    if ([DateUtils isTodayByIndexPath:indexPath]) {
        calWeekLabel.font = [UIFont fontWithName:@"Helvetica Bold" size:12];
        calDateLabel.font = [UIFont fontWithName:@"Helvetica" size:24];
    } else {
        calWeekLabel.font = [UIFont fontWithName:@"Helvetica Bold" size:9];
        calDateLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
    }
    
    return calLabelView;
}

- (UIView *)makeCommentNumLabel:(NSString *)ymd cellFrame:(CGRect)cellFrame
{
    CommentNumLabel *commentLabel = [CommentNumLabel view];
    CGRect frame = commentLabel.frame;
    frame.origin.x = cellFrame.size.width - frame.size.width - 2;
    frame.origin.y = cellFrame.size.height - frame.size.height - 1;
    commentLabel.frame = frame;

    NSString *key = [NSString stringWithFormat:@"%@%@", _childObjectId, ymd];
    if (commentNumForDate[key]) {
        [commentLabel setCommentNumber:[commentNumForDate[key] intValue]];
        return commentLabel;
    }
    return nil;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    _dragCount++;
    if (_dragCount % 10 != 0) {
        return;
    }
    if (_dragCount > 10000000) {
        _dragCount = 0;
    }
    
    NSArray* visibleCellIndex = _pageContentCollectionView.indexPathsForVisibleItems;
    NSDateComponents *visibleDateComp = [logic dateComps];
    int yyyymm = 999999;
    for (NSIndexPath *ip in visibleCellIndex) {
        int yyyymmTmp = [NSString stringWithFormat:@"%@%@", _childImages[ip.section][@"year"], _childImages[ip.section][@"month"]].intValue;
        if (yyyymm > yyyymmTmp) {
            yyyymm = yyyymmTmp;
            visibleDateComp.year = [_childImages[ip.section][@"year"] intValue];
            visibleDateComp.month = [_childImages[ip.section][@"month"] intValue];
        }
    }
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *visibleDate = [cal dateFromComponents:visibleDateComp];
    NSDate *loadedDate = [cal dateFromComponents:_dateComp];
    if ([visibleDate compare:loadedDate] == NSOrderedAscending) {
        if (_isLoading) {
            return;
        }
        
        _dateComp = visibleDateComp;
        [[self logic:@"getChildImagesWithYear"] getChildImagesWithYear:visibleDateComp.year withMonth:visibleDateComp.month withReload:YES];
    }
}

- (BOOL)notChoosedYet: (NSIndexPath *)indexPath
{
    NSMutableDictionary *section = [_childImages objectAtIndex:indexPath.section];
    NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
    
    if([totalImageNum isEqual:[NSNumber numberWithInt:-1]]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)adjustChildImages
{
    if (!_childImages || !_childImages.count < 1) {
        [self initializeChildImages];
        return;
    }
    PFObject *latestChildImage;
    PFObject *oldestChildImage;
    
    latestChildImage = _childImages[0][@"images"][0];
    NSMutableDictionary *oldestSection = _childImages[_childImages.count - 1];
    if (oldestSection) {
        oldestChildImage = oldestSection[@"images"][ [oldestSection[@"images"] count] - 1];
    }
    
    if (!latestChildImage || !oldestChildImage) {
        [self initializeChildImages];
        return;
    }
    
    NSDateComponents *todayComps = [[self logic:@"dateComps"] dateComps];
    
    NSNumber *todayNumber = [NSNumber numberWithInteger:
                             [[NSString stringWithFormat:@"%ld%02ld%02ld",
                               (long)todayComps.year,
                               (long)todayComps.month,
                               (long)todayComps.day
                               ] integerValue]];
    if ([todayNumber compare:latestChildImage[@"date"]] == NSOrderedAscending) {
        [_childImages removeAllObjects];
        [self initializeChildImages];
        return;
    }
    if ( ! (
            [latestChildImage[@"date"] isEqualToNumber:todayNumber] &&
            [oldestChildImage[@"date"] isEqualToNumber:[Config config][@"CalendarStartDate"]]
            
            )
    ) {
        [self initializeChildImages];
        return;
    }
}

- (void)initializeChildImages
{
    NSDateComponents *calendarStartingDateComps = [DateUtils compsFromNumber:[Config config][@"CalendarStartDate"]];
    NSDateComponents *todayComps = [[self logic:@"dateComps"] dateComps];    
    
    if (!_childImages) {
        _childImages = [[NSMutableArray alloc]init];
    }
    
    // 始点と終点の日付(NSDateComponents)を与えるとchildPropertyに自動追加してくれるmethodを作る必要がある
    [self addChildImagesWithStartDateComps:calendarStartingDateComps withEndDateComps:todayComps];
    
    [self setupChildImagesIndexMap];
    
    // scroll位置と表示月の関係
    [self setupScrollPositionData];
}

- (void)addChildImagesWithStartDateComps:(NSDateComponents *)startDateComps withEndDateComps:(NSDateComponents *)endDateComps
{
    NSDateComponents *twoMonthAgo = [DateUtils addDateComps:[logic dateComps] withUnit:@"month" withValue:-2];
    NSDateComponents *twoMonthAndOneDayAgo = [DateUtils addDateComps:twoMonthAgo withUnit:@"day" withValue:-1];
    [self addChildImagesFirstWithStartDateComps:twoMonthAgo withEndDateComps:endDateComps];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self addChildImagesFirstWithStartDateComps:startDateComps withEndDateComps:twoMonthAndOneDayAgo];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupChildImagesIndexMap];
            [_pageContentCollectionView reloadData];
            [self initializeClosedCellCountBySection];
    });
});
}

- (void)addChildImagesFirstWithStartDateComps:(NSDateComponents *)startDateComps withEndDateComps:(NSDateComponents *)endDateComps
{
    NSCalendar *cal   = [NSCalendar currentCalendar];
    NSDate *startDate = [cal dateFromComponents:startDateComps];
    NSDate *endDate   = [cal dateFromComponents:endDateComps];
    
    NSMutableDictionary *dicForCheckDuplicate = [[NSMutableDictionary alloc]init];
    
    while ([endDate compare:startDate] == NSOrderedDescending || [endDate compare:startDate] == NSOrderedSame) {
        NSString *ym = [NSString stringWithFormat:@"%ld%02ld", (long)endDateComps.year, (long)endDateComps.month];
        
        // childImagesの中に格納されているsectionの中にいまwhileで回している対象のymと同じ物が合ったらtargetSectionに突っ込む
        NSMutableDictionary *targetSection;
        for (NSMutableDictionary *section in _childImages) {
            NSString *yearMonthOfSection = [NSString stringWithFormat:@"%@%@", section[@"year"], section[@"month"]];
            if ([yearMonthOfSection isEqualToString:ym]) {
                targetSection = section;
                break;
            }
        }
        // なかったら、targetSectionを作り直す
        if (!targetSection) {
            targetSection = [[NSMutableDictionary alloc]init];
            targetSection[@"images"]        = [[NSMutableArray alloc]init];
            targetSection[@"totalImageNum"] = [[NSMutableArray alloc]init];
            targetSection[@"weekdays"]      = [[NSMutableArray alloc]init];
            targetSection[@"year"]          = [NSString stringWithFormat:@"%ld", (long)endDateComps.year];
            targetSection[@"month"]         = [NSString stringWithFormat:@"%02ld", (long)endDateComps.month];
            [_childImages addObject:targetSection];
        }

        NSNumber *date = [NSNumber numberWithInteger:[[NSString stringWithFormat:@"%ld%02ld%02ld", (long)endDateComps.year, (long)endDateComps.month, (long)endDateComps.day] integerValue]];
        if ([self isDuplicatedChildImage:dicForCheckDuplicate withYearMonth:ym withDate:date withTargetSection:targetSection]) {
            break; // childImagesが歯抜けになることはないので、duplicateになった時点で完成されていると判断する
        }
        
        PFObject *childImage = [[PFObject alloc]initWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]]];
        childImage[@"date"] = date;
        
        [self insertChildImage:childImage withSection:targetSection withComps:endDateComps];
        
        endDateComps = [DateUtils addDateComps:endDateComps withUnit:@"day" withValue:-1];
        endDate = [cal dateFromComponents:endDateComps];
    }
}

- (void)insertChildImage:(PFObject *)childImage withSection:(NSMutableDictionary *)targetSection withComps:(NSDateComponents *)endDateComps
{
    NSNumber *date = childImage[@"date"];
    
    // 最後の要素として追加するケースが多いので速度向上のため配列を逆にまわす
    int targetIndex = 0;
    for (int i = [targetSection[@"images"] count] - 1; i >= 0; i--) {
        PFObject *elem = targetSection[@"images"][i];
        if ([elem[@"date"] compare:date] == NSOrderedAscending) {
            continue;
        }
       
        targetIndex = i + 1;
        break;
    }
    [targetSection[@"images"] insertObject:childImage atIndex:targetIndex];
    [targetSection[@"totalImageNum"] insertObject:[NSNumber numberWithInt:-1] atIndex:targetIndex];
    [targetSection[@"weekdays"] insertObject:[NSNumber numberWithInteger:endDateComps.weekday] atIndex:targetIndex];
}

- (BOOL)isDuplicatedChildImage:(NSMutableDictionary *)dicForCheckDuplicate withYearMonth:(NSString *)ym withDate:(NSNumber *)date withTargetSection:(NSMutableDictionary *)targetSection
{
    if (!dicForCheckDuplicate[ym]) {
        [dicForCheckDuplicate removeAllObjects]; // メモリ節約
        dicForCheckDuplicate[ym] = [self dictionaryForYM:targetSection];
    }
    
    return dicForCheckDuplicate[ym][date] ? YES : NO;
}

- (NSMutableDictionary *)dictionaryForYM:(NSMutableDictionary *)targetSection
{
    NSMutableDictionary *dictionaryForYM = [[NSMutableDictionary alloc]init];
    for (PFObject *childImage in targetSection[@"images"]) {
        dictionaryForYM[childImage[@"date"]] = @"1";
    }
    return dictionaryForYM;
}

- (void)setupChildImagesIndexMap
{
    if (!_childImagesIndexMap) {
        _childImagesIndexMap = [[NSMutableDictionary alloc] init];
    } else {
        [_childImagesIndexMap removeAllObjects];
    }
    
    int n = 0;
    for (NSMutableDictionary *section in _childImages) {
        NSString *ym = [NSString stringWithFormat:@"%@%02ld", section[@"year"], (long)[section[@"month"] integerValue]];
        [_childImagesIndexMap setObject:[[NSNumber numberWithInt:n] stringValue] forKey:ym];
        n++;
    }
}

- (void)setupScrollPositionData
{
    _scrollPositionData = [[NSMutableArray alloc]init];
    for (NSMutableDictionary *section in _childImages) {
        NSInteger cellCount = [[section objectForKey:@"images"] count];
        double verticalCellCount = ceil(cellCount / 3);
        double requiredHeight = (verticalCellCount * self.view.frame.size.width / 3) + [[Config config][@"CollectionViewSectionHeaderHeight"] intValue] + 60; // 60: わからんが微調整用に必要
        NSNumber *n = [NSNumber numberWithDouble:requiredHeight];
        NSMutableDictionary *sectionHeightInfo = [[NSMutableDictionary alloc]initWithObjects:@[n, [section objectForKey:@"year"], [section objectForKey:@"month"]] forKeys:@[@"heightNumber", @"year", @"month"]];
        [_scrollPositionData addObject:sectionHeightInfo];
    }
}

- (void)setBackgroundViewOfCell:(CalendarCollectionViewCell *)cell withImageCachePath:(NSString *)imageCachePath withIndexPath:(NSIndexPath *)indexPath withYmd:(NSString *)ymd
{
    NSData *imageCacheData = [ImageCache getCache:imageCachePath dir:@""];
    NSString *role = _selfRole;
    
    NSMutableDictionary *section = [_childImages objectAtIndex:indexPath.section];
    NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
    
    // imageCacheDataが無い場合には条件によってPlaceHolderなどはめる
    if (!imageCacheData) {
        // 2日以内の場合には、candidateがあれば表示させる
        NSArray *candidateCaches = [[NSMutableArray alloc] initWithArray:[ImageCache getListOfMultiUploadCache:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", _childObjectId, ymd]]];
        if ([DateUtils isInTwodayByIndexPath:indexPath]) {
            if ([candidateCaches count] > 0) {
                // candidateの中から選択してはめる
                UIImage *multiCandidateImage = [ImageTrimming makeMultiCandidateImageWithBlur:candidateCaches childObjectId:_childObjectId ymd:ymd cellFrame:cell.frame];
                cell.backgroundView = [[UIImageView alloc] initWithImage:multiCandidateImage];
            } else {
                cell.backgroundView = [[UIImageView alloc] initWithImage:[self makeIconImageWithBlurWithCell:cell.frame]];
            }
        } else {
            cell.backgroundView = [[UIImageView alloc] initWithImage:[self makeIconImageWithBlurWithCell:cell.frame]];
        }
        
        // PlaceHolderアイコンなどをはめる
        if ([DateUtils isTodayByIndexPath:indexPath]) {
            CellImageFramePlaceHolderLarge *placeHolder = [CellImageFramePlaceHolderLarge view];
            CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
            placeHolder.frame = rect;
            [placeHolder setPlaceHolderForCell:cell indexPath:indexPath role:role candidateCount:[candidateCaches count]];
        } else {
            CellImageFramePlaceHolder *placeHolder = [CellImageFramePlaceHolder view];
            CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
            placeHolder.frame = rect;
            [placeHolder setPlaceHolderForCell:cell indexPath:indexPath role:role candidateCount:[candidateCaches count]];
        }
        return;
    }
    
    // best shotが既に選択済の場合は普通に写真を表示
    if ([DateUtils isTodayByIndexPath:indexPath]) {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectTopImage:[UIImage imageWithData:imageCacheData] ratio:(cell.frame.size.height/cell.frame.size.width)]];
    } else {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageWithData:imageCacheData]]];
    }
    // コメント数を付ける
    UIImageView *backgroundGridView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ImageBackgroundGrid"]];
    backgroundGridView.frame = CGRectMake(0, cell.frame.size.height - backgroundGridView.frame.size.height, cell.frame.size.width, 24);
    [cell.backgroundView addSubview:backgroundGridView];
    UIView *commentNumView = [self makeCommentNumLabel:ymd cellFrame:cell.frame];
    if (commentNumView) {
        [cell addSubview:commentNumView];
    }
    
    cell.isChoosed = YES;
}

- (NSMutableDictionary *)getYearMonthMap
{
    NSMutableDictionary *yearMonthMap = [[NSMutableDictionary alloc]init];
    for (NSMutableDictionary *section in _childImages) {
        NSString *year = [section objectForKey:@"year"];
        NSString *month = [section objectForKey:@"month"];

        if (![yearMonthMap objectForKey:year]) {
            [yearMonthMap setObject: [[NSMutableArray alloc]init] forKey:year];
        }
        [[yearMonthMap objectForKey:year] addObject:month];
    }
    return yearMonthMap;
}


- (void) giveMePhoto
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);

    NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
    transitionInfoDic[@"event"] = @"requestPhoto";
    transitionInfoDic[@"childObjectId"] = _childObjectId;
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    options[@"data"] = [[NSMutableDictionary alloc]
                        initWithObjects:@[@"Increment", transitionInfoDic]
                        forKeys:@[@"badge", @"transitionInfo"]];
    [PushNotification sendInBackground:@"requestPhoto" withOptions:options];
    
    NSInteger date;
    if ([requestPhotoDay isEqualToString:@"today"]) {
        date = [[DateUtils getTodayYMD] integerValue];
    } else {
        date = [[DateUtils getYesterdayYMD] integerValue];
    }
    
    PFObject *partner = (PFObject *)[Partner partnerUser];
    [NotificationHistory createNotificationHistoryWithType:@"requestPhoto" withTo:partner[@"userId"] withChild:_childObjectId withDate:date];
}

- (void)vibrate:(NSTimer *)timer
{
    NSDictionary *info = timer.userInfo;
    UIImageView *imageView = info[@"imageView"];
    NSMutableArray *posList = info[@"posList"];
    
    if (posList.count < 1) {
        [timer invalidate];
        return;
    }
    
    CGRect rect = [posList[0] CGRectValue];
    [posList removeObjectAtIndex:0];
    imageView.frame = rect;
}

- (void)addIntroductionOfImageRequestView:(NSTimer *)timer
{
    // すでにダイアログが表示されていたらCoreDataを戻してreturn
    if ([self alreadyDisplayedDialog]) {
        AppSetting *as = [AppSetting MR_findFirstByAttribute:@"name" withValue:[Config config][@"FinishedFirstLaunch"]];
        [as MR_deleteEntity];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        return;
    }
    // ダイアログを表示
    ImageRequestIntroductionView *view = [ImageRequestIntroductionView view];
    CGRect rect = view.frame;
    rect.origin.x = (self.view.frame.size.width - rect.size.width)/2;
    rect.origin.y = (self.view.frame.size.height - rect.size.height)/2;
    view.frame = rect;
    [self.view addSubview:view];
}

- (void)addIntroductionOfPageFlickView:(NSTimer *)timer
{
    // すでにダイアログが表示されていたらCoreDataを戻してreturn
    if ([self alreadyDisplayedDialog]) {
        AppSetting *as = [AppSetting MR_findFirstByAttribute:@"name" withValue:[Config config][@"FinishedIntroductionOfPageFlick"]];
        [as MR_deleteEntity];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        return;
    }
    // ダイアログを表示
    PageFlickIntroductionView *view = [PageFlickIntroductionView view];
    CGRect rect = view.frame;
    rect.origin.x = (self.view.frame.size.width - rect.size.width)/2;
    rect.origin.y = (self.view.frame.size.height - rect.size.height)/2;
    view.frame = rect;
    [self.view addSubview:view];
}

- (void)showAlertMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ネットワークエラー"
                                                    message:@"ネットワークの接続状況を確認してください"
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil
                          ];
    [alert show];
}

- (void)openFamilyApply
{
    [Tutorial forwardStageWithNextStage:@"familyApplyExec"];
    [_tn removeNavigationView];
    PartnerInviteViewController * partnerInviteViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PartnerInviteViewController"];
    [self.navigationController pushViewController:partnerInviteViewController animated:YES];
}

- (void)openFamilyApplyList
{
    [_tn removeNavigationView];
    FamilyApplyListViewController * familyApplyListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FamilyApplyListViewController"];
    [self.navigationController pushViewController:familyApplyListViewController animated:YES];
}

- (void)openPartnerWait
{
    [_tn removeNavigationView];
    PartnerWaitViewController * partnerWaitViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PartnerWaitViewController"];
    [self.navigationController pushViewController:partnerWaitViewController animated:YES];
}

- (void)showTutorialNavigator
{
    if (_tn) {
        [_tn removeNavigationView];
        _tn = nil;
    }
    _tn = [[TutorialNavigator alloc]init];
    _tn.targetViewController = self;
    [_tn showNavigationView];
}

- (void)forwardNextTutorial
{
    [[self logic:@"forwardNextTutorial"] forwardNextTutorial];
}

- (BOOL)alreadyDisplayedDialog
{
    NSArray *views = [self.view subviews];
    for (int i = 0; i < views.count; i++) {
        if ([views[i] isKindOfClass:[ImageRequestIntroductionView class]] ||
            [views[i] isKindOfClass:[PageFlickIntroductionView class]]    ||
            [views[i] isKindOfClass:[UploadPastImagesIntroductionView class]] ||
            [views[i] isKindOfClass:[AnnounceBoardView class]]) {
            return YES;
        }
    }
    return NO;
}

- (void)removeDialogs
{
    NSArray *views = [self.view subviews];
    for (int i = 0; i < views.count; i++) {
        if ([views[i] isKindOfClass:[ImageRequestIntroductionView class]] ||
            [views[i] isKindOfClass:[PageFlickIntroductionView class]]    ||
            [views[i] isKindOfClass:[UploadPastImagesIntroductionView class]]) {
            [views[i] removeFromSuperview];
        }
    }
}


- (void)showLoadingIcon
{
    _hud = nil;
    _hud.labelText = @"データ更新中";
    _hud.hidden = NO;
}

- (void)hideLoadingIcon
{
    [_hud hide:YES];
}

- (void)reloadPageContentView
{
    [self viewWillAppear:NO];
    [self viewDidAppear:NO];
}

- (void)rotateViewYAxis: (NSArray *)indexPathList
{
    NSMutableDictionary *targetIndexPath = [[NSMutableDictionary alloc]init];
    for (NSIndexPath *indexPath in indexPathList) {
        NSNumber *section = [NSNumber numberWithInteger: indexPath.section];
        NSNumber *row = [NSNumber numberWithInteger:indexPath.row];
        
        if (!targetIndexPath[section]) {
            targetIndexPath[section] = [[NSMutableDictionary alloc]init];
        }
        
        // 非同期でchildImagesが更新されるので、念のためここでもchildImagesをチェック
        PFObject *childImage = _childImages[indexPath.section][@"images"][indexPath.row];
        if (childImage.objectId) {
            continue;
        }
       
        targetIndexPath[section][row] = @"YES";
    }

    _isRotatingCells = YES;
    for (UIView *v in [_pageContentCollectionView subviews]) {
        if (![v isKindOfClass:[CalendarCollectionViewCell class]]) {
            continue;
        }
        CalendarCollectionViewCell *cell = (CalendarCollectionViewCell *)v;
        if (targetIndexPath[ [NSNumber numberWithInteger:cell.currentSection] ][ [NSNumber numberWithInteger:cell.currentRow] ]) {
            [cell rotate];
        }
    }
    // 1.0fはCalendarCollectionViewCellのdurationに合わせている
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(resetRotatingCells) userInfo:nil repeats:NO];
}

- (void)resetRotatingCells
{
    if (_skippedReloadData) {
        [_pageContentCollectionView reloadData];
    }
    _isRotatingCells = NO;
    _skippedReloadData = NO;
}

-(void)showAnnounceBoard
{
    NSString *currentStage = [Tutorial currentStage].currentStage;
    AppSetting *as = [AppSetting MR_findFirstByAttribute:@"name" withValue:@"finishedIntroductionToUploadPastImages"];
    
    // as が無ければshowIntroductionForFillingEmptyCellsを優先
    // チュートリアル中、既に他のDialogを表示中はreturn
    if (!as || ![currentStage isEqualToString:@"tutorialFinished"] || [self alreadyDisplayedDialog]) {
        return;
    }
    
    NSDictionary *info = [AnnounceBoardView getAnnounceInfo];
    if (!info || !info[@"title"] || [info[@"title"] isEqualToString:@""]) {
        return;
    }
    
    // 透明のviewで画面をブロック
    UIView *view = [[UIView alloc]init];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    view.frame = window.bounds;
    [window addSubview:view];
    [window bringSubviewToFront:view];
    
    AnnounceBoardView *dialog = [AnnounceBoardView view];
    CGRect rect = dialog.frame;
    rect.origin.x = (view.frame.size.width - rect.size.width) / 2;
    rect.origin.y = (view.frame.size.height - rect.size.height) / 2;
    dialog.frame = rect;
    dialog.titleLabel.text = info[@"title"];
    dialog.messageLabel.text = info[@"message"];
    dialog.pageContentViewController = self;
    dialog.childObjectId = _childObjectId;
    [view addSubview:dialog];
    
    [Logger writeOneShot:@"info" message:[NSString stringWithFormat:@"Show announce %@:", info[@"key"]]];
    
    // 表示済みフラグを立てる
    PFObject *announceHist = [PFObject objectWithClassName:@"AnnounceInfoHistory"];
    announceHist[@"userId"] = _currentUser[@"userId"];
    announceHist[@"displayed"] = info[@"key"];
    [announceHist saveInBackground];
}

- (void)showIntroductionForFillingEmptyCells
{
    NSString *currentStage = [Tutorial currentStage].currentStage;
    AppSetting *as = [AppSetting MR_findFirstByAttribute:@"name" withValue:@"finishedIntroductionToUploadPastImages"];
   
    if (
        as                                                 ||
        ![currentStage isEqualToString:@"familyApplyExec"] ||
        ![_selfRole isEqualToString:@"uploader"]           ||
        [self alreadyDisplayedDialog]
    ) {
        return;
    }
    
    AppSetting *newAppSetting = [AppSetting MR_createEntity];
    newAppSetting.name = @"finishedIntroductionToUploadPastImages";
    newAppSetting.value = @"1";
    newAppSetting.createdAt = [DateUtils setSystemTimezone:[NSDate date]];
    newAppSetting.updatedAt = [DateUtils setSystemTimezone:[NSDate date]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    // 対象cellのindexPathList
    // 対象のcellがない場合 = 既に写真をアップしているユーザ なので、AppSettingのレコードはできたままにする
    NSMutableArray *indexPathList = [self rotateTargetIndexPathList];
    if (indexPathList.count < 1) {
        return;
    }
    
    // 透明のviewで画面をブロック
    UIView *view = [[UIView alloc]init];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    view.frame = window.bounds;
    [window addSubview:view];
    [window bringSubviewToFront:view];
    
    // 少しスクロール
    [_pageContentCollectionView scrollToItemAtIndexPath:indexPathList[ indexPathList.count - 1 ] atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
  
    // ダイアログを出す
    UploadPastImagesIntroductionView *dialog = [UploadPastImagesIntroductionView view];
    CGRect rect = dialog.frame;
    rect.origin.x = (self.view.frame.size.width - rect.size.width) / 2;
    CGRect containerFrame = UIEdgeInsetsInsetRect(self.view.bounds, UIEdgeInsetsMake(self.navigationController.toolbar.frame.size.height + 20, 0, 0, 0)); // 20はstatus barの高さ
    rect.origin.y = containerFrame.size.height * 2 / 3;
    dialog.frame = rect;
    [self.view addSubview:dialog];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0f
                                     target:self
                                   selector:@selector(rotateEmptyCells:)
                                   userInfo:[NSMutableDictionary dictionaryWithObjects:@[view, indexPathList, [NSNumber numberWithInt:0]] forKeys:@[@"clearView", @"indexPathList", @"repeatCount"]]
                                    repeats:NO];
    
}

- (NSMutableArray *)rotateTargetIndexPathList
{
    NSMutableArray *indexPathList = [[NSMutableArray alloc]init];
    NSInteger totalIndex = 0;
    for (NSInteger sectionIndex = 0; sectionIndex < _childImages.count; sectionIndex++) {
        NSMutableDictionary *section = _childImages[sectionIndex];
        for (NSInteger rowIndex = 0; rowIndex < [section[@"images"] count]; rowIndex++) {
            PFObject *childImage = section[@"images"][rowIndex];
            if (childImage.objectId) { // 画像upload済
                totalIndex++;
                continue;
            }
            
            [indexPathList addObject:[NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex]];
            totalIndex++;
            
            if (totalIndex >= 7) {
                return indexPathList;
            }
        }
    }
    return indexPathList;
}

- (void)rotateEmptyCells:(NSTimer *)timer
{
    NSMutableDictionary *userInfo = [timer userInfo];
    
    // 透明viewを消す
    [userInfo[@"clearView"] removeFromSuperview];
    
    NSMutableArray *indexPathList = userInfo[@"indexPathList"];
    [self rotateViewYAxis:indexPathList];
}

- (BOOL)toggleCells:(NSInteger)sectionIndex
{
    BOOL doExpand = ![self isExpandedSection:sectionIndex];
    
    // 処理中はsection headerのタップをblockする
    if (isTogglingCells) {
        return !doExpand; // blockした場合はdelegate元のisExpandを更新しない
    }
    isTogglingCells = YES;
 
    // sectionIndexに含まれるcellのindexPathを作成
    NSMutableArray *indexPaths = [[NSMutableArray alloc]init];
    NSInteger i = -1;
    for (PFObject *childImage in _childImages[sectionIndex][@"images"]) {
        i++;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:sectionIndex];
        [indexPaths addObject:indexPath];
    }
    
    if (doExpand) {
        [_pageContentCollectionView performBatchUpdates:^{
            closedCellCountBySection[ [NSNumber numberWithInteger:sectionIndex] ] = [NSNumber numberWithInteger:0];
            [_pageContentCollectionView insertItemsAtIndexPaths:indexPaths];
        } completion:nil];
    } else {
        NSMutableArray *ips = [[NSMutableArray alloc]init];
        for (NSInteger i = indexPaths.count - 1; i >= 0 ; i--) {
            [ips addObject:indexPaths[i]];
            if (i % 3 == 0) {
                [_pageContentCollectionView performBatchUpdates:^{
                    NSNumber *n = closedCellCountBySection[ [NSNumber numberWithInteger:sectionIndex] ];
                    closedCellCountBySection[ [NSNumber numberWithInteger:sectionIndex] ] = [NSNumber numberWithInteger:[n integerValue] + ips.count];
                    [_pageContentCollectionView deleteItemsAtIndexPaths:ips];
                    [ips removeAllObjects];
                } completion:nil];
            }
        }
    }
    isTogglingCells = NO;
    
    return doExpand;
}

// 7ヶ月以上前のsectionはデフォルトで閉じる
- (void)initializeClosedCellCountBySection
{
    for (NSInteger i = 0; i < _childImages.count; i++) {
        if (i > 6) { // TODO confに切り出し
            closedCellCountBySection[ [NSNumber numberWithInteger:i] ]
                = [NSNumber numberWithInteger: [_childImages[i][@"images"] count] ];
        }
    }
    
}

- (BOOL)isExpandedSection:(NSInteger)sectionIndex
{
    BOOL isExpand = YES;
    if (closedCellCountBySection[ [NSNumber numberWithInteger:sectionIndex] ]) {
        NSInteger closedCellCount = [closedCellCountBySection[ [NSNumber numberWithInteger:sectionIndex] ] integerValue];
        if (closedCellCount > 0) {
            isExpand = NO;
        }
    }
    return isExpand;
}

- (void) downloadComplete
{
	[logic executeReload];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            break;
        case 1:
        {
            [self giveMePhoto];
        }
            break;
    }
}

- (UIImage *)makeIconImageWithBlurWithCell:(CGRect)cellFrame
{
    if (!iconImage) {
        iconImage = [UIImage imageWithData:[ImageCache getCache:[NSString stringWithFormat:@"%@Gray",[Config config][@"ChildIconFileName"]] dir:_childObjectId]];
    }
    
    UIImage *trimmedIconImage = [ImageTrimming makeRectTopImage:iconImage ratio:(cellFrame.size.height/cellFrame.size.width)];
    return trimmedIconImage;
}

@end
