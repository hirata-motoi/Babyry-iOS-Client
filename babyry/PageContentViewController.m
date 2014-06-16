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

    // くるくる
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    float w = _indicator.frame.size.width;
    float h = _indicator.frame.size.height;
    float x = self.view.frame.size.width/2 - w/2;
    //ちょっと高めの位置にする
    float y = self.view.frame.size.height/3;
    _indicator.frame = CGRectMake(x, y, w, h);
    _indicator.hidesWhenStopped = YES;
    [self.view addSubview:_indicator];
    
    // set show ablum label
    _showAlbumLabel.layer.cornerRadius = 30.0f;
    _showSettingLabel.layer.cornerRadius = 30.0f;

    // forでまわそうぜ。。。
    self.weekUImageView1.image = [_childArray[_pageIndex] objectForKey:@"images"][0];
    self.weekUImageView2.image = [_childArray[_pageIndex] objectForKey:@"images"][1];
    self.weekUImageView3.image = [_childArray[_pageIndex] objectForKey:@"images"][2];
    self.weekUImageView4.image = [_childArray[_pageIndex] objectForKey:@"images"][3];
    self.weekUImageView5.image = [_childArray[_pageIndex] objectForKey:@"images"][4];
    self.weekUImageView6.image = [_childArray[_pageIndex] objectForKey:@"images"][5];
    self.weekUImageView7.image = [_childArray[_pageIndex] objectForKey:@"images"][6];
    self.titleLabel.text = [_childArray[_pageIndex] objectForKey:@"name"];

    // forでね。。。
    NSMutableArray *tmpMonth = [[NSMutableArray alloc] init];
    NSString *year = [[NSString alloc] init];
    NSString *month = [[NSString alloc] init];
    for (int i = 0; i < 7; i++) {
        year = [[_childArray[_pageIndex] objectForKey:@"month"][i] substringToIndex:4];
        month = [[_childArray[_pageIndex] objectForKey:@"month"][i] substringWithRange:NSMakeRange(4, 2)];
        [tmpMonth addObject:[NSString stringWithFormat:@"%@/%@", year, month]];
    }
    
    self.monthLabel1.text = [tmpMonth objectAtIndex:0];
    self.monthLabel2.text = [tmpMonth objectAtIndex:1];
    self.monthLabel3.text = [tmpMonth objectAtIndex:2];
    self.monthLabel4.text = [tmpMonth objectAtIndex:3];
    self.monthLabel5.text = [tmpMonth objectAtIndex:4];
    self.monthLabel6.text = [tmpMonth objectAtIndex:5];
    self.monthLabel7.text = [tmpMonth objectAtIndex:6];
    
    // forでどうやるんだろ
    self.dateLabel1.text = [[_childArray[_pageIndex] objectForKey:@"date"][0] substringWithRange:NSMakeRange(6, 2)];
    self.dateLabel2.text = [[_childArray[_pageIndex] objectForKey:@"date"][1] substringWithRange:NSMakeRange(6, 2)];
    self.dateLabel3.text = [[_childArray[_pageIndex] objectForKey:@"date"][2] substringWithRange:NSMakeRange(6, 2)];
    self.dateLabel4.text = [[_childArray[_pageIndex] objectForKey:@"date"][3] substringWithRange:NSMakeRange(6, 2)];
    self.dateLabel5.text = [[_childArray[_pageIndex] objectForKey:@"date"][4] substringWithRange:NSMakeRange(6, 2)];
    self.dateLabel6.text = [[_childArray[_pageIndex] objectForKey:@"date"][5] substringWithRange:NSMakeRange(6, 2)];
    self.dateLabel7.text = [[_childArray[_pageIndex] objectForKey:@"date"][6] substringWithRange:NSMakeRange(6, 2)];
    
    //NSLog(@"%@", _childArray);
    //NSLog(@"index %d", _pageIndex);

    // TODO
    //[self.logoutButton addTarget:self action:@selector(logout:) forControlEvents:UIControlEventTouchDown];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [_indicator stopAnimating];

    // ViewControllerにcurrentPageIndexを教える
    ViewController *vc = (ViewController*)self.parentViewController.parentViewController;
    vc.currentPageIndex = _pageIndex;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_indicator startAnimating];
    UITouch *touch = [touches anyObject];
    NSLog( @"tag is %d",touch.view.tag );
    if (touch.view.tag > 1 && touch.view.tag < 8) {
        //NSLog(@"open uploadViewController. pageIndex:%d", _pageIndex);
        UploadViewController *uploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UploadViewController"];
        //uploadViewController.pageIndex = _pageIndex;
        //uploadViewController.imageIndex = touch.view.tag;
        uploadViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        uploadViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
        uploadViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][touch.view.tag -1];
        uploadViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][touch.view.tag -1];
        uploadViewController.uploadedImage = [_childArray[_pageIndex] objectForKey:@"images"][touch.view.tag -1];
        uploadViewController.bestFlag = [_childArray[_pageIndex] objectForKey:@"bestFlag"][touch.view.tag -1];
        uploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        if(uploadViewController.childObjectId && uploadViewController.date && uploadViewController.month && uploadViewController.uploadedImage && uploadViewController.bestFlag) {
            [self presentViewController:uploadViewController animated:YES completion:NULL];
        } else {
            // TODO インターネット接続がありません的なメッセージいるかも
        }
    } else if (touch.view.tag == 1) {
        MultiUploadViewController *multiUploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadViewController"];
        multiUploadViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
        multiUploadViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        multiUploadViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][touch.view.tag -1];
        multiUploadViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][touch.view.tag -1];
        multiUploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        if(multiUploadViewController.childObjectId && multiUploadViewController.date && multiUploadViewController.month) {
            [self presentViewController:multiUploadViewController animated:YES completion:NULL];
        } else {
            // TODO インターネット接続がありません的なメッセージいるかも
        }
    } else if (touch.view.tag == 10) {
        NSLog(@"open album view");
        AlbumViewController *albumViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumViewController"];
        albumViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        albumViewController.name = [_childArray[_pageIndex] objectForKey:@"name"];
        albumViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][0];
        albumViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][0];
        [self presentViewController:albumViewController animated:YES completion:NULL];
    }
/*
    switch (touch.view.tag) {
        case 1:
            NSLog(@"1 touched");
            break;
        case 2:
            NSLog(@"2 touched");
            break;
        case 3:
            NSLog(@"3 touched");
            break;
        default:
            break;
    }
*/
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

//- (IBAction)logout:(id)sender {
//    [PFUser logOut];
//    ViewController *controller = [[ViewController init] alloc];
//    [controller openLoginView];
//}

@end
