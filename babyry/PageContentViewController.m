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
#import "AlbumViewController.h"
#import "ImageTrimming.h"
#import "SettingViewController.h"

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
    //NSLog(@"%@", _childArray[_pageIndex]);
    
    [self createCollectionView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [_pageContentCollectionView reloadData];
    //NSLog(@"viewDidAppear %d", _pageIndex);

    // ViewControllerにcurrentPageIndexを教える
    ViewController *vc = (ViewController*)self.parentViewController.parentViewController;
    vc.currentPageIndex = _pageIndex;
}

-(void)createCollectionView
{
    // UICollectionViewの土台を作成
    _pageContentCollectionView.delegate = self;
    _pageContentCollectionView.dataSource = self;
    [_pageContentCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"PageContentCollectionView"];
    
    [self.view addSubview:_pageContentCollectionView];
}

// セルの数を指定するメソッド
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    //NSLog(@"とりあえず7個だす。下まで行ったらロードする感じの方が良いかな");
    return 7;
}

// セルの大きさを指定するメソッド
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    float size = self.view.frame.size.width;
    if (indexPath.row == 0) {
        return CGSizeMake(size, self.view.frame.size.height - 50 - size*2/3);
    }
    return CGSizeMake(size/3, size/3);
}

// 指定された場所のセルを作るメソッド
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //セルを再利用 or 再生成
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PageContentCollectionView" forIndexPath:indexPath];
    for (UIView *view in [cell subviews]) {
        //NSLog(@"remove cell's child view");
        [view removeFromSuperview];
    }
    
    PFObject *object = [_childArray objectAtIndex:_pageIndex];
    //NSLog(@"month : %@", [[object objectForKey:@"month"] objectAtIndex:indexPath.row]);
    
    // Cacheからはりつけ
    NSString *imageCachePath = [NSString stringWithFormat:@"%@%@thumb", [object objectForKey:@"objectId"], [[object objectForKey:@"date"] objectAtIndex:indexPath.row]];
    NSData *imageCacheData = [ImageCache getCache:imageCachePath];
    if(imageCacheData) {
        if (indexPath.row == 0) {
            cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectTopImage:[UIImage imageWithData:imageCacheData] ratio:(cell.frame.size.height/cell.frame.size.width)]];
            //cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageWithData:imageCacheData]]];
        } else {
            cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageWithData:imageCacheData]]];
            //cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:imageCacheData]];
        }
    } else {
        if (indexPath.row == 0) {
            cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageNamed:@"NoImage"]]];
        } else {
            cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageNamed:@"NoImage"]]];
        }
    }

    NSString *yyyy = [[[object objectForKey:@"month"] objectAtIndex:indexPath.row] substringToIndex:4];
    NSString *mm = [[[object objectForKey:@"month"] objectAtIndex:indexPath.row] substringWithRange:NSMakeRange(4, 2)];
    NSString *dd = [[[object objectForKey:@"date"] objectAtIndex:indexPath.row] substringWithRange:NSMakeRange(6, 2)];
    float cellWidth = cell.frame.size.width;
    float cellHeight = cell.frame.size.height;

    // month label
    UILabel *monthLabel = [[UILabel alloc] init];
    monthLabel.text = [NSString stringWithFormat:@"%@/%@", yyyy, mm];
    monthLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:cellHeight/10];
    monthLabel.textColor = [UIColor whiteColor];
    monthLabel.shadowColor = [UIColor blackColor];
    monthLabel.frame = CGRectMake(2, 0, cellWidth, cellHeight/10);
    [cell addSubview:monthLabel];
    
    // date label
    UILabel *dateLabel = [[UILabel alloc] init];
    dateLabel.text = [NSString stringWithFormat:@"%@", dd];
    dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:cellHeight/5];
    dateLabel.textColor = [UIColor whiteColor];
    dateLabel.shadowColor = [UIColor blackColor];
    dateLabel.frame = CGRectMake(0, cellHeight/10, cellWidth, cellHeight/5);
    [cell addSubview:dateLabel];
    
    // child name label
    if (indexPath.row == 0) {
        UILabel *nameLabel = [[UILabel alloc] init];
        nameLabel.text = [NSString stringWithFormat:@"%@", [object objectForKey:@"name"]];
        nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:cellHeight/8];
        nameLabel.textAlignment = NSTextAlignmentLeft;
        nameLabel.textColor = [UIColor whiteColor];
        nameLabel.shadowColor = [UIColor blackColor];
        nameLabel.frame = CGRectMake(0, cellHeight - cellHeight/8, cellWidth, cellHeight/8);
        [cell addSubview:nameLabel];
        
        UILabel *albumLabel = [[UILabel alloc] init];
        albumLabel.text = @"album";
        albumLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:20];
        albumLabel.textColor = [UIColor blackColor];
        albumLabel.textAlignment = NSTextAlignmentCenter;
        albumLabel.backgroundColor = [UIColor whiteColor];
        albumLabel.alpha = 0.5;
        albumLabel.frame = CGRectMake(cell.frame.size.width - 65, cell.frame.size.height -65, 60, 60);
        albumLabel.layer.cornerRadius = 30;
        [albumLabel setClipsToBounds:YES];
        albumLabel.userInteractionEnabled = YES;
        [cell addSubview:albumLabel];
        albumLabel.tag = 1111111;
        UITapGestureRecognizer *singleTapGestureRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTapGestureRecognizer1.numberOfTapsRequired = 1;
        [albumLabel addGestureRecognizer:singleTapGestureRecognizer1];
        
        UILabel *settingLabel = [[UILabel alloc] init];
        settingLabel.text = @"setting";
        settingLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:20];
        settingLabel.textColor = [UIColor blackColor];
        settingLabel.textAlignment = NSTextAlignmentCenter;
        settingLabel.backgroundColor = [UIColor whiteColor];
        settingLabel.alpha = 0.5;
        settingLabel.frame = CGRectMake(cell.frame.size.width - 65, cell.frame.size.height -65 -65, 60, 60);
        settingLabel.layer.cornerRadius = 30;
        [settingLabel setClipsToBounds:YES];
        settingLabel.userInteractionEnabled = YES;
        [cell addSubview:settingLabel];
        settingLabel.tag = 2222222;
        UITapGestureRecognizer *singleTapGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTapGestureRecognizer2.numberOfTapsRequired = 1;
        [settingLabel addGestureRecognizer:singleTapGestureRecognizer2];
        
        
        // 穴あけ
        /*
        ICTutorialOverlay *overlay = [[ICTutorialOverlay alloc] init];
        overlay.hideWhenTapped = NO;
        overlay.animated = YES;
        [overlay addHoleWithView:albumLabel padding:0.0f offset:CGSizeMake(0, 50) form:ICTutorialOverlayHoleFormCircle transparentEvent:YES];
        
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 170, 220, 150)];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.numberOfLines = 0;
        label.text = @"You can place any views on the overlay";
        [overlay addSubview:label];
        
        [overlay show];
        */
    }
    
    cell.tag = indexPath.row + 1;
    // ジェスチャー定義
    //UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    //doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    //[cell addGestureRecognizer:doubleTapGestureRecognizer];

    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    // ダブルタップに失敗した時だけシングルタップとする
    //[singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
    [cell addGestureRecognizer:singleTapGestureRecognizer];
    
    // チュートリアル用
    /*
    if (![PFUser currentUser][@"tutorialStep"] || ![[PFUser currentUser][@"tutorialStep"] isEqualToString:@"complete"]) {
        if (indexPath.row == 0) {
            // disable all subviews touchevent
            for (UIView *view in cell.subviews) {
                for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
                    NSLog(@"subviews recognizer in cell %@", view);
                    [view removeGestureRecognizer:recognizer];
                }
            }
            
            _overlay = [[ICTutorialOverlay alloc] init];
            _overlay.hideWhenTapped = NO;
            _overlay.animated = YES;
            [_overlay addHoleWithView:cell padding:-20.0f offset:CGSizeMake(0, 50) form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];

            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 170, 220, 150)];
            label.backgroundColor = [UIColor clearColor];
            label.textColor = [UIColor whiteColor];
            label.numberOfLines = 0;
            label.text = @"ここをタップして今日の画像を設定しましょう";
            [_overlay addSubview:label];
        
            [_overlay show];
        }
    }
    */
    
    return cell;
}

-(void)handleDoubleTap:(id) sender
{
    NSLog(@"double tap");
}

-(void)handleSingleTap:(id) sender
{
    NSLog(@"single tap");
    NSLog(@"single tap %d", [[sender view] tag]);
    [self touchEvent:[[sender view] tag]];
}

- (void)touchEvent:(int) tagNumber
{
    //UITouch *touch = [touches anyObject];
    NSLog( @"tag is %d", tagNumber);
    if (tagNumber > 1 && tagNumber < 8) {
    
        //NSLog(@"open uploadViewController. pageIndex:%d", _pageIndex);
        UploadViewController *uploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UploadViewController"];
        //uploadViewController.pageIndex = _pageIndex;
        //uploadViewController.imageIndex = touch.view.tag;
        uploadViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        uploadViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
        uploadViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][tagNumber -1];
        uploadViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][tagNumber -1];
        uploadViewController.uploadedImage = [_childArray[_pageIndex] objectForKey:@"orgImages"][tagNumber -1];
        uploadViewController.bestFlag = [_childArray[_pageIndex] objectForKey:@"bestFlag"][tagNumber -1];
        uploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        if(uploadViewController.childObjectId && uploadViewController.date && uploadViewController.month && uploadViewController.uploadedImage && uploadViewController.bestFlag) {
            [self presentViewController:uploadViewController animated:YES completion:NULL];
        } else {
            // TODO インターネット接続がありません的なメッセージいるかも
        }
    } else if (tagNumber == 1) {
        //[_overlay hide];
        
        MultiUploadViewController *multiUploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadViewController"];
        multiUploadViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
        multiUploadViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        multiUploadViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][tagNumber -1];
        multiUploadViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][tagNumber -1];
        multiUploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        if(multiUploadViewController.childObjectId && multiUploadViewController.date && multiUploadViewController.month) {
            [self presentViewController:multiUploadViewController animated:YES completion:NULL];
        } else {
            // TODO インターネット接続がありません的なメッセージいるかも
        }
    } else if (tagNumber == 1111111) {
        NSLog(@"open album view");
        AlbumViewController *albumViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumViewController"];
        albumViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        albumViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
        albumViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][0];
        albumViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][0];
        [self presentViewController:albumViewController animated:YES completion:NULL];
    } else if (tagNumber == 2222222) {
        NSLog(@"open setting view");
        SettingViewController *settingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingViewController"];
        settingViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        settingViewController.childName = [_childArray[_pageIndex] objectForKey:@"name"];
        settingViewController.childBirthday = [_childArray[_pageIndex] objectForKey:@"birthday"];
        [self presentViewController:settingViewController animated:YES completion:NULL];
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
