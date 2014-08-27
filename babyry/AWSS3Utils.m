//
//  AWSS3Utils.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/03.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AWSS3Utils.h"
#import "Config.h"

@implementation AWSS3Utils

+ (AWSServiceConfiguration *) getAWSServiceConfiguration
{
    AWSCognitoCredentialsProvider *credentialsProvider = [AWSCognitoCredentialsProvider
                                                          credentialsWithRegionType:AWSRegionUSEast1
                                                          accountId:[Config secretConfig][@"AWSAccountId"]
                                                          identityPoolId:[Config secretConfig][@"AWSCognitoIdentityPoolId"]
                                                          unauthRoleArn:[Config secretConfig][@"AWSCognitoUnauthRoleArn"]
                                                          authRoleArn:nil];
    AWSServiceConfiguration *configuration = [AWSServiceConfiguration configurationWithRegion:AWSRegionAPNortheast1 credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    return configuration;
}

// awsS3のメソッド自体がBFTaskでの別スレッドの処理なのでさらにBFTaskで書こうとなんかおかしい気がしたので、使うのちょっとやめる
//+ (BFTask *) putObject:(NSString *)key imageData:(NSData *)imageData imageType:(NSString *)imageType configuration:(AWSServiceConfiguration *)configuration
//{
//    AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
//    putRequest.bucket = @"babyrydev-images";
//    putRequest.key = key;
//    putRequest.body = imageData;
//    putRequest.contentLength = [NSNumber numberWithLong:[imageData length]];
//    putRequest.contentType = imageType;
//    putRequest.cacheControl = @"no-cache";
//    
//    AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
//    return [awsS3 putObject:putRequest];
//}
//
//// 単発でgetする時にはこれを使う
//// 1月分とかとるのであれば再起的に呼び出す必要があるのでこれは使わない
//+ (BFTask *) getObject:(NSString *)key configuration:(AWSServiceConfiguration *)configuration
//{
//    AWSS3GetObjectRequest *getRequest = [AWSS3GetObjectRequest new];
//    getRequest.bucket = @"babyrydev-images";
//    getRequest.key = key;
//    // no-cacheにしないと反映が遅い
//    getRequest.responseCacheControl = @"no-cache";
//    
//    AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
//    
//    return [awsS3 getObject:getRequest];
//}

@end
