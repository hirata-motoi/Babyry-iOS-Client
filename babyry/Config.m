//
//  Config.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Config.h"

@implementation Config

+ (NSString *) getValue:key
{
    PFQuery *maintenanceQuery = [PFQuery queryWithClassName:@"Config"];
    maintenanceQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
    NSArray *objects = [maintenanceQuery findObjects];
    for (PFObject *object in objects) {
        if ([key isEqualToString:object[@"key"]]) {
            return object[@"value"];
        }
    }
    return @"";
}

@end
