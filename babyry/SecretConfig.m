//
//  SecretConfig.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/22.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "SecretConfig.h"

@implementation SecretConfig

static NSMutableDictionary *_config = nil;

+ (NSString *) getParseApplicationId
{
    return [self config][@"parseApplicationId"];
}

+ (NSString *) getParseClientKey
{
    return [self config][@"parseClientKey"];
}

+ (NSString *) getAWSAccountId
{
    return [self config][@"AWSAccountId"];
}

+ (NSString *) getAWSCognitoIdentityPoolId
{
    return [self config][@"AWSCognitoIdentityPoolId"];
}

+ (NSString *) getAWSCognitoUnauthRoleArn
{
    return [self config][@"AWSCognitoUnauthRoleArn"];
}

+ (NSMutableDictionary *)config
{
    if (_config == nil) {
        NSString *configName;
        if ([[app env] isEqualToString:@"prod"]) {
            configName = @"babyry-secret-config.plist";
        } else {
            configName = @"babyrydev-secret-config.plist";
        }

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
