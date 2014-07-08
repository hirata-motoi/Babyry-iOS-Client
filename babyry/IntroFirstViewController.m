//
//  IntroFirstViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "IntroFirstViewController.h"

@interface IntroFirstViewController ()

@end

@implementation IntroFirstViewController

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

    _introFirstViewTopLabel.text = @"\n\nBabyryへようこそ\n\nBabyryは赤ちゃんの毎日のベストショットをパートナーと協力して残していくサービスです。";
    _introFirstViewTopLabel.textAlignment = NSTextAlignmentCenter;
    _introFirstViewTopLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:20];
    _introFirstViewTopLabel.textColor = [UIColor whiteColor];
    
    // Add Listener
    _inviteByLineLabel.tag = 1;
    UITapGestureRecognizer *singleTapGestureRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer1.numberOfTapsRequired = 1;
    [_inviteByLineLabel addGestureRecognizer:singleTapGestureRecognizer1];
    
    
    _inviteByMailLabel.tag = 2;
    UITapGestureRecognizer *singleTapGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer2.numberOfTapsRequired = 1;
    [_inviteByLineLabel addGestureRecognizer:singleTapGestureRecognizer2];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

-(void)handleSingleTap:(id) sender
{
    int tag = [[sender view] tag];
    NSString *plainTitle = @"Babyryへ招待";
    NSString *escapedUrlTitle = [plainTitle stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *plainText = @"Babyryに招待します。\n以下のURLからアプリをインストール後、ユーザーID XXXXX を入力してください。\nhttps://app.store/id=3333";
    NSString *escapedUrlText = [plainText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"tapped %d", [[sender view] tag]);
    if (tag == 1) {
        NSLog(@"%@", escapedUrlText);
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"line://msg/text/%@", escapedUrlText]]];
    } else if (tag == 2) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:?Subject=%@&body=%@", escapedUrlTitle, escapedUrlText]]];
    }
}

@end
