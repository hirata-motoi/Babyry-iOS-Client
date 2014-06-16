//
//  AlbumViewController.m
//  babyry
//
//  Created by kenjiszk on 2014/06/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AlbumViewController.h"

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
    _yyyy = [_month substringToIndex:4];
    _mm = [_month substringWithRange:NSMakeRange(4, 2)];
    _dd = [_date substringWithRange:NSMakeRange(6, 2)];
    NSLog(@"%@/%@/%@", _yyyy, _mm, _dd);
    
    // set cell size
    _cellHeight = 100.0f;
    _cellWidth = 100.0f;
    
    // album name
    _albumViewNameLabel.text = [NSString stringWithFormat:@"%@/%@ %@", _yyyy, _mm, _name];
    
    [self createCollectionView];
    
    [self setAlbumCacheData];
    [self setAlbumParseData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)albumBackButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void) setAlbumCacheData
{
    NSLog(@"get album data");
}

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
    ImageCache *ic = [[ImageCache alloc] init];
    NSString *imageCachePath = [NSString stringWithFormat:@"%@%@%@%02d", _childObjectId, _yyyy, _mm, [_dd intValue] - indexPath.row];
    NSData *imageCacheData = [ic getCache:imageCachePath];
    if(imageCacheData) {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:imageCacheData]];
    } else {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NoImage"]];
    }
    
    UILabel *cellLabel = [[UILabel alloc] init];
    cellLabel.text = [NSString stringWithFormat:@"%02d", [_dd intValue] - indexPath.row];
    cellLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:_cellHeight/3];
    cellLabel.textColor = [UIColor whiteColor];
    cellLabel.shadowColor = [UIColor blackColor];
    cellLabel.frame = CGRectMake(2, 0, _cellWidth, _cellHeight/3);
    [cell addSubview:cellLabel];
    
/*
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [cell addGestureRecognizer:doubleTapGestureRecognizer];

    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    // ダブルタップに失敗した時だけシングルタップとする
    [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
    [cell addGestureRecognizer:singleTapGestureRecognizer];
*/
    return cell;
}

- (IBAction)albumViewPreMonthButton:(id)sender {
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
    [_albumCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"AlbumViewControllerCell"];
    [_albumCollectionView reloadData];
}

- (IBAction)albumViewNextMonthButton:(id)sender {
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
    _dd = [self getMaxDate:_mm yyyy:_yyyy];
    
    _albumViewNameLabel.text = [NSString stringWithFormat:@"%@/%@ %@", _yyyy, _mm, _name];
    [_albumCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"AlbumViewControllerCell"];
    [_albumCollectionView reloadData];

}

-(NSString *)getMaxDate:mm yyyy:(NSString *)yyyy
{
    int month = [mm intValue];
    int year = [yyyy intValue];
    //今月の場合
    if ([_month isEqual:[NSString stringWithFormat:@"%@%@", _yyyy, _mm]]) {
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

@end
