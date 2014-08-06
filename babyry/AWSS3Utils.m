//
//  AWSS3Utils.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/03.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AWSS3Utils.h"
#import "SecretConfig.h"

@implementation AWSS3Utils

+ (BFTask *) putObject:(NSString *)key imageData:(NSData *)imageData imageType:(NSString *)imageType
{
    // AWS cognite
    // これは適当に共通化した方が良さげ
    AWSCognitoCredentialsProvider *credentialsProvider = [AWSCognitoCredentialsProvider
                                                          credentialsWithRegionType:AWSRegionUSEast1
                                                          accountId:[SecretConfig getAWSAccountId]
                                                          identityPoolId:[SecretConfig getAWSCognitoIdentityPoolId]
                                                          unauthRoleArn:[SecretConfig getAWSCognitoUnauthRoleArn]
                                                          authRoleArn:nil];
    AWSServiceConfiguration *configuration = [AWSServiceConfiguration configurationWithRegion:AWSRegionAPNortheast1 credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
    putRequest.bucket = @"babyrydev-images";
    putRequest.key = key;
    putRequest.body = imageData;
    putRequest.contentLength = [NSNumber numberWithInt:[imageData length]];
    putRequest.contentType = imageType;
    
    AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
    return [awsS3 putObject:putRequest];
}

+ (BFTask *) getObject:(NSString *)key
{
    AWSCognitoCredentialsProvider *credentialsProvider = [AWSCognitoCredentialsProvider
                                                          credentialsWithRegionType:AWSRegionUSEast1
                                                          accountId:[SecretConfig getAWSAccountId]
                                                          identityPoolId:[SecretConfig getAWSCognitoIdentityPoolId]
                                                          unauthRoleArn:[SecretConfig getAWSCognitoUnauthRoleArn]
                                                          authRoleArn:nil];
    AWSServiceConfiguration *configuration = [AWSServiceConfiguration configurationWithRegion:AWSRegionAPNortheast1 credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    AWSS3GetObjectRequest *getRequest = [AWSS3GetObjectRequest new];
    getRequest.bucket = @"babyrydev-images";
    getRequest.key = key;
    
    AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
    
    return [awsS3 getObject:getRequest];
}

@end
