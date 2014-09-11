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
    [query whereKey:@"key" equalTo:@"minimumVersion"];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (object) {
            NSArray *minimumVersion = [object[@"value"] componentsSeparatedByString:@"."];
            int minimumMajor = [minimumVersion[0] intValue];
            int minimumMinor = [minimumVersion[1] intValue];
            int minimumRevision = [minimumVersion[2] intValue];
            
            NSArray *currentVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] componentsSeparatedByString:@"."];
            int currentMajor = [currentVersion[0] intValue];
            int currentMinor = [currentVersion[1] intValue];
            int currentRevision = [currentVersion[2] intValue];
            
            if (currentMajor > minimumMajor) {
                return;
            } else if (currentMajor < minimumMajor) {
                [self showUpdateAlert];
                return;
            }
            
            if (currentMinor > minimumMinor) {
                return;
            } else if (currentMinor < minimumMinor) {
                [self showUpdateAlert];
                return;
            }
            
            if (currentRevision < minimumRevision) {
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
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[Config config][@"AppStoreURL"]]];
        }
            break;
    }
}

@end
