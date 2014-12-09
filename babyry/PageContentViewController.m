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
#import "CellBackgroundViewToEncourageUpload.h"
#import "CellBackgroundViewToEncourageUploadLarge.h"
#import "CellBackgroundViewToEncourageChoose.h"
#import "CellBackgroundViewToEncourageChooseLarge.h"
#import "CellBackgroundViewToWaitUpload.h"
#import "CellBackgroundViewToWaitUploadLarge.h"
#import "CellBackgroundViewNoImage.h"
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
    [self initializeChildImages];
    [self createCollectionView];
    //[self setupScrollBarView];
    
    windowWidth = self.view.frame.size.width;
    windowHeight = self.view.frame.size.height;
    bigRect = CGSizeMake(windowWidth, windowHeight - 44 - 20  - windowWidth*2/3);
    smallRect = CGSizeMake(windowWidth/3 - 2, windowWidth/3 - 2);
    
    alreadyRegisteredObserver = NO;
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.hidden = YES;
	
	_bestImageIds = [[NSMutableDictionary alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadComplete) name:@"downloadCompleteFromS3" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadComplete) name:@"partialDownloadCompleteFromS3" object:nil];
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
    
    [self adjustChildImages];
    [self reloadView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Notification登録
    if (!alreadyRegisteredObserver) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPageContentView) name:@"receivedCalendarAddedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillAppear:) name:@"applicationWillEnterForeground" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPageContentView) name:@"resetImage" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setImages) name:@"didUpdatedChildImageInfo" object:nil]; // for tutorial
        alreadyRegisteredObserver = YES;
    }
    
    // pushでの遷移の時はクルクルを出さない。クルクルを止める処理をする時にはViewが遷移してしまっていてUIの制御が出来なくなるような挙動をするため
    if (_isFirstLoad && [[TransitionByPushNotification getInfo] count] < 1) {
        _hud.labelText = @"データ同期中";
        _hud.hidden = NO;
    }
    
    [self setImages];
    if (!_tm || ![_tm isValid]) {
        _tm = [NSTimer scheduledTimerWithTimeInterval:60.0f target:self selector:@selector(setImages) userInfo:nil repeats:YES];
    }
//    [self showAnnounceBoard];
}

- (void)reloadView
{
    if ([PartnerApply linkComplete] && [_instructionTimer isValid]) {
        // この処理は一回だけで良し
        [Tutorial forwardStageWithNextStage:@"tutorialFinished"];
        [_instructionTimer invalidate];
        
        [ChildProperties asyncChildPropertiesWithBlock:^(NSMutableArray *beforeSyncChildProperties) {
            NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:n];
        
        }];
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
    if (section == _childImages.count - 1 && [[self logic:@"canAddCalendar"] canAddCalendar:section]) {
        return [_childImages[section][@"images"] count] + 1;
    }
    return [_childImages[section][@"images"] count];
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
   
    // カレンダー追加用cell
    if ([_childImages[indexPath.section][@"images"] count] <= indexPath.row) {
        [self setBackgroundViewOfCell:cell withImageCachePath:@"" withIndexPath:indexPath];
        
        if (indexPath.section == 0 && indexPath.row == 1) {
            CGRect rect = cell.frame;
            rect.origin.x = 0;
            cell.frame = rect;
        }
        return cell;
    }

    PFObject *childImage = [[[_childImages objectAtIndex:indexPath.section] objectForKey:@"images"] objectAtIndex:indexPath.row];
    
    // Cacheからはりつけ
    NSString *ymd = [childImage[@"date"] stringValue];
    NSString *imageCachePath = ([[self logic:@"isToday"] isToday:indexPath.section withRow:indexPath.row])
        ? [NSString stringWithFormat:@"%@/bestShot/fullsize/%@", _childObjectId , ymd]
        : [NSString stringWithFormat:@"%@/bestShot/thumbnail/%@", _childObjectId , ymd];

    [self setBackgroundViewOfCell:cell withImageCachePath:imageCachePath withIndexPath:indexPath];
    
    // カレンダーラベル付ける
    [cell addSubview:[self makeCalenderLabel:indexPath cellFrame:cell.frame]];
    
    [self setBadgeToCell:cell withIndexPath:(NSIndexPath *)indexPath withYMD:ymd];
    
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
    
    // カレンダー追加cell withinTwoDayがcallされる前にチェックしておく必要がある
    if ([_childImages[indexPath.section][@"images"] count] <= indexPath.row) {
        [[self logic:@"addMonthToCalendar"] addMonthToCalendar:indexPath];
        return;
    }
    
    // チェックの人がアップ催促する時は何の処理もしない
    if ([_selfRole isEqualToString:@"chooser"] && [[self logic:@"withinTwoDay"] withinTwoDay:indexPath]) {
        if ([[self logic:@"isNoImage"] isNoImage:indexPath]) {
            return;
        }
    }
    
    // チェック側、2日より前の時にも何もしない(No Image)
    if ([_selfRole isEqualToString:@"chooser"] && ![[self logic:@"withinTwoDay"] withinTwoDay:indexPath]) {
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
            albumTableViewController.notificationHistoryByDay = _notificationHistory[[tappedChildImage[@"date"] stringValue]];
            
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
    return CGSizeMake(self.view.frame.size.width, 30);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *headerView = [_pageContentCollectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"viewControllerHeader" forIndexPath:indexPath];
    
    
    NSString *year = [[_childImages objectAtIndex:indexPath.section] objectForKey:@"year"];
    NSString *month = [[_childImages objectAtIndex:indexPath.section] objectForKey:@"month"];
    
    CollectionViewSectionHeader *header = [CollectionViewSectionHeader view];
    [header setParmetersWithYear:[year integerValue] withMonth:[month integerValue] withName:childProperty[@"name"]];
   
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
    multiUploadViewController.notificationHistoryByDay = _notificationHistory[[date substringWithRange:NSMakeRange(0, 8)]];
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
    pageViewController.notificationHistory = _notificationHistory;
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
    if ([[self logic:@"isToday"] isToday:indexPath.section withRow:indexPath.row]) {
        calLabelView.frame = CGRectMake(cellWidth/20, cellHeight/20, cellWidth/6, cellHeight/6);
    } else {
        calLabelView.frame = CGRectMake(cellWidth/20, cellHeight/20, cellWidth/4, cellHeight/4);
    }
    calLabelView.calLabelBack.frame = CGRectMake(0, 0, calLabelView.frame.size.width, calLabelView.frame.size.height);
    calLabelView.calLabelBack.layer.cornerRadius = calLabelView.calLabelBack.frame.size.width/20;
    calLabelView.calLabelTop.frame = CGRectMake(0, 0, calLabelView.frame.size.width, calLabelView.frame.size.height/3);
    calLabelView.calLabelTop.layer.cornerRadius = calLabelView.frame.size.width/20;
    calLabelView.calLabelTopBehind.frame = CGRectMake(0, calLabelView.calLabelTop.frame.size.height/2, calLabelView.frame.size.width, calLabelView.calLabelTop.frame.size.height/2);
    
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
    calWeekLabel.font = [UIFont systemFontOfSize:calLabelView.calLabelTop.frame.size.height*0.8];
    calWeekLabel.textAlignment = NSTextAlignmentCenter;
    [calLabelView.calLabelTop addSubview:calWeekLabel];
    
    // 日付ラベル
    UILabel *calDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, calLabelView.frame.size.height/3, calLabelView.frame.size.width, calLabelView.frame.size.height*2/3)];
    calDateLabel.textColor = [UIColor blackColor];
    calDateLabel.text = dd;
    calDateLabel.font = [UIFont systemFontOfSize:calLabelView.calLabelTop.frame.size.height];
    calDateLabel.textAlignment = NSTextAlignmentCenter;
    [calLabelView.calLabelBack addSubview:calDateLabel];
    
    return calLabelView;
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
    
    _dragView.hidden = NO;
    // scroll位置からどの月を表示ようとしているかを判定
    // その月のデータをまだとってなければ取得
    [self reflectPageScrollToDragView];
    
    // 今のsection : _currentScrollSection
    NSDateComponents *currentYearMonth = [self getCurrentYearMonthByScrollPosition];
    _dragView.dragViewLabel.text = [NSString stringWithFormat:@"%ld%02ld", (long)currentYearMonth.year, (long)currentYearMonth.month];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *currentDate = [cal dateFromComponents:currentYearMonth];
    NSDate *loadedDate = [cal dateFromComponents:_dateComp];
    if ([currentDate compare:loadedDate] == NSOrderedAscending) {
        if (_isLoading) {
            return;
        }
        _dateComp = [DateUtils addDateComps:_dateComp withUnit:@"month" withValue:-1];
        NSDate *firstDate = [[self logic:@"getCollectionViewFirstDay"] getCollectionViewFirstDay];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMM"];
        NSString *firstDateString = [dateFormatter stringFromDate:firstDate];
        
        int firstDateInt = [firstDateString intValue];
        int nextLoadInt = [[NSString stringWithFormat:@"%ld%02ld", (long)_dateComp.year, (long)_dateComp.month] intValue];
        
        if (firstDateInt <= nextLoadInt) {
            [[self logic:@"getChildImagesWithYear"] getChildImagesWithYear:_dateComp.year withMonth:_dateComp.month withReload:YES];
        }                  
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

- (void)setupScrollBarView
{
    _dragViewUpperLimitOffset = 20;
    _dragViewLowerLimitOffset = self.view.bounds.size.height - 44 - 20 - 60;
    
    _dragView = [[DragView alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 70, _dragViewUpperLimitOffset, 70, 60)];
    _dragView.userInteractionEnabled = YES;
    _dragView.delegate = self;
    _dragView.dragViewLabel.text = [NSString stringWithFormat:@"%ld/%02ld", (long)_dateComp.year, (long)_dateComp.month];
    _dragView.dragViewLowerLimitOffset = _dragViewLowerLimitOffset;
    _dragView.dragViewUpperLimitOffset = _dragViewUpperLimitOffset;
    
    [self.view addSubview:_dragView];
}

- (void)drag:(DragView *)targetView
{
    _dragging = YES;
 
    // scrollViewを連動
    CGFloat contentHeight = _pageContentCollectionView.contentSize.height - (self.view.bounds.size.height - 64);
    CGFloat viewHeight = _dragViewLowerLimitOffset - _dragViewUpperLimitOffset;

    CGFloat rate = contentHeight / viewHeight ;
    
    CGFloat scrolledHeight = (targetView.frame.origin.y - _dragViewUpperLimitOffset) * rate;
    CGPoint scrolledPoint = CGPointMake(0, scrolledHeight);
    [_pageContentCollectionView setContentOffset:scrolledPoint];
    _dragging = NO;
}

- (void)adjustChildImages
{
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
    
    NSDateComponents *calendarStartingDateComps = [DateUtils compsFromNumber:[self getCalendarStartingDate]];
    NSDateComponents *todayComps = [[self logic:@"dateComps"] dateComps];
    
    NSNumber *calendarStartingDateNumber = [NSNumber numberWithInteger:
                                            [[NSString stringWithFormat:@"%ld%02ld%02ld",
                                              (long)calendarStartingDateComps.year,
                                              (long)calendarStartingDateComps.month,
                                              (long)calendarStartingDateComps.day
                                              ] integerValue]];
    NSNumber *todayNumber = [NSNumber numberWithInteger:
                             [[NSString stringWithFormat:@"%ld%02ld%02ld",
                               (long)todayComps.year,
                               (long)todayComps.month,
                               (long)todayComps.day
                               ] integerValue]];
                                                       
    if (
        [todayNumber compare:latestChildImage[@"date"]] == NSOrderedAscending ||
        [calendarStartingDateNumber compare:oldestChildImage[@"date"]] == NSOrderedDescending
    ) {
        [_childImages removeAllObjects];
        [self initializeChildImages];
        return;
    }
    
    if ( ! (
            [latestChildImage[@"date"] isEqualToNumber:todayNumber] &&
            [oldestChildImage[@"date"] isEqualToNumber:calendarStartingDateNumber]
            
            )
    ) {
        [self initializeChildImages];
        return;
    }
}

- (void)initializeChildImages
{
    NSDateComponents *calendarStartingDateComps = [DateUtils compsFromNumber:[self getCalendarStartingDate]];
    NSDateComponents *todayComps = [[self logic:@"dateComps"] dateComps];
    
    if (!_childImages) {
        _childImages = [[NSMutableArray alloc]init];
    }
    
    // 始点と終点の日付(NSDateComponents)を与えるとchildPropertyに自動追加してくれるmethodを作る必要がある
    [self addChildImages:_childImages withStartDateComps:calendarStartingDateComps withEndDateComps:todayComps];
    
    [self setupChildImagesIndexMap];
    
    // scroll位置と表示月の関係
    [self setupScrollPositionData];
}

- (NSNumber *)getCalendarStartingDate
{
    childProperty = [ChildProperties getChildProperty:_childObjectId];
    NSNumber *calendarStartDate = childProperty[@"calendarStartDate"];
    NSNumber *oldestChildImageDate = childProperty[@"oldestChildImageDate"];
    NSDate *birthday = childProperty[@"birthday"] ? childProperty[@"birthday"] : childProperty[@"createdAt"];
    
    if (calendarStartDate) {
        // calendarStartDateがある場合はcalendarStartDateをカレンダー開始日とする
        
        // ただしoldestChildImageDate < calendarStartDateの場合はoldestChildImageDateを起点にする
        if (oldestChildImageDate && [oldestChildImageDate compare:calendarStartDate] == NSOrderedAscending) {
            return oldestChildImageDate;
        } else {
            return calendarStartDate;
        }
    } else {
        // calendarStartDateがない場合は誕生日をカレンダー開始日とする
        NSDateComponents *birthdayComps = [DateUtils dateCompsFromDate:birthday];
        NSNumber *birthdayNumber = [NSNumber numberWithInteger:[[NSString stringWithFormat:@"%ld%02ld%02ld", (long)birthdayComps.year, (long)birthdayComps.month, (long)birthdayComps.day] integerValue]];
                                                                                                                                                                  
        // ただしoldestChildImageDate < birthdayの場合はoldestChildImageDateを起点にする
        if (oldestChildImageDate && [oldestChildImageDate compare:birthdayNumber] == NSOrderedAscending) {
            return oldestChildImageDate;
        } else {
            return birthdayNumber;
        }
    }
}

- (void)addChildImages:(NSMutableArray *)childImages withStartDateComps:(NSDateComponents *)startDateComps withEndDateComps:(NSDateComponents *)endDateComps
{
    NSCalendar *cal   = [NSCalendar currentCalendar];
    NSDate *startDate = [cal dateFromComponents:startDateComps];
    NSDate *endDate   = [cal dateFromComponents:endDateComps];
    
    NSMutableDictionary *dicForCheckDuplicate = [[NSMutableDictionary alloc]init];
    
    while ([endDate compare:startDate] == NSOrderedDescending || [endDate compare:startDate] == NSOrderedSame) {
        NSString *ym = [NSString stringWithFormat:@"%ld%02ld", (long)endDateComps.year, (long)endDateComps.month];
                                                               
        NSMutableDictionary *targetSection;
        for (NSMutableDictionary *section in childImages) {
            NSString *yearMonthOfSection = [NSString stringWithFormat:@"%@%@", section[@"year"], section[@"month"]];
            if ([yearMonthOfSection isEqualToString:ym]) {
                targetSection = section;
                break;
            }
        }
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
            endDateComps = [DateUtils addDateComps:endDateComps withUnit:@"day" withValue:-1];
            endDate = [cal dateFromComponents:endDateComps];
            continue;
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
    _childImagesIndexMap = [[NSMutableDictionary alloc] init];
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
        double requiredHeight = (verticalCellCount * self.view.frame.size.width / 3) + 30 + 60; // 30 : section header  60: わからんが微調整用に必要
        NSNumber *n = [NSNumber numberWithDouble:requiredHeight];
        NSMutableDictionary *sectionHeightInfo = [[NSMutableDictionary alloc]initWithObjects:@[n, [section objectForKey:@"year"], [section objectForKey:@"month"]] forKeys:@[@"heightNumber", @"year", @"month"]];
        [_scrollPositionData addObject:sectionHeightInfo];
    }
}

- (NSDateComponents *)getCurrentYearMonthByScrollPosition
{
    CGFloat hiddenHeight = _pageContentCollectionView.contentSize.height - (_pageContentCollectionView.contentOffset.y + (_pageContentCollectionView.bounds.size.height - 64)/2);
    
    NSDateComponents *c = [[NSDateComponents alloc]init];
    [c setYear:[[[_childImages objectAtIndex:0] objectForKey:@"year"] intValue]];
    [c setMonth:[[[_childImages objectAtIndex:0] objectForKey:@"month"] intValue]];
    
    CGFloat sectionHeightSum = 0.0f;
    for (NSInteger i = [_scrollPositionData count] - 1; i >= 0; i--) {
        CGFloat sectionHeight = [[[_scrollPositionData objectAtIndex:i] objectForKey:@"heightNumber"] floatValue];
        sectionHeightSum += sectionHeight;
        
        if (sectionHeightSum >= hiddenHeight) {
            
            NSString *yearString = [[_scrollPositionData objectAtIndex:i] objectForKey:@"year"];
            NSString *monthString = [[_scrollPositionData objectAtIndex:i] objectForKey:@"month"];
            [c setYear: [yearString integerValue]];
            [c setMonth: [monthString integerValue]];
            break;
        }
    }
    return c;
}

- (void)reflectPageScrollToDragView
{
    if (_dragging) {
        return;
    }
    CGFloat contentHeight = _pageContentCollectionView.contentSize.height - (self.view.bounds.size.height - 64);
    CGFloat viewHeight = _dragViewLowerLimitOffset - _dragViewUpperLimitOffset;

    CGFloat rate = viewHeight / contentHeight;
    CGFloat dragViewOffset = _pageContentCollectionView.contentOffset.y * rate;
   
    int dragViewOffsetInt = [[NSNumber numberWithFloat:dragViewOffset] intValue];
    
    CGPoint movedPoint = CGPointMake(_dragView.center.x, dragViewOffsetInt + _dragView.frame.size.height / 2 + _dragViewUpperLimitOffset);
    _dragView.center = movedPoint;
}

- (void)setBackgroundViewOfCell:(CalendarCollectionViewCell *)cell withImageCachePath:(NSString *)imageCachePath withIndexPath:(NSIndexPath *)indexPath
{
    NSData *imageCacheData = [ImageCache getCache:imageCachePath dir:@""];
    NSString *role = _selfRole;
    
    NSMutableDictionary *section = [_childImages objectAtIndex:indexPath.section];
    NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
    if (!imageCacheData) {
        if ([section[@"images"] count] <= indexPath.row) {
            // カレンダー追加用のcell
            PFObject *oldestChildImage = section[@"images"][indexPath.row - 1];
            NSNumber *oldestChildImageDate = oldestChildImage[@"date"];
            NSDateComponents *comps = [[self logic:@"compsToAdd"] compsToAdd:oldestChildImageDate];
            AddMonthToCalendarView *backgroundView = [AddMonthToCalendarView view];
            CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
            backgroundView.frame = rect;
            backgroundView.messageLabel.text = [NSString stringWithFormat:@"カレンダー追加\n(%ld月分)", comps.month];
            [cell addSubview:backgroundView];
        } else if ([role isEqualToString:@"uploader"]) {
            // アップの出し分け
            // アップしたが、チョイスされていない(=> totalImageNum = (0|-1))場合 かつ 今日or昨日の場合 : チョイス催促アイコン
            // それ以外 : アップアイコン
            
            if([[self logic:@"withinTwoDay"] withinTwoDay:indexPath] && [[self logic:@"isNoImage"] isNoImage:indexPath]) {
                // チョイス催促をいれてもいいけど、いまは UP PHOTO アイコンをはめている
                if ([[self logic:@"isToday"] isToday:indexPath.section withRow:indexPath.row]) {
                    CellBackgroundViewToEncourageUploadLarge *backgroundView = [CellBackgroundViewToEncourageUploadLarge view];
                    CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
                    backgroundView.frame = rect;
                    backgroundView.iconView.frame = rect;
                    [cell addSubview:backgroundView];
                } else {
                    CellBackgroundViewToEncourageUpload *backgroundView = [CellBackgroundViewToEncourageUpload view];
                    CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
                    backgroundView.frame = rect;
                    backgroundView.iconView.frame = rect;
                    [cell addSubview:backgroundView];
                }
            } else {
                // アップアイコン
                if ([[self logic:@"isToday"] isToday:indexPath.section withRow:indexPath.row]) {
                    CellBackgroundViewToEncourageUploadLarge *backgroundView = [CellBackgroundViewToEncourageUploadLarge view];
                    CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
                    backgroundView.frame = rect;
                    backgroundView.iconView.frame = rect;
                    [cell addSubview:backgroundView];
                } else {
                    CellBackgroundViewToEncourageUpload *backgroundView = [CellBackgroundViewToEncourageUpload view];
                    CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
                    backgroundView.frame = rect;
                    backgroundView.iconView.frame = rect;
                    [cell addSubview:backgroundView];
                }
            }
        } else {
            // チョイスの出し分け
            // 今日 or 昨日
            //// アップ済み : チョイス催促、　未アップ : アップ催促
            // ２日以上たったらNoImage
            if ([[self logic:@"withinTwoDay"] withinTwoDay:indexPath]) {
                // アップ催促
                if ([[self logic:@"isNoImage"] isNoImage:indexPath]) {
                    if ([[self logic:@"isToday"] isToday:indexPath.section withRow:indexPath.row]) {
                        CellBackgroundViewToWaitUploadLarge *backgroundView = [CellBackgroundViewToWaitUploadLarge view];
                        CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
                        backgroundView.frame = rect;
                        backgroundView.iconView.frame = rect;
                        [cell addSubview:backgroundView];
                    } else {
                        CellBackgroundViewToWaitUpload *backgroundView = [CellBackgroundViewToWaitUpload view];
                        CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
                        backgroundView.frame = rect;
                        backgroundView.iconView.frame = rect;
                        [cell addSubview:backgroundView];
                    }
                    // ダブルタップでプッシュ通知
                    UITapGestureRecognizer *giveMePhotoGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(giveMePhoto:)];
                    giveMePhotoGesture.numberOfTapsRequired = 2;
                    [cell addGestureRecognizer:giveMePhotoGesture];
                } else {
                    // チョイス促進アイコン貼る
                    NSNumber *uploadedNum = [totalImageNum objectAtIndex:indexPath.row];
                    if ([[self logic:@"isToday"] isToday:indexPath.section withRow:indexPath.row]) {
                        CellBackgroundViewToEncourageChooseLarge *backgroundView = [CellBackgroundViewToEncourageChooseLarge view];
                        CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
                        backgroundView.frame = rect;
                        rect = CGRectMake(0, cell.frame.size.height - backgroundView.upCountLabel.frame.size.height, cell.frame.size.width - 10, backgroundView.upCountLabel.frame.size.height);
                        backgroundView.upCountLabel.frame = rect;
                        backgroundView.upCountLabel.text = [NSString stringWithFormat:@"%@ PHOTO AVAILABLE", uploadedNum];
                        [cell addSubview:backgroundView];
                    } else {
                        CellBackgroundViewToEncourageChoose *backgroundView = [CellBackgroundViewToEncourageChoose view];
                        CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
                        backgroundView.frame = rect;
                        rect = CGRectMake(0, cell.frame.size.height - backgroundView.upCountLabel.frame.size.height, cell.frame.size.width - 5, backgroundView.upCountLabel.frame.size.height);
                        backgroundView.upCountLabel.frame = rect;
                        backgroundView.upCountLabel.text = [NSString stringWithFormat:@"%@ PHOTO AVAILABLE", uploadedNum];
                        [cell addSubview:backgroundView];
                    }
                }
            } else {
                CellBackgroundViewNoImage *backgroundView = [CellBackgroundViewNoImage view];
                CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
                backgroundView.frame = rect;
                backgroundView.iconView.frame = rect;
                [cell addSubview:backgroundView];
            }
        }
        return;
    }
    
    // best shotが既に選択済の場合は普通に写真を表示
    if ([[self logic:@"isToday"] isToday:indexPath.section withRow:indexPath.row]) {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectTopImage:[UIImage imageWithData:imageCacheData] ratio:(cell.frame.size.height/cell.frame.size.width)]];
    } else {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageWithData:imageCacheData]]];
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


- (void) giveMePhoto:(id)sender
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    CalendarCollectionViewCell *cell = [sender view];
    for (id elem in [cell subviews]) {
        if ([elem isKindOfClass:[CellBackgroundViewToWaitUpload class]] || [elem isKindOfClass:[CellBackgroundViewToWaitUploadLarge class]]) {
            for (UIImageView *imageView in [elem subviews]) {
                [self vibrateImageView:imageView];
            }
        }
    }
    
    NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
    transitionInfoDic[@"event"] = @"requestPhoto";
    transitionInfoDic[@"childObjectId"] = _childObjectId;
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    options[@"data"] = [[NSMutableDictionary alloc]
                        initWithObjects:@[@"Increment", transitionInfoDic]
                        forKeys:@[@"badge", @"transitionInfo"]];
    [PushNotification sendInBackground:@"requestPhoto" withOptions:options];
    
    
    PFObject *childImage = [[[_childImages objectAtIndex:0] objectForKey:@"images"] objectAtIndex:[sender view].tag];
    NSString *ymd = [childImage[@"date"] stringValue];
    PFObject *partner = (PFObject *)[Partner partnerUser];
    [NotificationHistory createNotificationHistoryWithType:@"requestPhoto" withTo:partner[@"userId"] withChild:_childObjectId withDate:[ymd integerValue]];
}


// コメントはコメントアイコン、それ以外はいわゆるbadgeを表示する
- (void)setBadgeToCell:(CalendarCollectionViewCell *)cell withIndexPath:(NSIndexPath *)indexPath withYMD:ymd
{
    NSMutableDictionary *histories = _notificationHistory[ymd];
    if (!histories) {
        return;
    }
    
    NSMutableArray *badges = [[NSMutableArray alloc]init];
    
    // コメント
    NSMutableArray *commentNotifications = histories[@"commentPosted"];
    if (commentNotifications && commentNotifications.count > 0) {
        // コメントアイコン内に数字をいれる
        UIImageView *commentBadge = [Badge badgeViewWithType:@"commentPosted" withCount:commentNotifications.count];
        [badges addObject:commentBadge];
    }
   
    // bestShotChanged・bestShotReply・imageUPloadedを取得
    NSMutableArray *bestShotChangeNotifications = histories[@"bestShotChanged"];
    if (!bestShotChangeNotifications) {
        bestShotChangeNotifications = [[NSMutableArray alloc]init];
    }
    NSMutableArray *bestShotReplyNotifications = histories[@"bestShotReply"];
    if (!bestShotReplyNotifications) {
        bestShotReplyNotifications = [[NSMutableArray alloc]init];
    }
    NSMutableArray *imageUploadedNotifications = histories[@"imageUploaded"];
    if (!imageUploadedNotifications) {
        imageUploadedNotifications = [[NSMutableArray alloc]init];
    }
    if (bestShotChangeNotifications.count > 0 || bestShotReplyNotifications.count > 0 || imageUploadedNotifications.count > 0) {
        // badgeをつける
        NSInteger count = bestShotChangeNotifications.count + bestShotReplyNotifications.count + imageUploadedNotifications.count;
        UIView *badge = [Badge badgeViewWithType:nil withCount:count];
        [badges addObject:badge];
    }
   
    // badgeをcell右下に配置
    NSInteger c = 0;
    for (UIView *badge in badges) {
        CGRect rect = badge.frame;
        rect.origin.y = cell.frame.size.height - rect.size.height - 5; // 5:余白
        rect.origin.x = cell.frame.size.width - (rect.size.width + 5) * (c + 1);
        badge.frame = rect;
        [cell addSubview:badge];
        c++;
    }
    
    // give me photoのラベルはる
    // 基本的には1つしか無いはずなので、最初の一つをとる
    // ただし、表示するのは、section = 0, row = 0,1だけ
    // かつ uploaderだけ
//    if ([[FamilyRole selfRole:@"useCache"] isEqualToString:@"uploader"]) {
//        if (indexPath.section == 0 && (indexPath.row == 0 || indexPath.row == 1)) {
//            if (histories[@"requestPhoto"] && [histories[@"requestPhoto"] count] > 0) {
//                // 左下にそっと出してみる
//                float cellHeigt = cell.frame.size.height;
//                float cellWidth = cell.frame.size.width;
//                int widthRatio = 4;
//                if (indexPath.row == 1) {
//                    widthRatio = 3;
//                }
//                CGRect rect = CGRectMake(0, cellHeigt - cellHeigt/widthRatio, cellWidth/widthRatio, cellHeigt/widthRatio);
//                UIImage *giveMePhotoIcon = [UIImage imageNamed:@"GiveMePhotoIcon"];
//                UIImageView *giveMePhotoIconView = [[UIImageView alloc] initWithImage:giveMePhotoIcon];
//                giveMePhotoIconView.frame = rect;
//                [cell addSubview:giveMePhotoIconView];
//            }
//        }
//    }
}

- (void)vibrateImageView:(UIImageView *)imageView
{
    CGRect rect = imageView.frame;
    
    CGRect rightRect = rect;
    rightRect.origin.x += 5;
    NSValue *rightRectObj = [NSValue valueWithCGRect:rightRect];
    
    CGRect leftRect = rect;
    leftRect.origin.x -= 5;
    NSValue *leftRectObj = [NSValue valueWithCGRect:leftRect];
    
    NSValue *originalRectObj = [NSValue valueWithCGRect:rect];
    
    
    NSMutableArray *posList = [[NSMutableArray alloc]initWithObjects:rightRectObj, leftRectObj, rightRectObj, leftRectObj, originalRectObj , nil];
    
    NSMutableDictionary *info = [[NSMutableDictionary alloc]init];
    info[@"imageView"] = imageView;
    info[@"posList"] = posList;
    NSTimer *tm = [NSTimer scheduledTimerWithTimeInterval:0.03f target:self selector:@selector(vibrate:) userInfo:info repeats:YES];
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

- (void) downloadComplete
{
	[logic executeReload];
}

@end
