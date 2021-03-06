//
//  ImageOperationViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageOperationViewController.h"
#import "ViewController.h"
#import "CommentViewController.h"
#import "PageContentViewController.h"
#import "UploadViewController.h"
#import "ImageCache.h"
#import "ImageTrimming.h"
#import "PushNotification.h"
#import "Navigation.h"
#import "AlbumTableViewController.h"
#import "ImageToolbarViewController.h"
#import "Partner.h"
#import "NotificationHistory.h"
#import "Logger.h"
#import "ChildProperties.h"

@interface ImageOperationViewController ()

@end

@implementation ImageOperationViewController {
    NSMutableDictionary *childProperty;
}


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
    
    childProperty = [ChildProperties getChildProperty:_childObjectId];
    
    _selectedBestshotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SelectedBestshot"]];
    
    // タップでoperationViewを非表示にする
    UITapGestureRecognizer *hideOperationViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideOperationView:)];
    hideOperationViewTapGestureRecognizer.numberOfTapsRequired = 1;
    self.view.userInteractionEnabled = YES;
    [self.view addGestureRecognizer:hideOperationViewTapGestureRecognizer];
    
    // 画像がなければコメントは出来ない
    // プリロード(サムネイルだけで本画像ではない)時もコメントは出さない(出せない)
    if (_fromMultiUpload) {
        [self setupBestLabel];
    }
    [self setupCommentView];
    // 画像削除、保存、コメントは全部toolbar経由にする
    [self setupToolbar];
    [self setupNavigation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self getBestShotIndex] == _pageIndex) {
        [self.view addSubview:_selectedBestshotView];
        [self setBestShotToBack];
    }
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_selectedBestshotView removeFromSuperview];
}

- (void)openPhotoLibrary
{
    [[[UIAlertView alloc] initWithTitle:@"写真を変更しますか？"
                                message:@"フォトアルバムから新たに写真を選択し入れ替えることが可能です。ただし、現在保存されている画像は上書き保存されるため閲覧できなくなります。写真変更を行いますか？"
                               delegate:self
                      cancelButtonTitle:@"キャンセル"
                      otherButtonTitles:@"写真変更", nil] show];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            break;
        case 1:
        {
            AlbumTableViewController *albumTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumTableViewController"];
            albumTableViewController.month = _month;
            albumTableViewController.childObjectId = _childObjectId;
            albumTableViewController.date = _date;
            albumTableViewController.uploadViewController = _uploadViewController;
            albumTableViewController.uploadType = @"single";
            [self.navigationController pushViewController:albumTableViewController animated:YES];
        }
            break;
    }
}

- (void)hideOperationView:(id)sender
{
    self.view.hidden = YES;
}

- (void)setupCommentView
{
    CommentViewController *commentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CommentViewController"];
    commentViewController.childObjectId = _childObjectId;
    commentViewController.name = _name;
    commentViewController.date = _date;
    commentViewController.month = _month;
    // つかってないんじゃないの？
    //commentViewController.imageInfo = _imageInfo;
    commentViewController.indexPath = _indexPath;
    _commentView = commentViewController.view;
    _commentView.hidden = NO;
    _commentView.frame = CGRectMake(self.view.frame.size.width, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height -44 -20 -44);
    [self addChildViewController:commentViewController];
    [self.view addSubview:_commentView];
}

// NavigationController(self.navigationController)を使うとPageViewControllerがずれるため
// self.navigationControllerは非表示にして、自前でnavigationを作る
- (void)setupNavigation
{
    [self setColorForNavigation];
   
    // back button
    UIButton *backButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 6, 44, 32)];
    [backButton setBackgroundImage:[UIImage imageNamed:@"angleLeftReverse"] forState:UIControlStateNormal];
    UITapGestureRecognizer *back = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doBack)];
    [backButton addGestureRecognizer:back];
    [_navbar addSubview:backButton];
    
    // title
    NSString *yyyy =  [_date substringWithRange:NSMakeRange(0, 4)];
    NSString *mm   =  [_date substringWithRange:NSMakeRange(4, 2)];
    NSString *dd   =  [_date substringWithRange:NSMakeRange(6, 2)];
    
    [Navigation setTitle:_navbarItem withTitle:[NSString stringWithFormat:@"%@年%@月%@日", yyyy, mm, dd] withSubtitle:_uploadViewController.promptText withFont:nil withFontSize:0 withColor:nil];
}

- (void)setupToolbar
{
    ImageToolbarViewController *imageToolbarViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ImageToolbarViewController"];
    imageToolbarViewController.commentView = _commentView;
    imageToolbarViewController.uploadViewController = _uploadViewController;
    imageToolbarViewController.openCommentView = _openCommentView;
    imageToolbarViewController.childObjectId = _childObjectId;
    imageToolbarViewController.date = _date;
    
    _toolbarView = imageToolbarViewController.view;
    _toolbarView.hidden = NO;
    CGRect frame = CGRectMake(0, self.view.frame.size.height - imageToolbarViewController.view.frame.size.height, imageToolbarViewController.view.frame.size.width, imageToolbarViewController.view.frame.size.height);
    _toolbarView.frame = frame;
    [self addChildViewController:imageToolbarViewController];
    [self.view addSubview:_toolbarView];
}

- (void)setColorForNavigation
{
    [Navigation setNavbarColor:_navbar withColor:nil withEtcElements:@[_statusBarCoverView]];
}

- (void)doBack
{
    [self.navigationController popViewControllerAnimated:YES];
    [self.navigationController setNavigationBarHidden:NO];
}

-(void)setupBestLabel
{
    // ベスト以外の星、全部の写真に付ける
    _unSelectedBestshotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UnSelectedBestshot"]];
    
    // どの画像でも定位置に張る
    int bestLabelWidth = self.view.frame.size.width/6;
    int x = self.view.frame.size.width - bestLabelWidth - 5;
    int y = self.view.frame.size.height -50 - bestLabelWidth -5;
    _unSelectedBestshotView.frame = CGRectMake(x, y, bestLabelWidth, bestLabelWidth*0.925);
    [self.view addSubview:_unSelectedBestshotView];

    // ベストショットのほうもはる
    _selectedBestshotView.frame = _unSelectedBestshotView.frame;
    if ([self getBestShotIndex] == (int)_pageIndex) {
        [self.view addSubview:_selectedBestshotView];
    } else {
        if ([_myRole isEqualToString:@"uploader"]) {
            _unSelectedBestshotView.hidden = YES;
        }
    }
    
    if ([_myRole isEqualToString:@"chooser"]) {
        UITapGestureRecognizer *selectBestShotGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectBestShot:)];
        selectBestShotGesture.numberOfTapsRequired = 1;
        _unSelectedBestshotView.userInteractionEnabled = YES;
        [_unSelectedBestshotView addGestureRecognizer:selectBestShotGesture];
    }
}

- (void) selectBestShot:(id) sender
{
    _selectedBestshotView.frame = [sender view].frame;
    [self.view addSubview:_selectedBestshotView];
    [self setBestShotToBack];
    [self setBestShotIndex:_pageIndex];
   
    UIImage *thumbImage = [ImageCache makeThumbNail:_uploadedImage];
    NSData *thumbData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(thumbImage, 0.7f)];
    NSData *fullsizeData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(_uploadedImage, 1.0f)];
    [ImageCache setCache:_date image:thumbData dir:[NSString stringWithFormat:@"%@/bestShot/thumbnail", _childObjectId]];
    [ImageCache setCache:_date image:fullsizeData dir:[NSString stringWithFormat:@"%@/bestShot/fullsize", _childObjectId]];
}                                                                                                    

- (int)getBestShotIndex
{
    int num = 0;
    for (NSString *flag in _bestImageIndexArray) {
        if([flag isEqualToString:@"YES"]) {
            return num;
        }
        num++;
    }
    return -1;
}

- (void)setBestShotIndex:(NSInteger)index
{
    for (int i = 0; i < [_bestImageIndexArray count]; i++) {
        if (i == index) {
            [_bestImageIndexArray replaceObjectAtIndex:i withObject:@"YES"];
        } else {
            [_bestImageIndexArray replaceObjectAtIndex:i withObject:@"NO"];
        }
    }
    
    // bestshotのobjectIdを調べる
    NSString *bestObjectId = [[[_uploadViewController.childCachedImageArray objectAtIndex:index] componentsSeparatedByString:@"-"] lastObject];
    
    // Parseを更新(Classに外出しでも良さげ)
    PFQuery *childImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)[childProperty[@"childImageShardIndex"] integerValue]]];
    childImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [childImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
    [childImageQuery whereKey:@"date" equalTo:[NSNumber numberWithInteger:[_date integerValue]]];
    [childImageQuery orderByAscending:@"createdAt"];
    [childImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error) {
            int indexOfParse = 0;
            for (PFObject *object in objects) {
                if ([object.objectId isEqualToString:bestObjectId]) {
                    if (![object[@"bestFlag"] isEqualToString:@"choosed"]) {
                        object[@"bestFlag"] =  @"choosed";
                        [object saveInBackground];
                    }
                } else {
                    if (![object[@"bestFlag"] isEqualToString:@"unchoosed"]) {
                        object[@"bestFlag"] =  @"unchoosed";
                        [object saveInBackground];
                    }
                }
                indexOfParse++;
            }
            PFObject *partner = (PFUser *)[Partner partnerUser];
            if (partner != nil) {
                NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
                transitionInfoDic[@"event"] = @"bestShotChosen";
                transitionInfoDic[@"date"] = _date;
                transitionInfoDic[@"section"] = [NSString stringWithFormat:@"%d", _indexPath.section];
                transitionInfoDic[@"row"] = [NSString stringWithFormat:@"%d", _indexPath.row];
                transitionInfoDic[@"childObjectId"] = _childObjectId;
                NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
                options[@"formatArgs"] = [NSArray arrayWithObject:[PFUser currentUser][@"nickName"]];
                options[@"data"] = [[NSMutableDictionary alloc]
                                    initWithObjects:@[@"Increment", transitionInfoDic]
                                    forKeys:@[@"badge", @"transitionInfo"]];
                [PushNotification sendInBackground:@"bestShotChosen" withOptions:options];
                [self createNotificationHistory:@"bestShotChanged"];
            }
            
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in setBestShotIndex : %@", error]];
        }
    }];
}

// これもクラス化？
- (void)createNotificationHistory:(NSString *)type
{
    [NSThread detachNewThreadSelector:@selector(executeNotificationHistory:) toTarget:self withObject:[[NSMutableDictionary alloc]initWithObjects:@[type] forKeys:@[@"type"]]];
}

- (void)executeNotificationHistory:(id)param
{
    NSString *type = [param objectForKey:@"type"];
    PFObject *partner = (PFUser *)[Partner partnerUser];
    [NotificationHistory createNotificationHistoryWithType:type withTo:partner[@"userId"] withChild:_childObjectId withDate:[_date integerValue]];
}

- (void)setBestShotToBack
{
    [self.view sendSubviewToBack:_selectedBestshotView];
    [self.view sendSubviewToBack:_unSelectedBestshotView];
    if ([_myRole isEqualToString:@"uploader"]) {
        _unSelectedBestshotView.hidden = YES;
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
