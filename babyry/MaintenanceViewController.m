//
//  MaintenanceViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "MaintenanceViewController.h"

@interface MaintenanceViewController ()

@end

@implementation MaintenanceViewController

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
    
    _maintenanceViewTextView.text = @"ただ今メンテナンス中です。\nご迷惑をおかけしますが、もうしばらくお待ちください。";
    
    _maintenanceImageView.image = [UIImage imageNamed:@"CryingBaby"];
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

- (IBAction)maintenanceReloadButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
