//
//  TagAlbumOperationViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/14.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TagAlbumOperationViewController.h"
#import "TagAlbumViewController.h"

@interface TagAlbumOperationViewController ()

@end

@implementation TagAlbumOperationViewController
@synthesize delegate = _delegate;

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
    if (!_tagId) {
        _tagId = [NSNumber numberWithInt:0]; //インスタンス化した時にpropertyがセットされていなかった場合の初期値
    }
    
    [self setupViewTappedAction];
    [self setupOperationView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// タップでoperationViewを非表示にする
- (void)setupViewTappedAction
{
    UITapGestureRecognizer *hideOperationViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideOperationView:)];
    hideOperationViewTapGestureRecognizer.numberOfTapsRequired = 1;
    self.view.userInteractionEnabled = YES;
    [self.view addGestureRecognizer:hideOperationViewTapGestureRecognizer];
}

- (void)hideOperationView:(id)sender
{
    self.view.hidden = YES;
}

- (void)setupOperationView
{
    self.tagAlbumOperationView.layer.cornerRadius = 15;
    if (_frameOption) {
        int x      = [_frameOption[@"x"] intValue];
        int y      = [_frameOption[@"y"] intValue];
        int width  = [_frameOption[@"width"] intValue];
        int height = [_frameOption[@"height"] intValue];
        self.tagAlbumOperationView.frame = CGRectMake(x, y, width, height);
    }

    // TODO TagView.mと共通化できる部分があるので、Tagクラスみたいなものに切り出したい
    
    // ここは滅多に変更されるもんじゃないのでキャッシュしておく
    PFQuery *query = [PFQuery queryWithClassName:@"Tag"];
    query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            if (objects.count > 0) {
                [self setTagObjects:objects];
            } else {
                // TODO tagのマスター情報がないときはどうしようかな
            }
        }
    }];
    
    // cancel button  適当に作る
    UILabel *tagCancelButton = [[UILabel alloc]initWithFrame:CGRectMake(40, 60, 80, 30)];
    tagCancelButton.text = @"tag cancel";
    tagCancelButton.backgroundColor = [UIColor grayColor];
    tagCancelButton.layer.cornerRadius = 10;
    tagCancelButton.clipsToBounds = YES;
    UITapGestureRecognizer *cancelGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cancelTagSelection)];
    cancelGesture.numberOfTapsRequired = 1;
    tagCancelButton.userInteractionEnabled = YES;
    [tagCancelButton addGestureRecognizer:cancelGesture];
    [_tagAlbumOperationView addSubview:tagCancelButton];
    
    
    // tap event
    UITapGestureRecognizer *tagTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(narrowDownByTag:)];
    tagTapGestureRecognizer.numberOfTapsRequired = 1;
    [_tagAlbumOperationView addGestureRecognizer:tagTapGestureRecognizer];
}

- (void)setTagObjects:(NSArray *)tagMasterObjects
{
    _tags = [[NSMutableArray alloc]init];
    for (PFObject *tagInfo in tagMasterObjects) {
        UIImageView *tag = [self tagObject:tagInfo];
        [_tags addObject:tag];
    }
    [self showTags];
}

- (UIImageView *)tagObject:(PFObject *)tagInfo
{
    NSString *imageName = [[NSString alloc]init];
    

    // TODO どっかに切り出したい。TagImageクラスとか
    if ( [tagInfo[@"color"] isEqualToString:@"red"] ) {
        imageName = @"badgeRed";
    } else if ( [tagInfo[@"color"] isEqualToString:@"blue"] ) {
        imageName = @"badgeBlue";
    }
    
    UIImage *image = [UIImage imageNamed:imageName];
    
    int y      = 10;
    int width  = 40;
    int height = 40;
    int x      = 10 + (10 + width)  * ([tagInfo[@"tagId"] intValue] - 1);
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(x, y, width, height)];
    imageView.image = image;
    imageView.tag = [tagInfo[@"tagId"] intValue];
    imageView.userInteractionEnabled = YES;
    imageView.alpha = 0.3;
    
    if ([tagInfo[@"tagId"] isEqualToNumber:_tagId]) {
        imageView.alpha = 1;
    }
    
    // ViewControllerが保持するtagObjectはalphaなし
    if ([_holdedBy isEqualToString:@"ViewController"]) {
        imageView.alpha = 1;
    }
    
    // gesture recognizer
    UITapGestureRecognizer *tagTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(narrowDownByTag:)];
    tagTapGestureRecognizer.numberOfTapsRequired = 1;
    imageView.userInteractionEnabled = YES;
    [imageView addGestureRecognizer:tagTapGestureRecognizer];
    
    return imageView;
}

- (void)showTags
{
    for (UIImageView *tag in _tags) {
        [_tagAlbumOperationView addSubview:tag];
    }
}

- (void)narrowDownByTag:(id)sender
{
    NSInteger tag = [[sender view]tag]; // ここではtagにtagIdをintegerに変換したものが入る
    if (!tag) {
        return;
    }
    
    // tapされたtag以外を半透明にする
    for (UIImageView *tagView in _tags) {
        if (tagView.tag == tag) {
            tagView.alpha = 1;
            continue;
        }
        
        tagView.alpha = 0.3;
    }
    
    // PageViewControllerに保持されているインスタンスの場合は
    // TagAlbumViewControllerを実体化
    if ( [_holdedBy isEqualToString:@"PageViewController"] ) {
        NSString *childObjectId = [_delegate getDisplayedChildObjectId];
        //NSInteger year = [_delegate getDisplayedYear];
        NSMutableDictionary *yearMonthMap = [_delegate getYearMonthMap];

        if (_tagAlbumViewController) {
            [self cancelTagSelection];
        }
        
        _tagAlbumViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TagAlbumViewController"];
        _tagAlbumViewController.tagId = [NSNumber numberWithInteger:tag];
        _tagAlbumViewController.childObjectId = childObjectId;
        _tagAlbumViewController.yearMonthMap = yearMonthMap;
        [self.parentViewController addChildViewController:_tagAlbumViewController];
        [self.parentViewController.view insertSubview:_tagAlbumViewController.view belowSubview:self.view];
        [self clearTagAlpha];
    } else {
        // 画面更新のnotificationを登録
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        [params setObject:[NSNumber numberWithInteger:tag] forKey:@"tagId"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"selectedTagChanged" object:params userInfo:nil];
    }
}

- (void)clearTagAlpha
{
    for (UIImageView *tag in _tags) {
        tag.alpha = 1;
    }
}

- (void)cancelTagSelection
{
    [_tagAlbumViewController.view removeFromSuperview];
    [_tagAlbumViewController removeFromParentViewController];
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
