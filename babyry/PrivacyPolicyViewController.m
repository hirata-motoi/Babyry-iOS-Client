//
//  PrivacyPolicyViewController.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/13.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PrivacyPolicyViewController.h"
#import "Navigation.h"
#import "UIColor+Hex.h"
#import "Logger.h"

@interface PrivacyPolicyViewController ()

@end

@implementation PrivacyPolicyViewController

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
    [Navigation setTitle:self.navigationItem withTitle:@"プライバシーポリシー" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
    _webView.delegate = self;
    _webView.scalesPageToFit = YES;
    _webView.backgroundColor = [UIColor_Hex colorWithHexString:@"CCCCCC" alpha:0];
    self.view.backgroundColor = [UIColor_Hex colorWithHexString:@"CCCCCC" alpha:1];
    
    // navigation controller
    CGRect rect = CGRectMake(0, 0, 130, 38);
    UIImageView *titleview = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"babyryTitleReverse"]];
    titleview.frame = rect;
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(176, 0, 130, 38)];
    [view addSubview:titleview];
    self.navigationItem.titleView = view;
    self.navigationController.navigationBar.barTintColor = [UIColor_Hex colorWithHexString:@"f4c510" alpha:1.0f];

    // loading image
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.labelText = @"";
    
    [self load];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)load
{
    PFQuery *query = [PFQuery queryWithClassName:@"Config"];
    [query whereKey:@"key" equalTo:@"privacyPolicy"];
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSString *filePath = @"";
        if (!objects || objects.count < 1) {
            // TODO 準備中です とか表示
        } else {
            PFObject *row = objects[0];
            PFFile *fileObject = row[@"file"];
            filePath = fileObject.url;
            [self loadWebView:filePath];
        }
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in load privacyPolicy : %@", error]];
        }
    }];
}

- (void)loadWebView:(NSString *)filePath
{
    if (!filePath || filePath.length < 1) {
        // TODO 準備中です とか表示
    } else {
        NSURL *url = [NSURL URLWithString:filePath];
        NSURLRequest *req = [NSURLRequest requestWithURL:url];
        [_webView loadRequest:req];
    }
}

// ページ読込完了時にインジケータを非表示にする
-(void)webViewDidFinishLoad:(UIWebView*)webView{
    _hud.hidden = YES;
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
