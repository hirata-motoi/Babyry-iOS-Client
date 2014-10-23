//
//  ImagePageViewController.m
//  babyry
//
//  Created by hirata.motoi on 2014/07/26.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImagePageViewController.h"
#import "UploadViewController.h"
#import "ImageCache.h"
#import "AWSS3Utils.h"
#import "DateUtils.h"
#import "Config.h"
#import "Logger.h"
#import "ChildProperties.h"

@implementation ImagePageViewController
{
    NSDictionary *transitionInfo;
    NSMutableDictionary *childProperty;
    BOOL isPushTransition;
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
    NSLog(@"viewDidLoad in ImagePageViewController");
    // Do any additional setup after loading the view.
    self.dataSource = self;

    childProperty = [ChildProperties getChildProperty:_childObjectId];
    transitionInfo = [TransitionByPushNotification getInfo];
    if ([transitionInfo count] > 0) {
        isPushTransition = YES;
    } else {
        isPushTransition = NO;
    }
    _imageList = [[NSMutableArray alloc]init];
}

// 通常遷移
// 通常は_childImagesがセットされているのでsetupDataSourceを呼ぶ。
// setupDataSourceはviewWillAppearで呼ぶ必要がある。viewDidAppearで呼ぶと、ベースのViewを表示後にPageViewをセットし始めるので一瞬真っ暗な画面が出てしまう。
// _childImagesがセットされている状態では、setupDataSourceは時間がかからないのでviewDidAppearでも問題ない。

// Push後遷移
// _childImages(正確には必要なのは_imageList)がセットされていないので本ViewController内でセットする
// setupDataSourceInPushTransitionがそれ用のmethodであるが、同期的に取得するので多少時間がかかる。
// この処理をviewWillAppearでやると、Pushで開いた後に本ViewControllerに遷移してくる時間が結構かかる。
// そのため、viewWillAppearで空のImageをまずは表示させておき(showInitialImage)、ViewDidAppearで改めてPageViewをセットし直している

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    if (!isPushTransition) {
        [self setupDataSource];
    }
    [self showInitialImage];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    
    if (isPushTransition){
        [self setupDataSourceInPushTransition];
        [self showInitialImage];
    }
    
    // create bestshot index array
    if (_fromMultiUpload) {
        _bestImageIndexArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [_imagesCountDic[@"imagesCountNumber"] integerValue]; i++) {
            if ([_bestImageIndexNumber intValue] == i) {
                [_bestImageIndexArray addObject:@"YES"];
            } else {
                [_bestImageIndexArray addObject:@"NO"];
            }
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupDataSource
{
    NSInteger sectionIndex = 0;
    for (NSDictionary *sectionInfo in _childImages) {
        if (sectionIndex  == _indexPath.section) {
            _currentIndex = _imageList.count + _currentRow;
        }
        
        NSArray *images = [sectionInfo objectForKey:@"images"];
        [_imageList addObjectsFromArray:images];
        sectionIndex += 1;
    }
}

- (void)setupDataSourceInPushTransition
{
    _indexPath = [NSIndexPath indexPathForRow:[transitionInfo[@"row"] intValue] inSection:[transitionInfo[@"section"] intValue]];
    
    NSDate *date = [DateUtils setSystemTimezoneAndZero:[NSDate date]];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [[NSDateComponents alloc]init];
    comps.month = -_indexPath.section;
    
    NSDate *fromDate = [cal dateByAddingComponents:comps toDate:date options:0];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyyMM"];
    
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_group_t g = dispatch_group_create();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(2);
    
    dispatch_group_async(g,q,^{
        NSLog(@"_imageList構築");
        [self getChildImagesFrom:[[df stringFromDate:fromDate] integerValue] to:[[df stringFromDate:date] integerValue]];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_group_async(g,q,^{
        NSLog(@"総image数をカウント");
        _imagesCountDic = [[NSMutableDictionary alloc] init];
        _imagesCountDic[@"imagesCountNumber"] = [NSNumber numberWithInt:0];
        [self countTotalNumOfChildImages:0];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_group_wait(g, DISPATCH_TIME_FOREVER);
    NSLog(@"おわり");
    
    // TODO : Notification関連処理
    
    isPushTransition = NO;
}

- (UploadViewController *)viewControllerAtIndex:(NSInteger)index
{
    PFObject *imageInfo;
    if ([_imageList count] > 0) {
        imageInfo = [_imageList objectAtIndex:index];
    } else {
        imageInfo = nil;
    }
    UploadViewController *uploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UploadViewController"];
    uploadViewController.imageInfo = imageInfo;
    uploadViewController.childObjectId = _childObjectId;
    uploadViewController.name = _name;
   
    NSString *ymd = [[NSString alloc] init];
    if (imageInfo) {
        ymd   = [imageInfo[@"date"] stringValue];
    } else {
        ymd = transitionInfo[@"date"];
        NSLog(@"ymd %@", ymd);
    }
    NSString *year  = [ymd substringWithRange:NSMakeRange(0, 4)];
    NSString *month = [ymd substringWithRange:NSMakeRange(4, 2)];
    
    uploadViewController.month = [NSString stringWithFormat:@"%@%@", year, month];
    uploadViewController.date = ymd;
    uploadViewController.tagAlbumPageIndex = index;
    //uploadViewController.holdedBy = @"TagAlbumPageViewController";
    uploadViewController.fromMultiUpload = _fromMultiUpload;
    uploadViewController.indexPath = _indexPath;
    if (_fromMultiUpload) {
        uploadViewController.bestImageIndexArray = _bestImageIndexArray;
        uploadViewController.pageIndex = index;
        uploadViewController.myRole = _myRole;
        uploadViewController.childCachedImageArray = _childCachedImageArray;
    }
    
    if (_notificationHistory[ymd]) {
        uploadViewController.notificationHistoryByDay = _notificationHistory[ymd];
    }
    
    // Cacheからはりつけ
    NSString *imageCachePath = [[NSString alloc] init];
    NSString *cacheDir = [[NSString alloc]init];
    if (!_fromMultiUpload) {
        imageCachePath = ymd;
        cacheDir = [NSString stringWithFormat:@"%@/bestShot/thumbnail", _childObjectId];
    } else {
        imageCachePath = [_childCachedImageArray objectAtIndex:index];
        cacheDir = [NSString stringWithFormat:@"%@/candidate/%@/thumbnail", _childObjectId, ymd];
    }
    NSData *imageCacheData = [ImageCache getCache:imageCachePath dir:cacheDir];
    if(imageCacheData) {
        uploadViewController.uploadedImage = [UIImage imageWithData:imageCacheData];
    } else {
        uploadViewController.uploadedImage = [UIImage imageNamed:@"NoImage"];
    }
    uploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    if (_showPageNavigation) {
        NSInteger imagesCount = (_imagesCountDic && _imagesCountDic[@"imagesCountNumber"])
            ? [_imagesCountDic[@"imagesCountNumber"] integerValue]
            : _imageList.count;
        uploadViewController.promptText = [NSString stringWithFormat:@"%d/%ld", index + 1, (long)imagesCount];
    }
    
    if (!_fromMultiUpload) {
        [self laodMoreImages:index];
    }

//    // _childImagesの中身を更新するためにUploadViewにリファレンスを渡す (MultiUploadの場合はひとまず除外)
//    if (!_fromMultiUpload) {
//        NSMutableDictionary *section = [_childImages objectAtIndex:_indexPath.section];
//        NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
//        uploadViewController.totalImageNum = totalImageNum;
//        uploadViewController.currentRow = _currentRow;
//    }
    
    return uploadViewController;
}

- (void)showInitialImage
{
    UploadViewController *uploadViewController  = [self viewControllerAtIndex:_currentIndex];
    NSArray *viewControllers = @[uploadViewController];
    [self setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [uploadViewController didMoveToParentViewController:self];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    UploadViewController *uploadViewController = (UploadViewController *)viewController;
    
    NSInteger index = uploadViewController.tagAlbumPageIndex;
    
    if (index == NSNotFound || index == 0) {
        return nil;
    }
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    UploadViewController *uploadViewController = (UploadViewController *)viewController;
    
    NSInteger index = uploadViewController.tagAlbumPageIndex;
    
    if (isPushTransition) {
        if (index == NSNotFound || index == 0) {
            return nil;
        }
    }
    
    if (index == NSNotFound || index == self.imageList.count - 1) {
        return nil;
    }
    index++;
    return [self viewControllerAtIndex:index];
}

//- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
- (void)laodMoreImages:(NSInteger)index
{
    // TODO 必要に応じてparseから画像データを取得
    // 総枚数
    // 現在のimage数
    // 後10枚になったら次の月のデータを読み込む
    // 必要な値
    //   総枚数  imagesCountDicがあれば採用、なければreturn
    //   現在のimage数(_childImages.count)
    //   次の月
    //     データがなければさらに次の月を再帰的にとりにいく
    //     現在の月はpreviousviewControllers.monthで取得可能
    
    if (!_imagesCountDic || !_imagesCountDic[@"imagesCountNumber"]) {
        return;
    }
    if (_imageList.count >= [_imagesCountDic[@"imagesCountNumber"] integerValue]) {
        return;
    }
    if (_imageList.count - 10 <= index) {
        PFObject *lastChildImage = _imageList[ _imageList.count - 1 ];
        NSString *ymd = [lastChildImage[@"date"] stringValue];
        NSString *year = [ymd substringWithRange:NSMakeRange(0, 4)];
        NSString *month = [ymd substringWithRange:NSMakeRange(4, 2)];
        [self getChildImagesWithYear:[year integerValue] withMonth:[month integerValue]];
    }
}                          

- (void)getChildImagesWithYear:(NSInteger)year withMonth:(NSInteger)month
{
    if (_isLoading) {
        return;
    }
    _isLoading = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        [self getChildImagesRecursive:year withMonth:month];
        dispatch_sync(dispatch_get_main_queue(), ^{
        });
    });
}

- (void)getChildImagesRecursive:(NSInteger)year withMonth:(NSInteger)month
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [[NSDateComponents alloc]init];
    comps.year = year;
    comps.month = month;
    comps.day = 1;
    comps = [DateUtils addDateComps:comps withUnit:@"month" withValue:-1];
    NSDate *date = [cal dateFromComponents:comps];
    
    // 画像が取得できるまで処理する
    // 誕生日に達したら終了(誕生日がなければ2010年1月まで)
    // 画像が取得できたら終了
    
    // 誕生月
    NSDate *birthday = childProperty[@"birthday"];
    if (!birthday) {
        NSDateComponents *tmpComps = [[NSDateComponents alloc]init];
        tmpComps.year = 2010;
        tmpComps.month = 1;
        tmpComps.day = 1;
        birthday = [cal dateFromComponents:tmpComps];
    }
    NSDateComponents *birthmonthComps = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:birthday];
    birthmonthComps.day = 1;
    NSDate *birthmonth = [cal dateFromComponents:birthmonthComps];
   
    while ([date compare:birthmonth] != NSOrderedAscending) {
        NSDateComponents *c = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
        
        PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]]];
        [query whereKey:@"imageOf" equalTo:_childObjectId];
        [query whereKey:@"bestFlag" equalTo:@"choosed"];
        
        [query whereKey:@"date" greaterThanOrEqualTo:[NSNumber numberWithInteger:[[NSString stringWithFormat:@"%ld%02ld%02d", c.year, c.month, 1] integerValue]]];
        [query whereKey:@"date" lessThanOrEqualTo:[NSNumber numberWithInteger:[[NSString stringWithFormat:@"%ld%02ld%02d", c.year, c.month, 31] integerValue]]];
        [query orderByDescending:@"date"];
        NSArray *objects = [query findObjects];
  
        if (objects && objects.count > 0) {
            [_imageList addObjectsFromArray:objects];
            for (PFObject *childImage in objects) {
                [self cacheThumbnail:childImage];
            }
            break;
        }
        
        comps = [DateUtils addDateComps:comps withUnit:@"month" withValue:-1];
        date = [cal dateFromComponents:comps];
    }
    _isLoading = NO;
}

- (void)getChildImagesFrom:(NSInteger)fromYM to:(NSInteger)toYM
{
    PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]]];
    [query whereKey:@"imageOf" equalTo:_childObjectId];
    [query whereKey:@"bestFlag" equalTo:@"choosed"];
    
    [query whereKey:@"date" greaterThanOrEqualTo:[NSNumber numberWithInteger:[[NSString stringWithFormat:@"%04d%02d", fromYM, 1] integerValue]]];
    [query whereKey:@"date" lessThanOrEqualTo:[NSNumber numberWithInteger:[[NSString stringWithFormat:@"%04d%02d", toYM, 31] integerValue]]];
    [query orderByDescending:@"date"];
    NSArray *objects = [query findObjects];
    
    if (objects && objects.count > 0) {
        [_imageList addObjectsFromArray:objects];
        int index = 0;
        for (PFObject *childImage in objects) {
            if ([[childImage[@"date"] stringValue] isEqualToString:transitionInfo[@"date"]]) {
                _currentIndex = index;
            }
            [self cacheThumbnail:childImage];
            index++;
        }
    }
}

- (void)cacheThumbnail:(PFObject *)childImage
{
    NSString *ymd = [childImage[@"date"] stringValue];
    
    // まずはS3に接続
    AWSServiceConfiguration *configuration = [AWSS3Utils getAWSServiceConfiguration];
    AWSS3GetObjectRequest *getRequest = [AWSS3GetObjectRequest new];
    getRequest.bucket = [Config config][@"AWSBucketName"];
    getRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]], childImage.objectId];
    getRequest.responseCacheControl = @"no-cache";
    
    AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
    [[awsS3 getObject:getRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        if (!task.error && task.result) {
            AWSS3GetObjectOutput *getResult = (AWSS3GetObjectOutput *)task.result;
            NSString *thumbPath = [NSString stringWithFormat:@"%@%@thumb", _childObjectId, ymd];
            // cacheが存在しない場合 or cacheが存在するがS3のlastModifiledの方が新しい場合 は新規にcacheする
            if ([getResult.lastModified timeIntervalSinceDate:[ImageCache returnTimestamp:thumbPath]] > 0) {
                UIImage *thumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:getResult.body]];
                
                NSData *thumbData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(thumbImage, 0.7f)];
                [ImageCache
                    setCache:ymd
                    image:thumbData
                    dir:[NSString stringWithFormat:@"%@/bestShot/thumbnail", _childObjectId]];
            }
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in cacheThumbnail : %@", task.error]];
        }
        return nil;
    }];
}

- (void)countTotalNumOfChildImages:(int)skip
{
    NSString *className = [NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]];
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:@"imageOf" equalTo:_childObjectId];
    [query whereKey:@"bestFlag" equalTo:@"choosed"];
    query.skip = skip;
    query.limit = 1000;
    int count = [query countObjects];
    
    if (count > 1000) {
        [self countTotalNumOfChildImages:skip+1000];
    } else {
        NSNumber *totalCount = [NSNumber numberWithInt:skip + count];
        _imagesCountDic[@"imagesCountNumber"] = totalCount;
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

@end
