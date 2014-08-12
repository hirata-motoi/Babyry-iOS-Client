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


@implementation ImagePageViewController

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
    self.dataSource = self;
  
    [self setupDataSource];
    [self showInitialImage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupDataSource
{
    _imageList = [[NSMutableArray alloc]init];
    NSInteger sectionIndex = 0;
    for (NSDictionary *sectionInfo in _childImages) {
        if (sectionIndex  == _currentSection) {
            _currentIndex = _imageList.count + _currentRow;
        }
       
        NSArray *images = [sectionInfo objectForKey:@"images"];
        [_imageList addObjectsFromArray:images];
        sectionIndex += 1;
    }
}

- (UploadViewController *)viewControllerAtIndex:(NSInteger)index
{
    PFObject *imageInfo = [_imageList objectAtIndex:index];
    
    UploadViewController *uploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UploadViewController"];
    uploadViewController.childObjectId = _childObjectId;
    uploadViewController.name = _name;
   
    NSString *ymd   = [imageInfo[@"date"] substringWithRange:NSMakeRange(1, 8)];
    NSString *year  = [ymd substringWithRange:NSMakeRange(0, 4)];
    NSString *month = [ymd substringWithRange:NSMakeRange(4, 2)];
    
    uploadViewController.month = [NSString stringWithFormat:@"%@%@", year, month];
    uploadViewController.date = ymd;
    uploadViewController.tagAlbumPageIndex = index;
    uploadViewController.holdedBy = @"TagAlbumPageViewController";
    uploadViewController.child = _child;
    
    // Cacheからはりつけ
    NSString *imageCachePath = [[NSString alloc] init];
    if (!_fromMultiUpload) {
        imageCachePath = [NSString stringWithFormat:@"%@%@thumb", _childObjectId, ymd];
    } else {
        imageCachePath = [NSString stringWithFormat:@"%@%@-%d", _childObjectId, ymd, index];
    }
    NSData *imageCacheData = [ImageCache getCache:imageCachePath];
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
        uploadViewController.promptText = [NSString stringWithFormat:@"%ld/%ld", index + 1, imagesCount];
    }
    
    [self laodMoreImages:index];

    // _childImagesの中身を更新するためにUploadViewにリファレンスを渡す (MultiUploadの場合はひとまず除外)
    if (!_fromMultiUpload) {
        NSMutableDictionary *section = [_childImages objectAtIndex:_currentSection];
        NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
        uploadViewController.totalImageNum = totalImageNum;
        uploadViewController.currentRow = _currentRow;
    }
    
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
        NSString *year = [lastChildImage[@"date"] substringWithRange:NSMakeRange(1, 4)];
        NSString *month = [lastChildImage[@"date"] substringWithRange:NSMakeRange(5, 2)];
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
    NSDate *birthday = _child[@"birthday"];
    if (!birthday) {
        NSDateComponents *tmpComps = [[NSDateComponents alloc]init];
        tmpComps.year = 2014;
        tmpComps.month = 1;
        tmpComps.day = 1;
        birthday = [cal dateFromComponents:tmpComps];
    }
    NSDateComponents *birthmonthComps = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:birthday];
    birthmonthComps.day = 1;
    NSDate *birthmonth = [cal dateFromComponents:birthmonthComps];
   
    while ([date compare:birthmonth] != NSOrderedAscending) {
        NSDateComponents *c = [cal components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
        
        PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", [_child[@"childImageShardIndex"] integerValue]]];
        [query whereKey:@"imageOf" equalTo:_childObjectId];
        [query whereKey:@"bestFlag" equalTo:@"choosed"];
        [query whereKey:@"date" hasPrefix:[NSString stringWithFormat:@"D%ld%02ld", c.year, c.month]];
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

- (void)cacheThumbnail:(PFObject *)childImage
{
    NSString *ymd = [childImage[@"date"] substringWithRange:NSMakeRange(1, 8)];
    NSString *month = [ymd substringWithRange:NSMakeRange(0, 6)];
    
    // まずはS3に接続
    AWSServiceConfiguration *configuration = [AWSS3Utils getAWSServiceConfiguration];
    [[AWSS3Utils getObject:[NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", [_child[@"childImageShardIndex"] integerValue]], childImage.objectId] configuration:configuration] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        if (!task.error && task.result) {                                                                                                 
            AWSS3GetObjectOutput *getResult = (AWSS3GetObjectOutput *)task.result;
            NSString *thumbPath = [NSString stringWithFormat:@"%@%@thumb", _childObjectId, ymd];
            // cacheが存在しない場合 or cacheが存在するがS3のlastModifiledの方が新しい場合 は新規にcacheする
            if ([getResult.lastModified timeIntervalSinceDate:[ImageCache returnTimestamp:thumbPath]] > 0) {
                UIImage *thumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:getResult.body]];
                
                NSData *thumbData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(thumbImage, 0.7f)];
                [ImageCache setCache:[NSString stringWithFormat:@"%@%@thumb", _childObjectId, ymd] image:thumbData];
            }
        } else {
            // S3になければParseに
            [childImage[@"imageFile"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error){
                NSString *thumbPath = [NSString stringWithFormat:@"%@%@thumb", _childObjectId, ymd];
                // cacheが存在しない場合 or cacheが存在するがparseのupdatedAtの方が新しい場合 は新規にcacheする
                if ([childImage.updatedAt timeIntervalSinceDate:[ImageCache returnTimestamp:thumbPath]] > 0) {
                    UIImage *thumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:data]];
    
                    NSData *thumbData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(thumbImage, 0.7f)];
                    [ImageCache setCache:[NSString stringWithFormat:@"%@%@thumb", _childObjectId, ymd] image:thumbData];
                }
            }];
        }
        return nil;
    }];
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
