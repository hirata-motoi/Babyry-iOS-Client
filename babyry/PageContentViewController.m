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
#import "MultiUploadAlbumTableViewController.h"
#import "ImageTrimming.h"
#import "ImageCache.h"
#import "FamilyRole.h"
#import "ImagePageViewController.h"
#import "ArrayUtils.h"
#import "TagAlbumCollectionViewCell.h"
#import "DateUtils.h"
#import "DragView.h"
#import "CellBackgroundViewToEncourageUpload.h"
#import "CellBackgroundViewToEncourageUploadLarge.h"
#import "CellBackgroundViewToEncourageChoose.h"
#import "CellBackgroundViewToEncourageChooseLarge.h"
#import "CellBackgroundViewToWaitUpload.h"
#import "CellBackgroundViewToWaitUploadLarge.h"
#import "CellBackgroundViewNoImage.h"
#import "CalenderLabel.h"
#import "PushNotification.h"
#import "UploadPickerViewController.h"

@interface PageContentViewController ()

@end

@implementation PageContentViewController

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
    
    _configuration = [AWSS3Utils getAWSServiceConfiguration];
    
    _isFirstLoad = 1;
    _currentUser = [PFUser currentUser];
    
    [self initializeChildImages];
    
    [self createCollectionView];
    [self showChildImages];
    
    //[self setupScrollBarView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    _selfRole = [FamilyRole selfRole];
    [_pageContentCollectionView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void)createCollectionView
{
    // UICollectionViewの土台を作成
    _pageContentCollectionView.delegate = self;
    _pageContentCollectionView.dataSource = self;
    [_pageContentCollectionView registerClass:[TagAlbumCollectionViewCell class] forCellWithReuseIdentifier:@"PageContentCollectionView"];
    [_pageContentCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"viewControllerHeader"];
    
    [self.view addSubview:_pageContentCollectionView];
}

// セルの数を指定するメソッド
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[[_childImages objectAtIndex:section] objectForKey:@"images"] count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [_childImages count];
}

// セルの大きさを指定するメソッド
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    float width = self.view.frame.size.width;
    if (indexPath.section == 0 && indexPath.row == 0) {
        return CGSizeMake(width, self.view.frame.size.height - 44 - 20  - width*2/3); // TODO magic number
    }
    return CGSizeMake(width/3 - 2, width/3 - 2);
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
-(TagAlbumCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //セルを再利用 or 再生成
    TagAlbumCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PageContentCollectionView" forIndexPath:indexPath];
    for (UIView *view in [cell subviews]) {
        [view removeFromSuperview];
    }

    PFObject *childImage = [[[_childImages objectAtIndex:indexPath.section] objectForKey:@"images"] objectAtIndex:indexPath.row];
    
    NSMutableArray *weekdayArray = [[_childImages objectAtIndex:indexPath.section] objectForKey:@"weekdays"];
    NSString *weekdayString = [[NSString alloc] init];
    weekdayString = [DateUtils getWeekStringFromNum:[[weekdayArray objectAtIndex:indexPath.row] intValue]];
    
    // Cacheからはりつけ
    NSString *ymd = [childImage[@"date"] substringWithRange:NSMakeRange(1, 8)];
    NSString *dd = [ymd substringWithRange:NSMakeRange(6, 2)];
    
    NSString *imageCachePath = [NSString stringWithFormat:@"%@%@thumb", _childObjectId , ymd];
    [self setBackgroundViewOfCell:cell withImageCachePath:imageCachePath withIndexPath:indexPath];
    
    float cellWidth = cell.frame.size.width;
    float cellHeight = cell.frame.size.height;
    
    // カレンダーラベル
    CalenderLabel *calLabelView = [CalenderLabel view];
    if (indexPath.row == 0 && indexPath.section == 0) {
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
        calLabelView.calLabelTop.backgroundColor = [UIColor colorWithRed:1.0 green:0.396 blue:0.047 alpha:1.0];
        calLabelView.calLabelTopBehind.backgroundColor = [UIColor colorWithRed:1.0 green:0.396 blue:0.047 alpha:1.0];
    } else if ([weekdayString isEqualToString:@"SAT"]) {
        calLabelView.calLabelTop.backgroundColor = [UIColor colorWithRed:0.510 green:0.635 blue:0.773 alpha:1.0];
        calLabelView.calLabelTopBehind.backgroundColor = [UIColor colorWithRed:0.510 green:0.635 blue:0.773 alpha:1.0];
    } else {
        calLabelView.calLabelTop.backgroundColor = [UIColor colorWithRed:0.941 green:0.702 blue:0.216 alpha:1.0];
        calLabelView.calLabelTopBehind.backgroundColor = [UIColor colorWithRed:0.941 green:0.702 blue:0.216 alpha:1.0];
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

    [cell addSubview:calLabelView];
     
    cell.tag = indexPath.row + 1;

    // 月の2日目の時に、1日のサムネイルが中央寄せとなって表示されてしまうためorigin.xを無理矢理設定
    if (indexPath.section == 0 && indexPath.row == 1) {
        CGRect rect = cell.frame;
        rect.origin.x = 0;
        cell.frame = rect;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // チェックの人がアップ催促する時だけここは何の処理もしない
    if ([_selfRole isEqualToString:@"chooser"] && [self withinTwoDay:indexPath]) {
        if ([self isNoImage:indexPath]) {
            return;
        }
    }
    
    PFObject *tappedChildImage = [[[_childImages objectAtIndex:indexPath.section] objectForKey:@"images"] objectAtIndex:indexPath.row];
    // chooser
    //    upload待ち
    //    BS選択
    // uploader
    //    +ボタンがないパターン
    if ([self shouldShowMultiUploadView:indexPath]) {
        if ([self isNoImage:indexPath]) {
            MultiUploadAlbumTableViewController *multiUploadAlbumTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadAlbumTableViewController"];
            multiUploadAlbumTableViewController.childObjectId = _childObjectId;
            multiUploadAlbumTableViewController.date = [tappedChildImage[@"date"] substringWithRange:NSMakeRange(1, 8)];
            multiUploadAlbumTableViewController.month = [tappedChildImage[@"date"] substringWithRange:NSMakeRange(1, 6)];
            
            // _childImagesを更新したいのでリファレンスを渡す(2階層くらい渡すので別の方法があれば変えたいが)。
            NSMutableDictionary *section = [_childImages objectAtIndex:indexPath.section];
            NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
            multiUploadAlbumTableViewController.totalImageNum = totalImageNum;
            multiUploadAlbumTableViewController.indexPath = indexPath;
            
            [self.navigationController pushViewController:multiUploadAlbumTableViewController animated:YES];
        } else {
            MultiUploadViewController *multiUploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadViewController"];
            multiUploadViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
            multiUploadViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
            multiUploadViewController.date = [tappedChildImage[@"date"] substringWithRange:NSMakeRange(1, 8)];
            multiUploadViewController.month = [tappedChildImage[@"date"] substringWithRange:NSMakeRange(1, 6)];
            multiUploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            if(multiUploadViewController.childObjectId && multiUploadViewController.date && multiUploadViewController.month) {
                [self.navigationController pushViewController:multiUploadViewController animated:YES];
            } else {
                // TODO インターネット接続がありません的なメッセージいるかも
            }
        }
        return;
    }
    
    if (![self isBEstImageFixed:indexPath]) {
        // ベストショット決まってなければ即Pickerを開く
        UploadPickerViewController *uploadPickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UploadPickerViewController"];
        uploadPickerViewController.month = [tappedChildImage[@"date"] substringWithRange:NSMakeRange(1, 6)];
        uploadPickerViewController.childObjectId = _childObjectId;
        uploadPickerViewController.date = [tappedChildImage[@"date"] substringWithRange:NSMakeRange(1, 8)];
        
        NSMutableDictionary *section = [_childImages objectAtIndex:indexPath.section];
        NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
        uploadPickerViewController.totalImageNum = totalImageNum;
        uploadPickerViewController.indexPath = indexPath;
        
        [self.navigationController pushViewController:uploadPickerViewController animated:YES];
        return;
    }
    
    ImagePageViewController *pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ImagePageViewController"];
    pageViewController.childImages = _childImages;
    pageViewController.currentSection = indexPath.section;
    pageViewController.currentRow = indexPath.row;
    pageViewController.childObjectId = _childObjectId;
    [self.navigationController setNavigationBarHidden:YES];
    [self.navigationController pushViewController:pageViewController animated:YES];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(self.view.frame.size.width, 30);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, 30);
    
    UICollectionReusableView *headerView = [_pageContentCollectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"viewControllerHeader" forIndexPath:indexPath];
    
    UIImageView *headerImageView = [[UIImageView alloc]initWithFrame:rect];
    UIImage *headerImage = [UIImage imageNamed:@"SectionHeader"];
    headerImageView.image = headerImage;

    CGRect labelRect = rect;
    labelRect.origin.x = 20;
    UILabel *headerLabel = [[UILabel alloc]initWithFrame:labelRect];
    NSString *year = [[_childImages objectAtIndex:indexPath.section] objectForKey:@"year"];
    NSString *month = [[_childImages objectAtIndex:indexPath.section] objectForKey:@"month"];
    headerLabel.text = [NSString stringWithFormat:@"%@/%@", year, month];
    [headerImageView addSubview:headerLabel];
    
    [headerView addSubview:headerImageView];
    
    return headerView;
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
        _dateComp = [self addDateComps:_dateComp withUnit:@"month" withValue:-1];
        [self getChildImagesWithYear:_dateComp.year withMonth:_dateComp.month withReload:YES];
    }
}

-(void)handleDoubleTap:(id) sender
{
    NSLog(@"double tap");
}

-(void)handleSingleTap:(id) sender
{
//    [self touchEvent:[[sender view] tag]];
}

- (void)getChildImagesWithYear:(NSInteger)year withMonth:(NSInteger)month withReload:(BOOL)reload
{
    _isLoading = YES;
    PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld%02ld", (long)year, (long)month]];
    [query whereKey:@"imageOf" equalTo:_childObjectId];
    [query whereKey:@"bestFlag" equalTo:@"choosed"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            NSInteger index = [[_childImagesIndexMap objectForKey:[NSString stringWithFormat:@"%ld%02ld", (long)year, (long)month]] integerValue];
            NSMutableDictionary *section = [_childImages objectAtIndex:index];
            NSMutableArray *images = [section objectForKey:@"images"];
            NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
            
            NSMutableDictionary *childImageDic = [ArrayUtils arrayToHash:objects withKeyColumn:@"date"];
            
            NSMutableArray *cacheSetQueueArray = [[NSMutableArray alloc] init];
            for (int i = 0; i < [images count]; i++) {
                PFObject *childImage = [images objectAtIndex:i];
                NSString *ymdWithPrefix = childImage[@"date"];
                
                if ([childImageDic objectForKey:ymdWithPrefix]) {
                    PFObject *childImage = [[childImageDic objectForKey:ymdWithPrefix] objectAtIndex:0];
                    [images replaceObjectAtIndex:i withObject:childImage];
                    // bestshot決まっている時は9999入れる(あり得ないくらい大きな数字)
                    [totalImageNum replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:9999]];
                    [cacheSetQueueArray addObject:childImage];
                } else {
                    //NSLog(@"No Choosed Image %@", ymdWithPrefix);
                    // チョイスされた写真がなければ、そもそも画像が上がっているかどうかを見る
                    PFQuery *unchoosedQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld%02ld", (long)year, (long)month]];
                    [unchoosedQuery whereKey:@"imageOf" equalTo:_childObjectId];
                    [unchoosedQuery whereKey:@"date" equalTo:ymdWithPrefix];
                    [unchoosedQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
                        //NSLog(@"There is %d unchoosed image : %@ %d %d %d", [objects count], ymdWithPrefix, index, i, [images count]);
                        if ([objects count] > 0) {
                            [totalImageNum replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:[objects count]]];
                        } else {
                            [totalImageNum replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:0]];
                        }
                        // 昨日と今日のパネルを即入れ替えるため
                        if (index == 0 && i < 2) {
                            [_pageContentCollectionView reloadData];
                        }
                    }];
                }
            }
            [self setImageCache:cacheSetQueueArray withReload:reload];
          
            if (reload) {
                [_pageContentCollectionView reloadData];
            }
           
            // reloadDataは非同期なのでちょっと時間を空ける
            [NSThread sleepForTimeInterval:0.1];
            _isLoading = NO;
        } else {
            NSLog(@"error occured %@", error);
        }
    }];
}

- (void)setImageCache:(NSMutableArray *)cacheSetQueueArray withReload:(BOOL)reload
{
    if ([cacheSetQueueArray count] > 0) {
        NSLog(@"get image cache queue remain %d", [cacheSetQueueArray count]);
        // キャッシュ取り出し
        PFObject *childImage = [cacheSetQueueArray objectAtIndex:0];
        [cacheSetQueueArray removeObjectAtIndex:0];
        
        NSString *ymd = [childImage[@"date"] substringWithRange:NSMakeRange(1, 8)];
        NSString *month = [ymd substringWithRange:NSMakeRange(0, 6)];
        
        AWSS3GetObjectRequest *getRequest = [AWSS3GetObjectRequest new];
        getRequest.bucket = @"babyrydev-images";
        getRequest.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%@", month], childImage.objectId];
        // no-cache必須
        getRequest.responseCacheControl = @"no-cache";
        AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:_configuration];
        
        [[awsS3 getObject:getRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
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
            if (reload) {
                // このタイミングでreloadしたいけどするとtopページが一瞬かくっとなるので微妙
                //[_pageContentCollectionView reloadData];
            }
            [self setImageCache:cacheSetQueueArray withReload:reload];
            return nil;
        }];
    } else {
        NSLog(@"get image cache queue end!");
    }
}

- (NSDateComponents *)dateComps
{
    NSDate *date = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *dateComps = [cal components:
        NSYearCalendarUnit   |
        NSMonthCalendarUnit  |
        NSDayCalendarUnit    |
        NSHourCalendarUnit
    fromDate:date];
    return dateComps;
}

- (NSDateComponents *)addDateComps:(NSDateComponents *)comps withUnit:(NSString *)unit withValue:(NSInteger)value
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *base = [calendar dateFromComponents:comps];
   
    NSDateComponents *addComps = [[NSDateComponents alloc]init];
    
    if ([unit isEqualToString:@"year"]) {
        [addComps setYear:value];
    } else if ([unit isEqualToString:@"month"]) {
        [addComps setMonth:value];
    } else if ([unit isEqualToString:@"day"]) {
        [addComps setDay:value];
    } else if ([unit isEqualToString:@"hour"]) {
        [addComps setHour:value];
    } else if ([unit isEqualToString:@"minute"]) {
        [addComps setMinute:value];
    } else {
        [addComps setSecond:value];
    }
    NSDate *date = [calendar dateByAddingComponents:addComps toDate:base options:0];

    NSDateComponents *result = [calendar components:
        NSYearCalendarUnit  |
        NSMonthCalendarUnit |
        NSDayCalendarUnit   |
        NSHourCalendarUnit
    fromDate:date];
   
    return result;
}

- (NSInteger)getLastDayOfMonthWithYear:(NSInteger)year withMonth:(NSInteger)month
{
    // 対象の月が今月の場合は今日を最終日とする
    NSDateComponents *today = [self dateComps];
    if (month == today.month) {
        return today.day;
    }
    
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:year];
    [comps setMonth:month];
    NSDate *date = [cal dateFromComponents:comps];
    
    // inUnit:で指定した単位（月）の中で、rangeOfUnit:で指定した単位（日）が取り得る範囲
    NSRange range = [cal rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:date];
    
    NSInteger max = range.length;
    return max;
}

- (void)showChildImages
{
    // 今月
    NSDateComponents *comp = [self dateComps];
    [self getChildImagesWithYear:comp.year withMonth:comp.month withReload:NO];
   
    // 先月
    NSDateComponents *lastComp = [self dateComps];
    lastComp.month--;
    [self getChildImagesWithYear:lastComp.year withMonth:lastComp.month withReload:YES];
  
    _dateComp = lastComp;
}

// 今週
// 今週じゃない かつ 候補写真がある かつ 未choosed
- (BOOL)shouldShowMultiUploadView:(NSIndexPath *)indexPath
{
    // 2日間はMultiUploadViewController
    return [self withinTwoDay:indexPath];
}

- (BOOL)isNoImage:(NSIndexPath *)indexPath
{
    NSMutableDictionary *section = [_childImages objectAtIndex:indexPath.section];
    NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
    
    if ([[totalImageNum objectAtIndex:indexPath.row] compare:[NSNumber numberWithInt:1]] == NSOrderedAscending) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isBEstImageFixed:(NSIndexPath *)indexPath
{
    NSMutableDictionary *section = [_childImages objectAtIndex:indexPath.section];
    NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
    
    if ([[totalImageNum objectAtIndex:indexPath.row] isEqual:[NSNumber numberWithInt:9999]]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)withinTwoDay: (NSIndexPath *)indexPath
{
    PFObject *chilImage = [[[_childImages objectAtIndex:indexPath.section] objectForKey:@"images"] objectAtIndex:indexPath.row];
    NSString *ymd = [chilImage[@"date"] substringWithRange:NSMakeRange(1, 8)];
    NSDateComponents *compToday = [self dateComps];
  
    NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
	[inputDateFormatter setDateFormat:@"yyyyMMdd"];
	NSDate *dateToday = [DateUtils setSystemTimezone: [inputDateFormatter dateFromString:[NSString stringWithFormat:@"%ld%02ld%02ld", (long)compToday.year, (long)compToday.month, (long)compToday.day]]];
	NSDate *dateTappedImage = [DateUtils setSystemTimezone: [inputDateFormatter dateFromString:ymd]];
  
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *diff = [cal components:NSDayCalendarUnit fromDate:dateTappedImage toDate:dateToday options:0];
    
    return [diff day] < 2;
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

- (void)initializeChildImages
{
    // 現在日時と子供の誕生日の間のオブジェクトをとりあえず全部作る
    
    // 誕生日
    NSDate *birthday = [_childArray[_pageIndex] objectForKey:@"birthday"];
    NSDate *base = [DateUtils setSystemTimezone:[NSDate date]];
    if (!birthday || [base timeIntervalSinceDate:birthday] < 0) {
        birthday = [NSDate date];
    }
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *birthdayComps = [cal components:
        NSYearCalendarUnit  |
        NSMonthCalendarUnit |
        NSDayCalendarUnit   |
        NSHourCalendarUnit
    fromDate:birthday];
   
    // 誕生日の1年前
    NSDateComponents *lowerLimitDayComps = [self addDateComps:birthdayComps withUnit:@"year" withValue:-1];
    
    // 現在日時
    NSDateComponents *todayComps = [self dateComps];
    // 現在
    NSDate *today = [NSDate date];
    
    // 誕生日の1年前
    NSDate *firstday = [cal dateFromComponents:lowerLimitDayComps];
    
    NSMutableDictionary *childImagesDic = [[NSMutableDictionary alloc]init];
    while ([today compare:firstday] == NSOrderedDescending) {
        NSDateComponents *c = [cal components:
            NSYearCalendarUnit  |
            NSMonthCalendarUnit |
            NSDayCalendarUnit   |
            NSWeekdayCalendarUnit
        fromDate:today];
        
        NSString *ym = [NSString stringWithFormat:@"%ld%02ld", (long)c.year, (long)c.month];
        
        NSMutableDictionary *section;
        if ([childImagesDic objectForKey:ym]) {
            section = [childImagesDic objectForKey:ym];
        } else {     
            section = [[NSMutableDictionary alloc]init];
            [section setObject:[[NSMutableArray alloc]init] forKey:@"images"];
            [section setObject:[[NSMutableArray alloc]init] forKey:@"totalImageNum"];
            [section setObject:[[NSMutableArray alloc]init] forKey:@"weekdays"];
            NSString *year = [NSString stringWithFormat:@"%ld", (long)c.year];
            [section setObject:year forKey:@"year"];
            NSString *month = [NSString stringWithFormat:@"%02ld", (long)c.month];
            [section setObject:month forKey:@"month"];
            [childImagesDic setObject:section forKey:ym];
        }
        
        PFObject *childImage = [[PFObject alloc]initWithClassName:[NSString stringWithFormat:@"ChildImage%ld%02ld%02ld", (long)c.year, (long)c.month, (long)c.day]];
        childImage[@"date"] = [NSString stringWithFormat:@"D%ld%02ld%02ld", (long)c.year, (long)c.month, (long)c.day];
        [[section objectForKey:@"images"] addObject:childImage];
        [[section objectForKey:@"totalImageNum"] addObject:[NSNumber numberWithInt:-1]];
        [[section objectForKey:@"weekdays"] addObject: [NSNumber numberWithInt: c.weekday]];
       
        todayComps = [self addDateComps:todayComps withUnit:@"day" withValue:-1];
        today = [cal dateFromComponents:todayComps];
    }
    
    // needMergeがtrueの時は、mergeConfに従ってsectionをmergeする
    [self setObjectsToChildImages:childImagesDic];
    
    // scroll位置と表示月の関係
    [self setupScrollPositionData];
}

- (void)setObjectsToChildImages:(NSMutableDictionary *)childImagesDic
{
    NSArray *ymList = [[childImagesDic allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
        return [obj1 integerValue] > [obj2 integerValue];
    }];
   
    NSMutableArray *childImagesAsc = [[NSMutableArray alloc]init];
    for (NSString *ym in ymList) {
        [childImagesAsc addObject:[childImagesDic objectForKey:ym]];
    }
    _childImages = [[NSMutableArray alloc]initWithArray:[[childImagesAsc reverseObjectEnumerator] allObjects]];
    _childImagesIndexMap = [[NSMutableDictionary alloc]init];
   
    _childImagesIndexMap = [[NSMutableDictionary alloc] init];
    int n = 0;
    for (NSMutableDictionary *section in _childImages) {
        NSString *ym = [NSString stringWithFormat:@"%@%02ld", [section objectForKey:@"year"], (long)[[section objectForKey:@"month"] integerValue]];
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

- (BOOL)shouldShowNewSection
{
    CGFloat hiddenHeight = _pageContentCollectionView.contentSize.height - (_pageContentCollectionView.contentOffset.y + _pageContentCollectionView.bounds.size.height/2);
    if (hiddenHeight < _nextSectionHeight) {
        return YES;
    }
    return NO;
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

- (void)setBackgroundViewOfCell:(TagAlbumCollectionViewCell *)cell withImageCachePath:(NSString *)imageCachePath withIndexPath:(NSIndexPath *)indexPath
{
    NSData *imageCacheData = [ImageCache getCache:imageCachePath];
    NSString *role = _selfRole;
    
    NSMutableDictionary *section = [_childImages objectAtIndex:indexPath.section];
    NSMutableArray *totalImageNum = [section objectForKey:@"totalImageNum"];
    if (!imageCacheData) {
        if ([role isEqualToString:@"uploader"]) {
            // アップの出し分け
            // アップしたが、チョイスされていない(=> totalImageNum = (0|-1))場合 かつ 今日or昨日の場合 : チョイス催促アイコン
            // それ以外 : アップアイコン
            
            if([self withinTwoDay:indexPath] && [self isNoImage:indexPath]) {
                // チョイス催促をいれてもいいけど、いまは UP PHOTO アイコンをはめている
                if (indexPath.section == 0 && indexPath.row == 0) {
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
                if (indexPath.section == 0 && indexPath.row == 0) {
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
            if ([self withinTwoDay:indexPath]) {
                // アップ催促
                if ([self isNoImage:indexPath]) {
                    if (indexPath.section == 0 && indexPath.row == 0) {
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
                    UITapGestureRecognizer *giveMePhotoGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(giveMePhoto)];
                    giveMePhotoGesture.numberOfTapsRequired = 2;
                    [cell addGestureRecognizer:giveMePhotoGesture];
                } else {
                    // チョイス促進アイコン貼る
                    NSNumber *uploadedNum = [totalImageNum objectAtIndex:indexPath.row];
                    if (indexPath.section == 0 && indexPath.row == 0) {
                        CellBackgroundViewToEncourageChooseLarge *backgroundView = [CellBackgroundViewToEncourageChooseLarge view];
                        CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
                        backgroundView.frame = rect;
                        backgroundView.iconView.frame = rect;
                        rect = CGRectMake(0, cell.frame.size.height - backgroundView.upCountLabel.frame.size.height, cell.frame.size.width - 10, backgroundView.upCountLabel.frame.size.height);
                        backgroundView.upCountLabel.frame = rect;
                        backgroundView.upCountLabel.text = [NSString stringWithFormat:@"%@ PHOTO AVAILABLE", uploadedNum];
                        [cell addSubview:backgroundView];
                    } else {
                        CellBackgroundViewToEncourageChoose *backgroundView = [CellBackgroundViewToEncourageChoose view];
                        CGRect rect = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
                        backgroundView.frame = rect;
                        backgroundView.iconView.frame = rect;
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
    if (indexPath.section == 0 && indexPath.row == 0) {
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

- (void) giveMePhoto
{
    [PushNotification sendInBackground:@"requestPhoto" withOptions:nil];
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
