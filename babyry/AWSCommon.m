//
//  AWSCommon.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/10/31.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AWSCommon.h"
#import "Config.h"

@implementation AWSCommon

+ (AWSServiceConfiguration *) getAWSServiceConfiguration:(NSString *)service
{
    NSInteger regionEnum;
    if ([service isEqualToString:@"S3"]) {
        regionEnum = AWSRegionAPNortheast1;
    } else if ([service isEqualToString:@"SES"]) {
        regionEnum = AWSRegionUSWest2;
    } else {
        return nil;
    }
    
    AWSCognitoCredentialsProvider *credentialsProvider = [AWSCognitoCredentialsProvider
                                                          credentialsWithRegionType:AWSRegionUSEast1
                                                          accountId:[Config secretConfig][@"AWSAccountId"]
                                                          identityPoolId:[Config secretConfig][@"AWSCognitoIdentityPoolId"]
                                                          unauthRoleArn:[Config secretConfig][@"AWSCognitoUnauthRoleArn"]
                                                          authRoleArn:nil];
    AWSServiceConfiguration *configuration = [AWSServiceConfiguration configurationWithRegion:regionEnum credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    return configuration;
}

@end
