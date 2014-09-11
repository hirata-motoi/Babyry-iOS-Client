//
//  CheckAppVersion.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/12.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "CheckAppVersion.h"
#import "Config.h"

@implementation CheckAppVersion

+ (void)checkForceUpdate
{
    PFQuery *query = [PFQuery queryWithClassName:@"Config"];
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    [query whereKey:@"key" equalTo:@"versionLimit"];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (object) {
            NSArray *versionLimit = [object[@"value"] componentsSeparatedByString:@"."];
            int majorLimit = [versionLimit[0] intValue];
            int minorLimit = [versionLimit[1] intValue];
            int revisionLimit = [versionLimit[2] intValue];
            
            NSArray *versionCurrent = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] componentsSeparatedByString:@"."];
            int majorCurrent = [versionCurrent[0] intValue];
            int minorCurrent = [versionCurrent[1] intValue];
            int revisionCurrent = [versionCurrent[2] intValue];
            
            if (majorCurrent > majorLimit) {
                return;
            } else if (majorCurrent < majorLimit) {
                [self showUpdateAlert];
                return;
            }
            
            if (minorCurrent > minorLimit) {
                return;
            } else if (minorCurrent < minorLimit) {
                [self showUpdateAlert];
                return;
            }
            
            if (revisionCurrent < revisionLimit) {
                [self showUpdateAlert];
            }
        }
    }];
}

+ (void) showUpdateAlert;
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"新しいバージョンがあります"
                                                    message:@"App Storeに移動して最新のバージョンをインストールしてください"
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil
                          ];
    [alert show];
}

+ (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/jp/app/babyry/id910129660?mt=8"]];
        }
            break;
    }
}

@end
