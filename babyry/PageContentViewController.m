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
    
    _overlay = [[ICTutorialOverlay alloc] init];
    _overlay.hideWhenTapped = NO;
    _overlay.animated = YES;
    _tutoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 170, 300, 250)];
    
    _isFirstLoad = 1;
    
    //NSLog(@"%@", _childArray[_pageIndex]);
    
    //_bestFlagArray = [NSMutableArray arrayWithObjects:@"NO", @"NO", @"NO", @"NO", @"NO", @"NO", @"NO", nil];
    
    _currentUser = [PFUser currentUser];
    
    _isNoImageCellForTutorial = nil;
    _selfRole = [FamilyRole selfRole];
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
    [_pageContentCollectionView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //[_pageContentCollectionView reloadData];

    // ViewControllerにcurrentPageIndexを教える
    ViewController *vc = (ViewController*)self.parentViewController.parentViewController;
    vc.currentPageIndex = _pageIndex;
   
}

-(void)viewWillDisappear:(BOOL)animated
{
    [_overlay hide];
    [_overlay removeFromSuperview];
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
    return CGSizeMake(width/3, width/3);
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
    
    // Cacheからはりつけ
    NSString *ymd = [childImage[@"date"] substringWithRange:NSMakeRange(1, 8)];
    NSString *dd = [ymd substringWithRange:NSMakeRange(6, 2)];
   
    
    NSString *imageCachePath = [NSString stringWithFormat:@"%@%@thumb", _childObjectId , ymd];
    [self setBackgroundViewOfCell:cell withImageCachePath:imageCachePath withIndexPath:indexPath];
    
    float cellWidth = cell.frame.size.width;
    float cellHeight = cell.frame.size.height;

    // date label
    UILabel *dateLabel = [[UILabel alloc] init];
    dateLabel.text = [NSString stringWithFormat:@"%@", dd];
    dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:cellHeight/5];
    dateLabel.textColor = [UIColor whiteColor];
    dateLabel.shadowColor = [UIColor blackColor];
    dateLabel.frame = CGRectMake(0, cellHeight/10, cellWidth, cellHeight/5);
    [cell addSubview:dateLabel];

    // 今日のcellには子供名を表示
    if (indexPath.section == 0 && indexPath.row == 0) {
        UILabel *nameLabel = [[UILabel alloc] init];
        if (_returnValueOfChildName) {
            nameLabel.text = _returnValueOfChildName;
        } else {
            nameLabel.text = [NSString stringWithFormat:@"%@", [[_childArray objectAtIndex:_pageIndex] objectForKey:@"name"]];
        }                                                       
        nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:cellHeight/8];
        nameLabel.textAlignment = NSTextAlignmentLeft;
        nameLabel.textColor = [UIColor whiteColor];
        nameLabel.shadowColor = [UIColor blackColor];
        nameLabel.frame = CGRectMake(0, cellHeight - cellHeight/8, cellWidth, cellHeight/8);
        [cell addSubview:nameLabel];
    }
    
    cell.tag = indexPath.row + 1;
    
    // チュートリアル用
    if (indexPath.row == 0) {
        if (!_currentUser[@"tutorialStep"] || [_currentUser[@"tutorialStep"] intValue] < 100) {
            [_currentUser refresh];
            NSLog(@"Tutorial Step is %d", [_currentUser[@"tutorialStep"] intValue]);
            if ([_currentUser[@"tutorialStep"] intValue] == 1
                || [_currentUser[@"tutorialStep"] intValue] == 4
                || [_currentUser[@"tutorialStep"] intValue] == 5
                || [_currentUser[@"tutorialStep"] intValue] == 6
                || [_currentUser[@"tutorialStep"] intValue] == 7) {
                if (indexPath.row == 0) {
                    if ([_currentUser[@"tutorialStep"] intValue] != 5 && [_currentUser[@"tutorialStep"] intValue] != 6) {
                        // disable all subviews touchevent
                        for (UIView *view in cell.subviews) {
                            for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
                                //NSLog(@"subviews recognizer in cell %@", view);
                                [view removeGestureRecognizer:recognizer];
                            }
                        }
                    }
                    
                    if ([_currentUser[@"tutorialStep"] intValue] == 1 || [_currentUser[@"tutorialStep"] intValue] == 4) {
                        [_overlay addHoleWithView:cell padding:-20.0f offset:CGSizeMake(0, 50) form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
                    } else if ([_currentUser[@"tutorialStep"] intValue] == 6) {
                        [_overlay hide];
                        _overlay = [[ICTutorialOverlay alloc] init];
                        _overlay.hideWhenTapped = NO;
                        _overlay.animated = YES;
                    }
                    
                    [_tutoLabel removeFromSuperview];
                    _tutoLabel.backgroundColor = [UIColor clearColor];
                    _tutoLabel.textColor = [UIColor whiteColor];
                    _tutoLabel.numberOfLines = 0;
                    if ([_currentUser[@"tutorialStep"] intValue] == 1) {
                        _tutoLabel.text = @"Babyryの使い方(Step 1/13)\n\nBabyryのチュートリアルを始めます。Babyryはアップローダーとチューザーに分かれて一日のベストショットを残していくアプリです。\nまずは、アップローダーの機能のチュートリアルを始めます。今日のパネルをタップしてみてください。";
                        CGRect frame = _tutoLabel.frame;
                        frame.origin.y = cell.frame.origin.y + cell.frame.size.height;
                        _tutoLabel.frame = frame;
                    } else if ([_currentUser[@"tutorialStep"] intValue] == 4) {
                        _tutoLabel.text = @"チューザー機能(Step 7/13)\n\nチューザー側に切り替えました。\n今日のパネルをタップしてください。";
                        CGRect frame = _tutoLabel.frame;
                        frame.origin.y = cell.frame.origin.y + cell.frame.size.height;
                        _tutoLabel.frame = frame;
                    } else if ([_currentUser[@"tutorialStep"] intValue] == 5) {
                        _tutoLabel.text = @"チューザー機能(Step 9/13)\n\nベストショットが反映されました。これでアップローダーとチューザー機能のチュートリアルは完了です。画面をタップして次に進んでください。";
                        _overlay.tag = 555;
                        UITapGestureRecognizer *tutoGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
                        tutoGestureRecognizer.numberOfTapsRequired = 1;
                        [_overlay addGestureRecognizer:tutoGestureRecognizer];
                    } else if ([_currentUser[@"tutorialStep"] intValue] == 6) {
                        _tutoLabel.text = @"アルバムについて(Step 12/13)\n\n次はアルバムを見てみましょう。";
                    } else if ([_currentUser[@"tutorialStep"] intValue] == 7) {
                        [_overlay hide];
                        _overlay = [[ICTutorialOverlay alloc] init];
                        _overlay.hideWhenTapped = NO;
                        _overlay.animated = YES;
                        _tutoLabel.text = @"チュートリアルはこれで終了です。\n画面をタップしてBabyryを開始してください。\n\nHave A Nice Babyry Days!";
                        _overlay.tag = 777;
                        UITapGestureRecognizer *tutoGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
                        tutoGestureRecognizer.numberOfTapsRequired = 1;
                        [_overlay addGestureRecognizer:tutoGestureRecognizer];
                    }
                    [_overlay addSubview:_tutoLabel];
                    [_overlay show];
                    
                    /* チュートリアルスキップボタンがうまく動かない。。。
                    _tutoSkipLabel.userInteractionEnabled = YES;
                    _tutoSkipLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 130, 20)];
                    _tutoSkipLabel.layer.borderColor = [UIColor whiteColor].CGColor;
                    _tutoSkipLabel.layer.borderWidth = 1;
                    _tutoSkipLabel.layer.cornerRadius = _tutoSkipLabel.frame.size.height/2;
                    _tutoSkipLabel.textAlignment = NSTextAlignmentCenter;
                    _tutoSkipLabel.text = @"チュートリアルをスキップ";
                    _tutoSkipLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:10];
                    _tutoSkipLabel.textColor = [UIColor whiteColor];
                    _tutoSkipLabel.shadowColor = [UIColor blackColor];
                    _tutoSkipLabel.shadowOffset = CGSizeMake(0.f, 1.f);
                    _tutoSkipLabel.tag = 777;
                    UITapGestureRecognizer *tutoSkipGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
                    tutoSkipGesture.numberOfTapsRequired = 1;
                    [_tutoSkipLabel addGestureRecognizer:tutoSkipGesture];
                    [_overlay addSubview:_tutoSkipLabel];
                    */
                }
            } else if ([_currentUser[@"tutorialStep"] intValue] == 2) {
                NSLog(@"今日のパネルのチュートリアルが途中なのでそちらに遷移させる");
                //[self touchEvent:1];
            } else if ([_currentUser[@"tutorialStep"] intValue] == 3) {
                NSLog(@"3で止まっている場合には、すぐに4に遷移させてok");
                _currentUser[@"tutorialStep"] = [NSNumber numberWithInt:4];
                [_currentUser save];
                [_pageContentCollectionView reloadData];
            }
        }
    }

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
    PFObject *tappedChildImage = [[[_childImages objectAtIndex:indexPath.section] objectForKey:@"images"] objectAtIndex:indexPath.row];
    // chooser
    //    upload待ち
    //    BS選択
    // uploader
    //    +ボタンがないパターン
    if ([self shouldShowMultiUploadView:indexPath]) {
        MultiUploadViewController *multiUploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadViewController"];
        multiUploadViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
        multiUploadViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        multiUploadViewController.date = [tappedChildImage[@"date"] substringWithRange:NSMakeRange(1, 8)];
        multiUploadViewController.month = [tappedChildImage[@"date"] substringWithRange:NSMakeRange(1, 6)];
        multiUploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        if(multiUploadViewController.childObjectId && multiUploadViewController.date && multiUploadViewController.month) {
            //[self presentViewController:multiUploadViewController animated:YES completion:NULL];
            [self.navigationController pushViewController:multiUploadViewController animated:YES];
        } else {
            // TODO インターネット接続がありません的なメッセージいるかも
        }
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
    _dragView.dragViewLabel.text = [NSString stringWithFormat:@"%ld%02ld", currentYearMonth.year, currentYearMonth.month];
    
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

//- (void)touchEvent:(int) tagNumber
//{
//    //UITouch *touch = [touches anyObject];
//    NSLog( @"tag is %d", tagNumber);
//    
//    NSString *whichView;
//    
//    if (tagNumber > 1 && tagNumber < 8) {
//        
//        PFObject *familyRole = [FamilyRole getFamilyRole];
//        NSString *uploaderUserId = familyRole[@"uploader"];
//        
//        // チュートリアル中はUploadViewController
//        if (![_currentUser objectForKey:@"tutorialStep"] || [[_currentUser objectForKey:@"tutorialStep"] intValue] < 100) {
//            whichView = @"Upload";
//            
//        // アップローダーの場合は当日以外は全部UploadViewController
//        } else if ([[PFUser currentUser][@"userId"] isEqualToString:uploaderUserId]) {
//            whichView = @"Upload";
//            
//        // チューザーの場合は、bestshotが決まっていればUploadViewController
//        // bestshotが決まっていなければ、MultiUpload
//        } else {
//              // TODO cell.isChoosedを見て判定すべし
//              whichView = @"Upload";
////            if ([[_bestFlagArray objectAtIndex:tagNumber - 1] isEqualToString:@"YES"]) {
////                NSLog(@"fixed bestshot");
////                whichView = @"Upload";
////            } else {
////                NSLog(@"not fixed bestshot");
////                whichView = @"MultiUpload";
////            }
//        }
//    } else if (tagNumber == 1) {
//        whichView = @"MultiUpload";
//    } else if (tagNumber == 1111111) {
//        NSLog(@"open album view");
//        AlbumViewController *albumViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumViewController"];
//        albumViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
//        albumViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
//        albumViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][0];
//        albumViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][0];
//        
//        //[self presentViewController:albumViewController animated:YES completion:NULL];
//        [self.navigationController pushViewController:albumViewController animated:YES];
//    } else if (tagNumber == 2222222) {
//        NSLog(@"open setting view");
//        SettingViewController *settingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingViewController"];
//        settingViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
//        settingViewController.childName = [_childArray[_pageIndex] objectForKey:@"name"];
//        settingViewController.childBirthday = [_childArray[_pageIndex] objectForKey:@"birthday"];
//        settingViewController.pViewController = self;
//        [self.navigationController pushViewController:settingViewController animated:YES];
//    } else if (tagNumber == 555) {
//        if (_isNoImageCellForTutorial) {
//            [_overlay hide];
//            _overlay = [[ICTutorialOverlay alloc] init];
//            _overlay.hideWhenTapped = NO;
//            _overlay.animated = YES;
//            [_overlay addHoleWithView:_isNoImageCellForTutorial padding:0.0f offset:CGSizeMake(0, 0) form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
//            [_tutoLabel removeFromSuperview];
//            _tutoLabel.backgroundColor = [UIColor clearColor];
//            _tutoLabel.textColor = [UIColor whiteColor];
//            _tutoLabel.numberOfLines = 0;
//            CGRect frame = _tutoLabel.frame;
//            frame.origin.y = 100;
//            _tutoLabel.frame = frame;
//            _tutoLabel.text = @"過去の画像について(Step 10/13)\n\n前日までの画像について\nベストショットがアップロードされていない過去分のパネルには、後から画像をアップロードすることが可能です。ただし、通常のアップローダー、チューザーという機能はありません。\n画像が入っていないパネルをタップしてください。";
//            [_overlay addSubview:_tutoLabel];
//            [_overlay show];
//        } else {
//            // NoImageのUploadViewがないので飛ばす(そうゆう状態の人はチュートリアル不要だし)。
//            _currentUser[@"tutorialStep"] = [NSNumber numberWithInt:6];
//            [_currentUser save];
//            [_pageContentCollectionView reloadData];
//        }
//    } else if (tagNumber == 777) {
//        [_overlay hide];
//        [_overlay removeFromSuperview];
//        _currentUser[@"tutorialStep"] = [NSNumber numberWithInt:100];
//        [_currentUser save];
//    }
//    
//    
//    if ([whichView isEqualToString:@"Upload"]) {
//        UploadViewController *uploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UploadViewController"];
//        uploadViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
//        uploadViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
//        uploadViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][tagNumber -1];
//        uploadViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][tagNumber -1];
//        uploadViewController.uploadedImage = [_childArray[_pageIndex] objectForKey:@"orgImages"][tagNumber -1];
//        uploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//        
//        if(uploadViewController.childObjectId && uploadViewController.date && uploadViewController.month && uploadViewController.uploadedImage) {
////            [self presentViewController:uploadViewController animated:YES completion:NULL];
//            
//            ImagePageViewController *pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ImagePageViewController"];
//            pageViewController.childImages = _childImages;
//            NSLog(@"pageViewController.childImages : %@", _childImages);
//            pageViewController.currentSection = 0;
//            pageViewController.currentRow = tagNumber - 1;
//            pageViewController.childObjectId = _childObjectId;
//            //_pageViewController.name = _name;  // nameをどっかでとってくる
//            [self.navigationController setNavigationBarHidden:YES];
//            [self.navigationController pushViewController:pageViewController animated:YES];
//        } else {
//            // TODO インターネット接続がありません的なメッセージいるかも
//        }
//    } else if ([whichView isEqualToString:@"MultiUpload"]) {
//        MultiUploadViewController *multiUploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadViewController"];
//        multiUploadViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
//        multiUploadViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
//        multiUploadViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][tagNumber -1];
//        multiUploadViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][tagNumber -1];
//        multiUploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//        if(multiUploadViewController.childObjectId && multiUploadViewController.date && multiUploadViewController.month) {
//            //[self presentViewController:multiUploadViewController animated:YES completion:NULL];
//            [self.navigationController pushViewController:multiUploadViewController animated:YES];
//        } else {
//            // TODO インターネット接続がありません的なメッセージいるかも
//        }
//    }
//}

// mergeがtrueだった場合は取得したobjectsを1つ前のsectionにmergeする
- (void)getChildImagesWithYear:(NSInteger)year withMonth:(NSInteger)month withReload:(BOOL)reload
{
    _isLoading = YES;
    PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld%02ld", (long)year, (long)month]];
    [query whereKey:@"imageOf" equalTo:_childObjectId];
    [query whereKey:@"bestFlag" equalTo:@"choosed"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            NSInteger index = [[_childImagesIndexMap objectForKey:[NSString stringWithFormat:@"%ld%02ld", year, month]] integerValue];
            NSMutableDictionary *section = [_childImages objectAtIndex:index];
            NSMutableArray *images = [section objectForKey:@"images"];
            
            NSMutableDictionary *childImageHash = [ArrayUtils arrayToHash:objects withKeyColumn:@"date"];
            for (int i = 0; i < [images count]; i++) {
                PFObject *childImage = [images objectAtIndex:i];
                NSString *ymdWithPrefix = childImage[@"date"];
                
                if ([childImageHash objectForKey:ymdWithPrefix]) {
                    PFObject *childImage = [[childImageHash objectForKey:ymdWithPrefix] objectAtIndex:0];
                    [self cacheThumbnail:childImage];
                    [images replaceObjectAtIndex:i withObject:childImage];
                }
            }
          
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

- (void)cacheThumbnail:(PFObject *)childImage
{
    NSString *ymd = [childImage[@"date"] substringWithRange:NSMakeRange(1, 8)];
   
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
    BOOL needMerge = (comp.day < 7) ? YES : NO;
    NSDateComponents *lastComp = [self dateComps];
    lastComp.month--;
    [self getChildImagesWithYear:lastComp.year withMonth:lastComp.month withReload:YES];
  
    _dateComp = lastComp;
}

// 今週
// 今週じゃない かつ 候補写真がある かつ 未choosed
- (BOOL)shouldShowMultiUploadView:(NSIndexPath *)indexPath
{
    return [self withinOneWeek:indexPath] || [self notChoosedYet:indexPath];
}

- (BOOL)withinOneWeek: (NSIndexPath *)indexPath
{
    PFObject *chilImage = [[[_childImages objectAtIndex:indexPath.section] objectForKey:@"images"] objectAtIndex:indexPath.row];
    NSString *ymd = [chilImage[@"date"] substringWithRange:NSMakeRange(1, 8)];
    NSDateComponents *compToday = [self dateComps];
  
    NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
	[inputDateFormatter setDateFormat:@"yyyyMMdd"];
	NSDate *dateToday = [DateUtils setSystemTimezone: [inputDateFormatter dateFromString:[NSString stringWithFormat:@"%ld%02ld%02ld", compToday.year, compToday.month, compToday.day]]];
	NSDate *dateTappedImage = [DateUtils setSystemTimezone: [inputDateFormatter dateFromString:ymd]];
  
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *diff = [cal components:NSDayCalendarUnit fromDate:dateTappedImage toDate:dateToday options:0];
    
    return [diff day] < 7;
}

- (BOOL)notChoosedYet: (NSIndexPath *)indexPath
{
    // これどうやって判定すんねん
    // 最初にchoosedだけでなく全imageの情報を持ってきておかないといけない
    // 最初に取得した時にunchoosedしかない場合は、ちゃんとthumbnailの情報を保持 or cacheしておく
    // unchoosedしかない場合はその旨のflgを持っておく。 → chooseStatus enum("choosed", "unuploaded", "unchoosed")
    return NO;
}

- (void)setupScrollBarView
{
    _dragViewUpperLimitOffset = 20;
    _dragViewLowerLimitOffset = self.view.bounds.size.height - 44 - 20 - 60;
    
    _dragView = [[DragView alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 70, _dragViewUpperLimitOffset, 70, 60)];
    _dragView.userInteractionEnabled = YES;
    _dragView.delegate = self;
    _dragView.dragViewLabel.text = [NSString stringWithFormat:@"%ld/%02ld", _dateComp.year, _dateComp.month];
    _dragView.dragViewLowerLimitOffset = _dragViewLowerLimitOffset;
    _dragView.dragViewUpperLimitOffset = _dragViewUpperLimitOffset;
    
    [self.view addSubview:_dragView];
}

//- (void)dragView:(UIPanGestureRecognizer *)sender
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
            NSDayCalendarUnit
        fromDate:today];
        
        NSString *ym = [NSString stringWithFormat:@"%ld%02ld", c.year, c.month];
        
        NSMutableDictionary *section;
        if ([childImagesDic objectForKey:ym]) {
            section = [childImagesDic objectForKey:ym];
        } else {     
            section = [[NSMutableDictionary alloc]init];
            [section setObject:[[NSMutableArray alloc]init] forKey:@"images"];
            [section setObject:[[NSNumber numberWithInteger:c.year] stringValue] forKey:@"year"];
            [section setObject:[[NSNumber numberWithInteger:c.month] stringValue] forKey:@"month"];
            [childImagesDic setObject:section forKey:ym];
        }
        
        PFObject *childImage = [[PFObject alloc]initWithClassName:[NSString stringWithFormat:@"ChildImage%ld%02ld%02ld", c.year, c.month, c.day]];
        childImage[@"date"] = [NSString stringWithFormat:@"D%ld%02ld%02ld", c.year, c.month, c.day];
        [[section objectForKey:@"images"] addObject:childImage];
       
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
   
    int n = 0;
    for (NSMutableDictionary *section in _childImages) {
        NSString *ym = [NSString stringWithFormat:@"%@%@", [section objectForKey:@"year"], [section objectForKey:@"month"]];
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
    
    if (!imageCacheData) {
        if ([role isEqualToString:@"uploader"]) {
            // uploadを促す
            if (indexPath.section == 0 && indexPath.row == 0) {
                CellBackgroundViewToEncourageUploadLarge *backgroundView = [CellBackgroundViewToEncourageUploadLarge view];
                CGRect rect = backgroundView.frame;
                rect.size.width = cell.frame.size.width;
                rect.size.height = cell.frame.size.height;
                backgroundView.frame = rect;
                [cell addSubview:backgroundView];
            } else {
                CellBackgroundViewToEncourageUpload *backgroundView = [CellBackgroundViewToEncourageUpload view];
                CGRect rect = backgroundView.frame;
                rect.size.width = self.view.frame.size.width / 3;
                rect.size.height = rect.size.width;
                backgroundView.frame = rect;
                [cell addSubview:backgroundView];
                
                if(!_isNoImageCellForTutorial){
                    _isNoImageCellForTutorial = cell;
                }
            }
        } else {
            // upload待ち
            if (indexPath.section == 0 && indexPath.row == 0) {
                CellBackgroundViewToWaitUploadLarge *backgroundView = [CellBackgroundViewToWaitUploadLarge view];
                CGRect rect = backgroundView.frame;
                rect.size.width = cell.frame.size.width;
                rect.size.height = cell.frame.size.height;
                backgroundView.frame = rect;
                [cell addSubview:backgroundView];
            } else {
                CellBackgroundViewToWaitUpload *backgroundView = [CellBackgroundViewToWaitUpload view];
                CGRect rect = backgroundView.frame;
                rect.size.width = cell.frame.size.width;
                rect.size.height = cell.frame.size.height;
                backgroundView.frame = rect;
                [cell addSubview:backgroundView];
                if(!_isNoImageCellForTutorial){
                    _isNoImageCellForTutorial = cell;
                }
            }
        }
        return;
    }
    
    // TODO best shot未選択時の分岐
//    if (uploader) {
//        if (今週) {
//            // 今週の場合はuploadを促す + choose待ち表記
//        } else {
//            // 今週より前の場合はuploadを促す
//        }
//    } else {
//        // chooseをうながす
//    }
    
    // best shotが既に選択済の場合は普通に写真を表示
    if (indexPath.section == 0 && indexPath.row == 0) {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectTopImage:[UIImage imageWithData:imageCacheData] ratio:(cell.frame.size.height/cell.frame.size.width)]];
    } else {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageWithData:imageCacheData]]];
    }
    cell.isChoosed = YES;
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
