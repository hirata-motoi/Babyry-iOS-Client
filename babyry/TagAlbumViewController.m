//
//  TagAlbumViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/11.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TagAlbumViewController.h"
#import "UploadViewController.h"
#import "ImageCache.h"
#import "ImageTrimming.h"
#import "TagAlbumOperationViewController.h"
#import "TagAlbumCollectionViewCell.h"
#import "Navigation.h"
#import "ImagePageViewController.h"

@interface TagAlbumViewController ()

@end

@implementation TagAlbumViewController

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
    
    // 定数のinitialize
    // set cell size
    _cellHeight = self.view.frame.size.width/3 - 2;
    _cellWidth = _cellHeight;
    _childImages = [[NSMutableArray alloc]init];
    
    // 各ボタンのイベント設定などはしておく
    
    // viewにheaderを設定
    // 非同期でデータを読み込んできてcollectionViewをreloadする
    [self setupCollectionView:@"create"];
    [self.closeButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
    //[self.tagSelectButton addTarget:self action:@selector(openTagSelectView) forControlEvents:UIControlEventTouchUpInside];
    UIButton *tagSelectButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [tagSelectButton setBackgroundImage:[self filterImage:[UIImage imageNamed:@"badgeRed"]] forState:UIControlStateNormal];
    [tagSelectButton addTarget:self action:@selector(openTagSelectView) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:tagSelectButton];
    
    // year change
    [self setPaging];
    
    // operationView
    [self setupOperationView];
    
    // notification
    [self setupNotificationReceiver];
    
    // title
    [Navigation setTitle:self.navigationItem withTitle:_year withFont:nil withFontSize:0 withColor:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)createCollectionView
{
    // UICollectionViewの土台を作成
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[TagAlbumCollectionViewCell class] forCellWithReuseIdentifier:@"viewControllerCell"];
    [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"viewControllerHeader"];
    [self.view addSubview:_collectionView];
}

// セルの数を指定するメソッド
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray *sortedChildImages = [self sortChildImageByYearMonth];
    NSMutableArray *images = [[sortedChildImages objectAtIndex:section] objectForKey:@"images"];
    return images.count;
}

// セルの大きさを指定するメソッド
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(_cellWidth, _cellHeight);
}

// 指定された場所のセルを作るメソッド
-(TagAlbumCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //セルを再利用 or 再生成
    TagAlbumCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"viewControllerCell" forIndexPath:indexPath];
    for (UIView *view in [cell subviews]) {
        [view removeFromSuperview];
    }
    NSArray *sortedChildImages = [self sortChildImageByYearMonth];
    NSArray *imageObjects = [[sortedChildImages objectAtIndex:indexPath.section] objectForKey:@"images"];
    PFObject *imageObject = [imageObjects objectAtIndex:indexPath.row];
    
    NSString *yyyymmdd = [imageObject[@"date"] substringWithRange:NSMakeRange(1, 8)]; // D20140710 のような文字列から日付部分だけ切り出す
    // Cacheからはりつけ
    NSString *imageCachePath = [NSString stringWithFormat:@"%@%@thumb", _childObjectId, yyyymmdd];
    NSData *imageCacheData = [ImageCache getCache:imageCachePath];
    if(imageCacheData) {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageWithData:imageCacheData]]];
    } else {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageNamed:@"NoImage"]]];
    }

    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [cell addGestureRecognizer:singleTapGestureRecognizer];
    
    // tap時に使うためpropertyをセット
    cell.currentSection = indexPath.section;
    cell.currentRow = indexPath.row;
    
    return cell;
}

 - (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(self.view.frame.size.width, 30);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *sortedChildImages = [self sortChildImageByYearMonth];
    
    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, 30);
    
    UICollectionReusableView *headerView = [_collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"viewControllerHeader" forIndexPath:indexPath];
    
    UIImageView *headerImageView = [[UIImageView alloc]initWithFrame:rect];
    UIImage *headerImage = [UIImage imageNamed:@"SectionHeader"];
    headerImageView.image = headerImage;

    CGRect labelRect = rect;
    labelRect.origin.x = 20;
    UILabel *headerLabel = [[UILabel alloc]initWithFrame:labelRect];
    NSDictionary *section = [sortedChildImages objectAtIndex:indexPath.section];
    headerLabel.text = [NSString stringWithFormat:@"%@/%@", [section objectForKey:@"year"], [section objectForKey:@"month"]];
    [headerImageView addSubview:headerLabel];
    
    [headerView addSubview:headerImageView];
    
    return headerView;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [_childImages count];
}

-(void)handleSingleTap:(id) sender
{
    TagAlbumCollectionViewCell *cell = (TagAlbumCollectionViewCell *)[sender view];
    [self openTagAlbumPageView:cell.currentSection withRow:cell.currentRow];
}

-(void) openTagAlbumPageView:(int)section withRow:(int)row
{
    ImagePageViewController *pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ImagePageViewController"];
    pageViewController.childImages = [self sortChildImageByYearMonth];
    pageViewController.currentSection = section;
    pageViewController.currentRow = row;
    pageViewController.childObjectId = _childObjectId;
    //_pageViewController.name = _name;  // nameをどっかでとってくる
    [self.navigationController setNavigationBarHidden:YES];
    [self.navigationController pushViewController:pageViewController animated:YES];
}

- (NSArray *)getMonthList: (NSString *)targetYearString
{
    // 現在日付を取得
    NSDate *now = [NSDate date];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger flags;
    NSDateComponents *comps;
    
    // 年・月・日を取得
    flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    comps = [calendar components:flags fromDate:now];
    
    NSInteger year = comps.year;
    NSInteger month = comps.month;
    
    NSNumber *lastMonth = (year == [targetYearString intValue]) ? [NSNumber numberWithInt:month] : [NSNumber numberWithInt:12];
    
    NSMutableArray *monthList = [[NSMutableArray alloc]init];
    for (int i = 1; i <= [lastMonth intValue]; i++) {
        [monthList addObject:[NSNumber numberWithInt:i]];
    }
    NSArray *sortedMonthList = [monthList sortedArrayUsingComparator:^(id obj1, id obj2) {
        return [obj2 compare:obj1];
    }];
    return sortedMonthList;
}


- (void) setImageDataSource:(NSString *)year monthList:(NSArray *)monthList tagId:(NSNumber *)tagId
{
    // monthListは降順で渡される
    for (int i = 0; i < monthList.count; i++) {
        NSString *month = [monthList objectAtIndex:i];
        NSString *childImageClassName = [NSString stringWithFormat:@"ChildImage%@%02d", year, [month intValue]];

        PFQuery *query = [PFQuery queryWithClassName:childImageClassName];
        [query whereKey:@"imageOf" equalTo:_childObjectId];
        [query whereKey:@"bestFlag" equalTo:@"choosed"];
        [query whereKey:@"tags" equalTo:tagId]; // tagsカラムにはarrayが入っているが、equalToで「tagsに特定のtagIdが含まれる」行をselectできる
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
            if ( !error && objects.count > 0) {
                NSMutableDictionary *result = [[NSMutableDictionary alloc]init];
                [result setObject:objects forKey:@"images"];
                [result setObject:year forKey:@"year"];
                [result setObject:month forKey:@"month"];
                [_childImages addObject:result];
                
                // childImages[0]
                //    year
                //    month
                //    images
                //       ChildImageオブジェクト
                 
                int __block index = 0;
                for (PFObject *object in objects) {
                    NSString *date = [object[@"date"] substringWithRange:NSMakeRange(1, 8)];
                    NSString *cacheImageName = [NSString stringWithFormat:@"%@%@thumb", _childObjectId, date];
                    [object[@"imageFile"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error){
                        if(!error) {
                            // サムネイル作るためにUIImage作成
                            UIImage *thumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:data]];
                            
                            // サムネイル用UIImageを再度dataに変換
                            [ImageCache setCache:[NSString stringWithFormat:@"%@", cacheImageName] image:UIImageJPEGRepresentation(thumbImage, 0.7f)];
                            index++;
                            if (index == [objects count]) {
                                [_collectionView reloadData];
                            }
                        }
                    }];
                }
            }
        }];
    }
}

- (void)closeView
{
//    [self.view removeFromSuperview];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openTagSelectView
{
    _operationView.hidden = NO;
}

- (void)setupOperationView
{
    TagAlbumOperationViewController *operationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TagAlbumOperationViewController"];
    // 現在選択されているタグ
    operationViewController.tagId = _tagId;
    operationViewController.holdedBy = @"TagAlbumViewController";
    
    operationViewController.view.hidden = YES; //最初は隠す
    [self addChildViewController:operationViewController];
    [self.view addSubview:operationViewController.view];
    _operationView = operationViewController.view;
}

- (void)setupNotificationReceiver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCollectionViewByNotification:) name:@"selectedTagChanged" object:nil];
}

- (void)reloadCollectionViewByNotification:(NSNotification *)notification
{
    NSMutableDictionary *params = (NSMutableDictionary *)[notification object];
    _tagId = [params objectForKey:@"tagId"];
    [self setupCollectionView:@"reload"];
}

- (void)setupCollectionView: (NSString *)type
{
    if ([_tagId intValue] == 0) {
        return;
    }
    
    if ([type isEqualToString:@"create"]) {
        // type:createの時は新規にTagAlbumViewControllerをインスタンス化した時
        [self createCollectionView];
    } else {
        // 絞り込むtagを変えた場合はまず初期化
        [_childImages removeAllObjects];
        [_collectionView reloadData];
    }
    
    NSArray *monthList = [self getMonthList:_year];
    [self setImageDataSource:_year monthList:monthList tagId:_tagId];
}

- (void)setPaging
{
    _albumViewPreYearLabel = [self createButton:@"pre"];
    _albumViewNextYearLabel = [self createButton:@"next"];
    [self.view addSubview:_albumViewPreYearLabel];
    [self.view addSubview:_albumViewNextYearLabel];
}


// TODO button用classを作ってあげたい
- (UILabel *)createButton: (NSString *)type
{
    // buttom buttons
    float buttonRadius = 30.0f;
    float diff = (self.view.frame.size.width/4 - 2*buttonRadius)/2;
    int buttonFontSize = 20;
    float buttonAlpha = 0.5;
    
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:buttonFontSize];
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor orangeColor];
    label.alpha = buttonAlpha;
    label.layer.cornerRadius = buttonRadius;
    [label setClipsToBounds:YES];
    label.userInteractionEnabled = YES;
    
    if ([type isEqualToString:@"pre"]) {
        label.text = @"<<";
        label.frame = CGRectMake(self.view.frame.size.width/4 + diff, self.view.frame.size.height -2*buttonRadius -3, 2*buttonRadius, 2*buttonRadius);

        UITapGestureRecognizer *preGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showPreYearAlbum:)];
        preGestureRecognizer.numberOfTapsRequired = 1;
        [label addGestureRecognizer:preGestureRecognizer];
    } else if ([type isEqualToString:@"next"]) {
            label.text = @">>";
        label.frame = CGRectMake(self.view.frame.size.width*2/4 + diff, self.view.frame.size.height -2*buttonRadius -3, 2*buttonRadius, 2*buttonRadius);
        
        UITapGestureRecognizer *nextGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showNextYearAlbum:)];
        nextGestureRecognizer.numberOfTapsRequired = 1;
        [label addGestureRecognizer:nextGestureRecognizer];
    }
    return label;
}

- (void)showPreYearAlbum:(id)sender
{
    _year = [[NSNumber numberWithInt:[_year intValue] - 1] stringValue];
    [self setupCollectionView:@"reload"];
    [Navigation setTitle:self.navigationItem withTitle:_year withFont:nil withFontSize:0 withColor:nil];
}

- (void)showNextYearAlbum:(id)sender
{
    _year = [[NSNumber numberWithInt:[_year intValue] + 1] stringValue];
    [self setupCollectionView:@"reload"];
    [Navigation setTitle:self.navigationItem withTitle:_year withFont:nil withFontSize:0 withColor:nil];
}

- (NSArray *)sortChildImageByYearMonth
{
    NSArray *sortedChildImages = [_childImages sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        int yearMonthObj1 = [[NSString stringWithFormat:@"%@%@", [obj1 objectForKey:@"year"], [obj1 objectForKey:@"month"]] intValue];
        int yearMonthObj2 = [[NSString stringWithFormat:@"%@%@", [obj2 objectForKey:@"year"], [obj2 objectForKey:@"month"]] intValue];
        return (BOOL)(yearMonthObj2 > yearMonthObj1);
    }];
    return sortedChildImages;
}

- (UIImage *)filterImage:(UIImage *)originImage
{
    CIImage *filteredImage = [[CIImage alloc] initWithCGImage:originImage.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIMinimumComponent"];
    [filter setValue:filteredImage forKey:@"inputImage"];
    filteredImage = filter.outputImage;
    
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    CGImageRef imageRef = [ciContext createCGImage:filteredImage
                                          fromRect:[filteredImage extent]];
    UIImage *outputImage  = [UIImage imageWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    return outputImage;
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
