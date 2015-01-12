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
#import "ColorUtils.h"
#import "AWSS3Utils.h"
#import "ChildProperties.h"
#import "Logger.h"
#import "ImageSelectToolView.h"
#import "UIColor+Hex.h"
#import "Navigation.h"
#import "ImageTrimming.h"

@interface ChildIconCollectionViewController ()

@end

@implementation ChildIconCollectionViewController
{
    NSArray *bestShotList;
    CGSize cellRect;
    NSString *cacheDir;
    UIView *overlay;
    NSIndexPath *displayedIndexPath;
}
const float screenRate = 0.9;

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
    
    self.navigationController.navigationBar.barTintColor = [ColorUtils getBabyryColor];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"closeIcon"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(close)];
    [item setBackgroundImage:[UIImage imageNamed:@"transparent"]
                    forState:UIControlStateNormal
                  barMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    // TODO 名前の長さに応じてfont変更 + ... にすwる
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:_childObjectId];
    [Navigation setTitle:self.navigationItem
               withTitle:[NSString stringWithFormat:@"%@ちゃんのアイコン選択", childProperty[@"name"]]
            withSubtitle:nil
                withFont:nil
            withFontSize:15.0f
               withColor:nil];
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
    cell.backgroundView = [[UIImageView alloc]initWithImage:[ImageTrimming makeRectImage:image]];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    displayedIndexPath = indexPath;
    [self openModalView:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return cellRect;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 2.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 2.0;
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
    bestShotList = [ImageCache getListOfMultiUploadCache:cacheDir];
}

- (void)sendPushNotification
{
    NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
    transitionInfoDic[@"event"] = @"childIconChanged";
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    options[@"data"] = [[NSMutableDictionary alloc]
                        initWithObjects:@[transitionInfoDic, [NSNumber numberWithInt:1], @""]
                        forKeys:@[@"transitionInfo", @"content-available", @"sound"]];
    [PushNotification sendInBackground:@"childIconChanged" withOptions:options];
}

- (void)openModalView:(NSIndexPath *)indexPath
{
    NSString *fileName = bestShotList[indexPath.row];
    NSData *imageData = [ImageCache getCache:fileName dir:[NSString stringWithFormat:@"%@/bestShot/fullsize", _childObjectId]];
    UIImage *image = [[UIImage alloc]initWithData:imageData];
    
    // 縦横比計算
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    
    CGFloat width;
    CGFloat height;
    UIImage *thumbnail;
    if (imageData) {
        CGFloat widthRatio = screenRect.size.width * screenRate / image.size.width;
        CGFloat heightRatio = screenRect.size.height * screenRate / image.size.height;
        CGFloat ratio = (widthRatio < heightRatio) ? widthRatio : heightRatio;
        
        width = image.size.width * ratio;
        height = image.size.height * ratio;
    } else {
        thumbnail = [[UIImage alloc]initWithData:[ImageCache getCache:fileName dir:[NSString stringWithFormat:@"%@/bestShot/thumbnail", _childObjectId]]];
        CGFloat widthRatio = screenRect.size.width * screenRate / thumbnail.size.width;
        CGFloat heightRatio = screenRect.size.height * screenRate / thumbnail.size.height;
        CGFloat ratio = (widthRatio < heightRatio) ? widthRatio : heightRatio;
        
        width = thumbnail.size.width * ratio;
        height = thumbnail.size.height * ratio;
    }   
    
    CGRect rect = CGRectMake((screenRect.size.width - width)/2, (screenRect.size.height - height)/2, width, height);
    
    // modalを作る
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:rect];
    
    if (imageData) {
        imageView.image = image;
    } else {
        imageView.backgroundColor = [UIColor lightGrayColor];
        imageView.image = thumbnail;
        NSMutableDictionary *childProperty = [ChildProperties getChildProperty:_childObjectId];
        PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", [childProperty[@"childImageShardIndex"] integerValue]]];
        [query whereKey:@"imageOf" equalTo:_childObjectId];
        [query whereKey:@"bestFlag" equalTo:@"choosed"];
        [query whereKey:@"date" equalTo:[NSNumber numberWithInt:[fileName intValue]]];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to get childImage for image modal childObjectId:%@ date:%@ error:%@", _childObjectId, fileName, error]];
                return;
            }
            
            if (objects.count < 1) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"childImage for image modal NOT FOUND  childObjectId:%@ date:%@", _childObjectId, fileName]];
                return;                                                                      
            }
            
            PFObject *childImage = objects[0];
            NSString *objectId = childImage.objectId;
            NSString *bucketKey = [NSString stringWithFormat:@"ChildImage%ld/%@", [childProperty[@"childImageShardIndex"] integerValue], objectId];
            [AWSS3Utils singleDownloadWithKey:bucketKey withBlock:^(NSMutableDictionary *params) {
                NSData *imageData = params[@"imageData"];
                imageView.image = [[UIImage alloc]initWithData:imageData];
            }];
        }];
    }
    overlay = [[UIView alloc]initWithFrame:screenRect];
    overlay.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.6];
    [overlay addSubview:imageView];
    
    // tool view
    ImageSelectToolView *toolView = [ImageSelectToolView view];
    toolView.delegate = self;
    [overlay addSubview:toolView];
    CGRect toolViewRect = toolView.frame;
    toolViewRect.origin.x = 0;
    toolViewRect.origin.y = overlay.frame.size.height - toolView.frame.size.height;
    toolView.frame = toolViewRect;
    toolView.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.6];
    
    overlay.alpha = 0.0f;
    [self.view addSubview:overlay];
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         overlay.alpha = 1.0f;
                     }
                     completion:nil];
    
}

- (void)cancel
{
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         overlay.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                        [overlay removeFromSuperview];
                     }];
}

- (void)submit
{
    NSData *imageData = [ImageCache getCache:bestShotList[displayedIndexPath.row] dir:cacheDir];
    [ChildIconManager updateChildIcon:imageData withChildObjectId:_childObjectId];
    [self sendPushNotification];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)close
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
