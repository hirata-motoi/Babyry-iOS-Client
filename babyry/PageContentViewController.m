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
    self.dateLabel1.text = [_childArray[_pageIndex] objectForKey:@"date"][0];
    self.dateLabel2.text = [_childArray[_pageIndex] objectForKey:@"date"][1];
    self.dateLabel3.text = [_childArray[_pageIndex] objectForKey:@"date"][2];
    self.dateLabel4.text = [_childArray[_pageIndex] objectForKey:@"date"][3];
    self.dateLabel5.text = [_childArray[_pageIndex] objectForKey:@"date"][4];
    self.dateLabel6.text = [_childArray[_pageIndex] objectForKey:@"date"][5];
    self.dateLabel7.text = [_childArray[_pageIndex] objectForKey:@"date"][6];
    
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

    // ViewControllerにcurrentPageIndexを教える
    ViewController *vc = (ViewController*)self.parentViewController.parentViewController;
    vc.currentPageIndex = _pageIndex;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    //NSLog( @"%d",touch.view.tag );
    if (touch.view.tag > 1 && touch.view.tag < 8) {
        //NSLog(@"open uploadViewController. pageIndex:%d", _pageIndex);
        UploadViewController *uploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UploadViewController"];
        //uploadViewController.pageIndex = _pageIndex;
        //uploadViewController.imageIndex = touch.view.tag;
        uploadViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        uploadViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][touch.view.tag -1];
        uploadViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][touch.view.tag -1];
        uploadViewController.uploadedImage = [_childArray[_pageIndex] objectForKey:@"images"][touch.view.tag -1];
        uploadViewController.bestFlag = [_childArray[_pageIndex] objectForKey:@"bestFlag"][touch.view.tag -1];
        
        if(uploadViewController.childObjectId && uploadViewController.date && uploadViewController.month && uploadViewController.uploadedImage && uploadViewController.bestFlag) {
            [self presentViewController:uploadViewController animated:YES completion:NULL];
        } else {
            // TODO インターネット接続がありません的なメッセージいるかも
        }
    } else if (touch.view.tag == 1) {
        MultiUploadViewController *multiUploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadViewController"];
        multiUploadViewController.childObjectId = [_childArray[_pageIndex] objectForKey:@"objectId"];
        multiUploadViewController.date = [_childArray[_pageIndex] objectForKey:@"date"][touch.view.tag -1];
        multiUploadViewController.month = [_childArray[_pageIndex] objectForKey:@"month"][touch.view.tag -1];
        if(multiUploadViewController.childObjectId && multiUploadViewController.date && multiUploadViewController.month) {
            [self presentViewController:multiUploadViewController animated:YES completion:NULL];
        } else {
            // TODO インターネット接続がありません的なメッセージいるかも
        }
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
