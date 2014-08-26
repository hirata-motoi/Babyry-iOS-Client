//
//  Config.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Config.h"
#import "MaintenanceViewController.h"

@implementation Config

static NSMutableDictionary *_config = nil;

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

+ (NSString *)getBucketName
{
    return [self config][@"aws-bucket-name"];
}

+ (NSString *)getAppVertion
{
    return [self config][@"app-version"];
}

+ (NSString *)getInquiryEmail
{
    return [self config][@"inquiry-email"];
}

+ (NSMutableDictionary *)config
{
    if (_config == nil) {
        NSString *configName;
        #ifdef DEBUG
            configName = @"babyrydev-config.plist";
        #else
            configName = @"babyry-config.plist";
        #endif

        _config = [[NSMutableDictionary alloc]init];
        NSString *homeDir = NSHomeDirectory();
        NSString *appDir = [NSString stringWithFormat:@"%@/%@", homeDir, @"babyry.app"];
        NSString *filePath = [appDir stringByAppendingPathComponent:configName];
    
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:filePath]) {
            _config = [NSDictionary dictionaryWithContentsOfFile:filePath];
        }
    }
    
    return _config;
}

@end
