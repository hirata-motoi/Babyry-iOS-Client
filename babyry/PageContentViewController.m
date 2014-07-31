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
#import "FamilyRole.h"
#import "ImagePageViewController.h"

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
    
    _bestFlagArray = [NSMutableArray arrayWithObjects:@"NO", @"NO", @"NO", @"NO", @"NO", @"NO", @"NO", nil];
    
    _currentUser = [PFUser currentUser];
    
    _isNoImageCellForTutorial = nil;
    
    [self createCollectionView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [_pageContentCollectionView reloadData];
    //NSLog(@"viewDidAppear %d", _pageIndex);

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
    float width = self.view.frame.size.width;
    if (indexPath.row == 0) {
        return CGSizeMake(width, self.view.frame.size.height - 44 - 20  - width*2/3); // TODO magic number
    }
    return CGSizeMake(width/3, width/3);
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
    
    // Cacheからはりつけ
    NSString *imageCachePath = [NSString stringWithFormat:@"%@%@thumb", [object objectForKey:@"objectId"], [[object objectForKey:@"date"] objectAtIndex:indexPath.row]];
    NSData *imageCacheData = [ImageCache getCache:imageCachePath];
    if(imageCacheData) {
        if (indexPath.row == 0) {
            // TODO ここで画像のサイズをうまいこと設定してやる
            cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectTopImage:[UIImage imageWithData:imageCacheData] ratio:(cell.frame.size.height/cell.frame.size.width)]];
            //cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageWithData:imageCacheData]]];
        } else {
            cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageWithData:imageCacheData]]];
            //cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:imageCacheData]];
        }
        [_bestFlagArray replaceObjectAtIndex:indexPath.row withObject:@"YES"];
    } else {
        if (indexPath.row == 0) {
            cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageNamed:@"NoImage"]]];
        } else {
            cell.backgroundView = [[UIImageView alloc] initWithImage:[ImageTrimming makeRectImage:[UIImage imageNamed:@"NoImage"]]];
            if(!_isNoImageCellForTutorial){
                _isNoImageCellForTutorial = cell;
            }
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
        if (_returnValueOfChildName) {
            nameLabel.text = _returnValueOfChildName;
        } else {
            nameLabel.text = [NSString stringWithFormat:@"%@", [object objectForKey:@"name"]];
        }
        nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:cellHeight/8];
        nameLabel.textAlignment = NSTextAlignmentLeft;
        nameLabel.textColor = [UIColor whiteColor];
        nameLabel.shadowColor = [UIColor blackColor];
        nameLabel.frame = CGRectMake(0, cellHeight - cellHeight/8, cellWidth, cellHeight/8);
        [cell addSubview:nameLabel];
        
        _albumLabel = [[UILabel alloc] init];
        _albumLabel.text = @"album";
        _albumLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:20];
        _albumLabel.textColor = [UIColor blackColor];
        _albumLabel.textAlignment = NSTextAlignmentCenter;
        _albumLabel.backgroundColor = [UIColor whiteColor];
        _albumLabel.alpha = 0.5;
        _albumLabel.frame = CGRectMake(cell.frame.size.width - 65, cell.frame.size.height -65, 60, 60);
        _albumLabel.layer.cornerRadius = 30;
        [_albumLabel setClipsToBounds:YES];
        _albumLabel.userInteractionEnabled = YES;
        [cell addSubview:_albumLabel];
        _albumLabel.tag = 1111111;
        UITapGestureRecognizer *singleTapGestureRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTapGestureRecognizer1.numberOfTapsRequired = 1;
        [_albumLabel addGestureRecognizer:singleTapGestureRecognizer1];
        
        _settingLabel = [[UILabel alloc] init];
        _settingLabel.text = @"setting";
        _settingLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:20];
        _settingLabel.textColor = [UIColor blackColor];
        _settingLabel.textAlignment = NSTextAlignmentCenter;
        _settingLabel.backgroundColor = [UIColor whiteColor];
        _settingLabel.alpha = 0.5;
        _settingLabel.frame = CGRectMake(cell.frame.size.width - 65, cell.frame.size.height -65 -65, 60, 60);
        _settingLabel.layer.cornerRadius = 30;
        [_settingLabel setClipsToBounds:YES];
        _settingLabel.userInteractionEnabled = YES;
        [cell addSubview:_settingLabel];
        _settingLabel.tag = 2222222;
        UITapGestureRecognizer *singleTapGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTapGestureRecognizer2.numberOfTapsRequired = 1;
        [_settingLabel addGestureRecognizer:singleTapGestureRecognizer2];
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
                        [_overlay addHoleWithView:_albumLabel padding:0.0f offset:CGSizeMake(0, 0) form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
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
                [self touchEvent:1];
            } else if ([_currentUser[@"tutorialStep"] intValue] == 3) {
                NSLog(@"3で止まっている場合には、すぐに4に遷移させてok");
                _currentUser[@"tutorialStep"] = [NSNumber numberWithInt:4];
                [_currentUser save];
                [_pageContentCollectionView reloadData];
            }
        }
    }
    
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
    
    NSString *whichView;
    
    if (tagNumber > 1 && tagNumber < 8) {
        
        PFObject *familyRole = [FamilyRole getFamilyRole];
        NSString *uploaderUserId = familyRole[@"uploader"];
        
        // チュートリアル中はUploadViewController
        if (![_currentUser objectForKey:@"tutorialStep"] || [[_currentUser objectForKey:@"tutorialStep"] intValue] < 100) {
            whichView = @"Upload";
            
        // アップローダーの場合は当日以外は全部UploadViewController
        } else if ([[PFUser currentUser][@"userId"] isEqualToString:uploaderUserId]) {
            whichView = @"Upload";
            
        // チューザーの場合は、bestshotが決まっていればUploadViewController
        // bestshotが決まっていなければ、MultiUpload
        } else {
            if ([[_bestFlagArray objectAtIndex:tagNumber - 1] isEqualToString:@"YES"]) {
                NSLog(@"fixed bestshot");
                whichView = @"Upload";
            } else {
                NSLog(@"not fixed bestshot");
                whichView = @"MultiUpload";
            }
        }
    } else if (tagNumber == 1) {
        whichView = @"MultiUpload";
    } else if (tagNumber == 1111111) {
        NSLog(@"open album view");
        AlbumViewController *albumViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumViewController"];
        albumViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        albumViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
        albumViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][0];
        albumViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][0];
        
        //[self presentViewController:albumViewController animated:YES completion:NULL];
        [self.navigationController pushViewController:albumViewController animated:YES];
    } else if (tagNumber == 2222222) {
        NSLog(@"open setting view");
        SettingViewController *settingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingViewController"];
        settingViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        settingViewController.childName = [_childArray[_pageIndex] objectForKey:@"name"];
        settingViewController.childBirthday = [_childArray[_pageIndex] objectForKey:@"birthday"];
        settingViewController.pViewController = self;
        [self.navigationController pushViewController:settingViewController animated:YES];
    } else if (tagNumber == 555) {
        if (_isNoImageCellForTutorial) {
            [_overlay hide];
            _overlay = [[ICTutorialOverlay alloc] init];
            _overlay.hideWhenTapped = NO;
            _overlay.animated = YES;
            [_overlay addHoleWithView:_isNoImageCellForTutorial padding:0.0f offset:CGSizeMake(0, 0) form:ICTutorialOverlayHoleFormRoundedRectangle transparentEvent:YES];
            [_tutoLabel removeFromSuperview];
            _tutoLabel.backgroundColor = [UIColor clearColor];
            _tutoLabel.textColor = [UIColor whiteColor];
            _tutoLabel.numberOfLines = 0;
            CGRect frame = _tutoLabel.frame;
            frame.origin.y = 100;
            _tutoLabel.frame = frame;
            _tutoLabel.text = @"過去の画像について(Step 10/13)\n\n前日までの画像について\nベストショットがアップロードされていない過去分のパネルには、後から画像をアップロードすることが可能です。ただし、通常のアップローダー、チューザーという機能はありません。\n画像が入っていないパネルをタップしてください。";
            [_overlay addSubview:_tutoLabel];
            [_overlay show];
        } else {
            // NoImageのUploadViewがないので飛ばす(そうゆう状態の人はチュートリアル不要だし)。
            _currentUser[@"tutorialStep"] = [NSNumber numberWithInt:6];
            [_currentUser save];
            [_pageContentCollectionView reloadData];
        }
    } else if (tagNumber == 777) {
        [_overlay hide];
        [_overlay removeFromSuperview];
        _currentUser[@"tutorialStep"] = [NSNumber numberWithInt:100];
        [_currentUser save];
    }
    
    
    if ([whichView isEqualToString:@"Upload"]) {
        UploadViewController *uploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UploadViewController"];
        uploadViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        uploadViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
        uploadViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][tagNumber -1];
        uploadViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][tagNumber -1];
        uploadViewController.uploadedImage = [_childArray[_pageIndex] objectForKey:@"orgImages"][tagNumber -1];
        uploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        if(uploadViewController.childObjectId && uploadViewController.date && uploadViewController.month && uploadViewController.uploadedImage) {
//            [self presentViewController:uploadViewController animated:YES completion:NULL];
            
            ImagePageViewController *pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ImagePageViewController"];
            pageViewController.childImages = _childImages;
            NSLog(@"pageViewController.childImages : %@", _childImages);
            pageViewController.currentSection = 0;
            pageViewController.currentRow = tagNumber - 1;
            pageViewController.childObjectId = _childObjectId;
            //_pageViewController.name = _name;  // nameをどっかでとってくる
            [self.navigationController setNavigationBarHidden:YES];
            [self.navigationController pushViewController:pageViewController animated:YES];
        } else {
            // TODO インターネット接続がありません的なメッセージいるかも
        }
    } else if ([whichView isEqualToString:@"MultiUpload"]) {
        MultiUploadViewController *multiUploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadViewController"];
        multiUploadViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
        multiUploadViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        multiUploadViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][tagNumber -1];
        multiUploadViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][tagNumber -1];
        multiUploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        if(multiUploadViewController.childObjectId && multiUploadViewController.date && multiUploadViewController.month) {
            //[self presentViewController:multiUploadViewController animated:YES completion:NULL];
            [self.navigationController pushViewController:multiUploadViewController animated:YES];
        } else {
            // TODO インターネット接続がありません的なメッセージいるかも
        }
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
