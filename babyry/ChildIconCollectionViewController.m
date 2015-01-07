//
//  ChildIconCollectionViewController.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/06.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ChildIconCollectionViewController.h"
#import "ImageCache.h"
#import "ChildIconManager.h"
#import "PushNotification.h"

@interface ChildIconCollectionViewController ()

@end

@implementation ChildIconCollectionViewController
{
    NSArray *bestShotList;
    CGSize cellRect;
    NSString *cacheDir;
}

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
    _childIconCollectionView.dataSource = self;
    _childIconCollectionView.delegate = self;
    
    CGFloat windowWidth = self.view.frame.size.width;
    cellRect = CGSizeMake(windowWidth/4 - 2, windowWidth/4 - 2);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [self setupBestShotList];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return bestShotList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    // 画像を取得してcellのimageViewへはりつける
    NSData *imageData = [ImageCache getCache:bestShotList[indexPath.row] dir:cacheDir];
    UIImage *image = [UIImage imageWithData:imageData];
    cell.backgroundView = [[UIImageView alloc]initWithImage:image];
    
    // Configure the cell
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // indexPathから画像のpathを取得
    // PageViewControllerをひらく
    // bestShotListを渡す
    // indexPathを渡して画像をPageViewControllerに表示
    
    // test とりあえずアイコンを交換してみる
    NSData *imageData = [ImageCache getCache:bestShotList[indexPath.row] dir:cacheDir];
    [ChildIconManager updateChildIcon:imageData withChildObjectId:_childObjectId];
   
    // test silent pushを送る
    [self sendPushNotification];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return cellRect;
}


#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/


- (void)setupBestShotList
{
    cacheDir = [NSString stringWithFormat:@"%@/bestShot/thumbnail", _childObjectId];
    // localのBS一覧を取得
    bestShotList = [ImageCache getListOfMultiUploadCache:cacheDir];
}

- (void)sendPushNotification
{
    NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
    transitionInfoDic[@"event"] = @"childIconChanged";
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    options[@"data"] = [[NSMutableDictionary alloc]
                        initWithObjects:@[transitionInfoDic, [NSNumber numberWithInt:1]]
                        forKeys:@[@"transitionInfo", @"content-available"]];
    [PushNotification sendInBackground:@"childIconChanged" withOptions:options];
}

@end
