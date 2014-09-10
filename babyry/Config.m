//
//  Config.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Config.h"
#import "MaintenanceViewController.h"
#import "Logger.h"

@implementation Config

static NSMutableDictionary *_config = nil;
static NSMutableDictionary *_secretConfig = nil;

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

+ (NSMutableDictionary *)config
{
    if (_config == nil) {
        NSString *configName =
            ([[app env] isEqualToString:@"prod"]) ? @"babyry-config.plist"    :
            ([[app env] isEqualToString:@"dev"])  ? @"babyrydev-config.plist" : nil;
        if (configName == nil) {
            NSString *exceptionString = [NSString stringWithFormat:@"invalid configName due to unknown env:%@", [app env]];
            [Logger writeOneShot:@"crit" message:exceptionString];
            @throw exceptionString;
        }
        _config = [self load:configName];
    }
    
    return _config;
}

+ (NSMutableDictionary *)secretConfig
{
    if (_secretConfig == nil) {
        NSString *configName =
            ([[app env] isEqualToString:@"prod"]) ? @"babyry-secret-config.plist"    :
            ([[app env] isEqualToString:@"dev"])  ? @"babyrydev-secret-config.plist" : nil;
        if (configName == nil) {
            NSString *exceptionString = [NSString stringWithFormat:@"invalid secretConfigName due to unknown env:%@", [app env]];
            [Logger writeOneShot:@"crit" message:exceptionString];
            @throw exceptionString;
        }
        _secretConfig = [self load:configName];
    }
    
    return _secretConfig;
}

+ (NSMutableDictionary *)load:(NSString *)configName
{
    NSMutableDictionary *config;
    NSString *homeDir = NSHomeDirectory();
    NSString *appDir = [NSString stringWithFormat:@"%@/%@", homeDir, @"babyry.app"];
    NSString *filePath = [appDir stringByAppendingPathComponent:configName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        config = [NSDictionary dictionaryWithContentsOfFile:filePath];
    }
    
    return config;
}

@end
