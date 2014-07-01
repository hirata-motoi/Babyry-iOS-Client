//
//  AlbumViewController.m
//  babyry
//
//  Created by kenjiszk on 2014/06/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AlbumViewController.h"
#import "ImageTrimming.h"
#import "UploadViewController.h"

@interface AlbumViewController ()

@end

@implementation AlbumViewController

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
    
    // get pageIndex, imageIndex
    NSLog(@"received childObjectId:%@ month:%@ date:%@", _childObjectId, _month, _date);
    
    // set album yyyy mm dd
    NSLog(@"set album yyyy mm dd");
    _yyyy = [_month substringToIndex:4];
    _mm = [_month substringWithRange:NSMakeRange(4, 2)];
    _dd = [_date substringWithRange:NSMakeRange(6, 2)];
    NSLog(@"%@/%@/%@", _yyyy, _mm, _dd);
    
    // set cell size
    _cellHeight = self.view.frame.size.width/3 - 2;
    _cellWidth = _cellHeight;
    
    // album name
    _albumViewNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:20];
    _albumViewNameLabel.text = [NSString stringWithFormat:@"%@/%@ %@", _yyyy, _mm, _name];
    
    // buttom buttons
    float buttonRadius = 30.0f;
    float diff = (self.view.frame.size.width/4 - 2*buttonRadius)/2;
    int buttonFontSize = 20;
    float buttonAlpha = 0.5;
    
    // set back button
    _albumViewBackLabel = [[UILabel alloc] init];
    _albumViewBackLabel.text = @"Back";
    _albumViewBackLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:buttonFontSize];
    _albumViewBackLabel.textColor = [UIColor blackColor];
    _albumViewBackLabel.textAlignment = NSTextAlignmentCenter;
    _albumViewBackLabel.backgroundColor = [UIColor orangeColor];
    _albumViewBackLabel.alpha = buttonAlpha;
    _albumViewBackLabel.frame = CGRectMake(diff, self.view.frame.size.height -2*buttonRadius -3, 2*buttonRadius, 2*buttonRadius);
    _albumViewBackLabel.layer.cornerRadius = buttonRadius;
    [_albumViewBackLabel setClipsToBounds:YES];
    _albumViewBackLabel.userInteractionEnabled = YES;
    
    // set tag button
    _albumViewTagLabel = [[UILabel alloc] init];
    _albumViewTagLabel.text = @"Tag";
    _albumViewTagLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:buttonFontSize];
    _albumViewTagLabel.textColor = [UIColor blackColor];
    _albumViewTagLabel.textAlignment = NSTextAlignmentCenter;
    _albumViewTagLabel.backgroundColor = [UIColor orangeColor];
    _albumViewTagLabel.alpha = buttonAlpha;
    _albumViewTagLabel.frame = CGRectMake(self.view.frame.size.width*3/4 + diff, self.view.frame.size.height -2*buttonRadius -3, 2*buttonRadius, 2*buttonRadius);
    _albumViewTagLabel.layer.cornerRadius = buttonRadius;
    [_albumViewTagLabel setClipsToBounds:YES];
    _albumViewTagLabel.userInteractionEnabled = YES;
    
    // set change month button
    _albumViewPreMonthLabel = [[UILabel alloc] init];
    _albumViewPreMonthLabel.text = @"<<";
    _albumViewPreMonthLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:buttonFontSize];
    _albumViewPreMonthLabel.textColor = [UIColor blackColor];
    _albumViewPreMonthLabel.textAlignment = NSTextAlignmentCenter;
    _albumViewPreMonthLabel.backgroundColor = [UIColor orangeColor];
    _albumViewPreMonthLabel.alpha = buttonAlpha;
    _albumViewPreMonthLabel.frame = CGRectMake(self.view.frame.size.width/4 + diff, self.view.frame.size.height -2*buttonRadius -3, 2*buttonRadius, 2*buttonRadius);
    _albumViewPreMonthLabel.layer.cornerRadius = buttonRadius;
    [_albumViewPreMonthLabel setClipsToBounds:YES];
    _albumViewPreMonthLabel.userInteractionEnabled = YES;
    
    _albumViewNextMonthLabel = [[UILabel alloc] init];
    _albumViewNextMonthLabel.text = @">>";
    _albumViewNextMonthLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:buttonFontSize];
    _albumViewNextMonthLabel.textColor = [UIColor blackColor];
    _albumViewNextMonthLabel.textAlignment = NSTextAlignmentCenter;
    _albumViewNextMonthLabel.backgroundColor = [UIColor orangeColor];
    _albumViewNextMonthLabel.alpha = buttonAlpha;
    _albumViewNextMonthLabel.frame = CGRectMake(self.view.frame.size.width*2/4 + diff, self.view.frame.size.height -2*buttonRadius -3, 2*buttonRadius, 2*buttonRadius);
    _albumViewNextMonthLabel.layer.cornerRadius = buttonRadius;
    [_albumViewNextMonthLabel setClipsToBounds:YES];
    _albumViewNextMonthLabel.userInteractionEnabled = YES;

    UITapGestureRecognizer *singleTapGestureRecognizerBack = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(albumViewBack:)];
    singleTapGestureRecognizerBack.numberOfTapsRequired = 1;
    [_albumViewBackLabel addGestureRecognizer:singleTapGestureRecognizerBack];
    
    UITapGestureRecognizer *singleTapGestureRecognizerTag = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showTagAlbum:)];
    singleTapGestureRecognizerTag.numberOfTapsRequired = 1;
    [_albumViewTagLabel addGestureRecognizer:singleTapGestureRecognizerTag];
    
    UITapGestureRecognizer *singleTapGestureRecognizerPreMonth = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showPreMonth:)];
    singleTapGestureRecognizerPreMonth.numberOfTapsRequired = 1;
    [_albumViewPreMonthLabel addGestureRecognizer:singleTapGestureRecognizerPreMonth];
    
    UITapGestureRecognizer *singleTapGestureRecognizerNextMonth = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showNextMonth:)];
    singleTapGestureRecognizerNextMonth.numberOfTapsRequired = 1;
    [_albumViewNextMonthLabel addGestureRecognizer:singleTapGestureRecognizerNextMonth];
    
    [self createCollectionView];
    [self setAlbumParseData];
    
    [self.view addSubview:_albumViewBackLabel];
    [self.view addSubview:_albumViewTagLabel];
    [self.view addSubview:_albumViewPreMonthLabel];
    [self.view addSubview:_albumViewNextMonthLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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

-(void) setAlbumParseData
{
    NSLog(@"get album data");
}

-(void)createCollectionView
{
    // UICollectionViewの土台を作成
    _albumCollectionView.delegate = self;
    _albumCollectionView.dataSource = self;
    [_albumCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"AlbumViewControllerCell"];
    
    [self.view addSubview:_albumCollectionView];
}

// セルの数を指定するメソッド
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSLog(@"number of collection cell : %d", [_dd intValue]);
    return [_dd intValue];
}

// セルの大きさを指定するメソッド
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(_cellWidth, _cellHeight);
}

// 指定された場所のセルを作るメソッド
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //セルを再利用 or 再生成
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AlbumViewControllerCell" forIndexPath:indexPath];
    for (UIView *view in [cell subviews]) {
        //NSLog(@"remove cell's child view");
        [view removeFromSuperview];
    }
    
    // Cacheからはりつけ
    NSString *imageCachePath = [NSString stringWithFormat:@"%@%@%@%02d", _childObjectId, _yyyy, _mm, [_dd intValue] - indexPath.row];
    NSData *imageCacheData = [ImageCache getCache:imageCachePath];
    //ImageTrimming *it = [[ImageTrimming alloc] init];
    if(imageCacheData) {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageWithData:imageCacheData]]];
    } else {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageNamed:@"NoImage"]]];
    }
    
    UILabel *cellLabel = [[UILabel alloc] init];
    cellLabel.text = [NSString stringWithFormat:@"%02d", [_dd intValue] - indexPath.row];
    cellLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:_cellHeight/3];
    cellLabel.textColor = [UIColor whiteColor];
    cellLabel.shadowColor = [UIColor blackColor];
    cellLabel.frame = CGRectMake(2, 0, _cellWidth, _cellHeight/3);
    cell.tag = indexPath.row;
    [cell addSubview:cellLabel];
    
/*
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [cell addGestureRecognizer:doubleTapGestureRecognizer];
*/
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    // ダブルタップに失敗した時だけシングルタップとする
    //[singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
    [cell addGestureRecognizer:singleTapGestureRecognizer];
 
    return cell;
}

-(void)handleSingleTap:(id) sender
{
    NSLog(@"single tap");
    NSLog(@"single tap %d", [[sender view] tag]);
    [self openMonthPageView];
}

-(void) openMonthPageView
{
    NSLog(@"openMonthPageView");
    //_pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageViewController.dataSource = self;
    
    //NSLog(@"0ページ目を表示");
    UploadViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Change the size of page view controller
    //NSLog(@"view controllerのサイズ変更");
    //_pageViewController.view.frame = CGRectMake(0, 50, self.view.frame.size.width, self.view.frame.size.height);
    
    //NSLog(@"view追加");
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [_pageViewController didMoveToParentViewController:self];
}

-(void)albumViewBack:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void) showTagAlbum:(id)sender
{

}

-(void)showPreMonth:(id)sender
{
    NSLog(@"show previous month");
    // set next month
    if (![_mm isEqual:@"01"]) {
        _mm = [NSString stringWithFormat:@"%02d", [_mm intValue] - 1 ];
    } else {
        _mm = @"12";
        _yyyy = [NSString stringWithFormat:@"%02d", [_yyyy intValue] - 1 ];
    }
    _dd = [self getMaxDate:_mm yyyy:_yyyy];
    
    _albumViewNameLabel.text = [NSString stringWithFormat:@"%@/%@ %@", _yyyy, _mm, _name];
    CGPoint offset;
    offset.x = 0;
    offset.y = 0;
    [_albumCollectionView setContentOffset:offset animated:NO];
    [_albumCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"AlbumViewControllerCell"];
    [_albumCollectionView reloadData];
}

-(void)showNextMonth:(id)sender
{
    NSLog(@"show next month");
    // cant get future month
    NSLog(@"compare month %@ %@", _month, [NSString stringWithFormat:@"%@%@", _yyyy, _mm]);
    if ([_month isEqual:[NSString stringWithFormat:@"%@%@", _yyyy, _mm]]) {
        return;
    }
    // set next month
    if (![_mm isEqual:@"12"]) {
        _mm = [NSString stringWithFormat:@"%02d", [_mm intValue] + 1 ];
    } else {
        _mm = @"01";
        _yyyy = [NSString stringWithFormat:@"%02d", [_yyyy intValue] + 1 ];
    }
    
    // 今月の場合にはmaxの代わりに今日の日付入れる
    if ([_month isEqualToString:[NSString stringWithFormat:@"%@%@", _yyyy, _mm]]) {
        _dd = [self getMaxDate:_mm yyyy:_yyyy];
    } else {
        _dd = [_date substringWithRange:NSMakeRange(6, 2)];
    }
    
    _albumViewNameLabel.text = [NSString stringWithFormat:@"%@/%@ %@", _yyyy, _mm, _name];
    CGPoint offset;
    offset.x = 0;
    offset.y = 0;
    [_albumCollectionView setContentOffset:offset animated:NO];
    [_albumCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"AlbumViewControllerCell"];
    [_albumCollectionView reloadData];

}

-(NSString *)getMaxDate:mm yyyy:(NSString *)yyyy
{
    int month = [mm intValue];
    int year = [yyyy intValue];
    //今月の場合
    if ([_month isEqual:[NSString stringWithFormat:@"%@%@", _yyyy, _mm]]) {
        NSLog(@"getMaxDate return this month");
        return [_date substringWithRange:NSMakeRange(6, 2)];
    }
    //閏年
    if (year % 4 == 0) {
        if (year % 100 == 0 && year % 400 != 0) {
            return @"28";
        }
    }
    // 2月
    if (month == 2) {
        return @"29";
    }
    //その他
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
        return @"31";
    } else {
        return @"30";
    }
}


// 以下、pageviewcontroller用のメソッド
// provides the view controller after the current view controller. In other words, we tell the app what to display for the next screen.
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    // _dateは今月のmaxなdate
    // dateはuploadviewに表示されているdate
    // 差分 index = _date - date
    int date = [((UploadViewController *) viewController).date intValue];
    NSLog(@"viewControllerBeforeViewController : %d", date);
    NSUInteger index = [[NSString stringWithFormat:@"%@%@%@", _yyyy, _mm, _dd] intValue] - date;
    
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
    int date = [((UploadViewController *) viewController).date intValue];
    NSLog(@"viewControllerAfterViewController : %d", date);
    NSUInteger index = [[NSString stringWithFormat:@"%@%@%@", _yyyy, _mm, _dd] intValue] - date;
    
    if (index >= [_dd intValue] - 1 || index == NSNotFound) {
        return nil;
    }
    
    index++;
    NSLog(@"index++ :%d", index);
    return [self viewControllerAtIndex:index];
}

- (UploadViewController *)viewControllerAtIndex:(NSUInteger)index
{
    // index = _date - date なので
    // date = _date - indexで変更する
    NSLog(@"index:%dのviewController", index);
    // 設定されたページが0か、indexがpageTitlesよりも多かったらnil返す
    //if (([_childArray count] == 0) || (index >= [_childArray count])) {
        //NSLog(@"設定されたページが0か、indexがpageTitlesよりも多かったらnil返す");
    //    return nil;
    //}
    
    UploadViewController *uploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UploadViewController"];
    uploadViewController.childObjectId = _childObjectId;
    uploadViewController.name = _name;
    NSLog(@"calc targetDate index:%d _date:%@", index, _date);
    int targetDate = [[NSString stringWithFormat:@"%@%@%@", _yyyy, _mm, _dd] intValue] - index;
    
    NSLog(@"open uploadviewcontroller date:%d", targetDate);
    uploadViewController.date = [NSString stringWithFormat:@"%0d", targetDate];
    uploadViewController.month = [NSString stringWithFormat:@"%@%@", _yyyy, _mm];
    uploadViewController.uploadedImage = [UIImage imageNamed:@"NoImage"];
    uploadViewController.bestFlag = @"choosed";
    uploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    return uploadViewController;
}

// 全体で何ページあるか返す Delegate Method コメント外すとPageControlがあらわれる
/*
- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.pageTitles count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}
*/

@end
