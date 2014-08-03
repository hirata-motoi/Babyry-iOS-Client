//
//  AWSS3Utils.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/03.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AWSS3Utils.h"

@implementation AWSS3Utils

+ (void) saveToS3InBackground:(NSString *)key imageData:(NSData *)imageData
{
    AWSS3PutObjectRequest *putRequest = [AWSS3PutObjectRequest new];
    putRequest.bucket = @"babyrydev-images";
    putRequest.key = key;
    putRequest.body = imageData;
    putRequest.contentLength = [NSNumber numberWithInt:[imageData length]];
    
    // AWS cognite
    AWSCognitoCredentialsProvider *credentialsProvider = [AWSCognitoCredentialsProvider
                                                          credentialsWithRegionType:AWSRegionUSEast1
                                                          accountId:@"424568627207"
                                                          identityPoolId:@"us-east-1:7c7b2ce0-0dee-4516-93a7-63f9a51f216c"
                                                          unauthRoleArn:@"arn:aws:iam::424568627207:role/babyry-cognito-role"
                                                          authRoleArn:nil];
    AWSServiceConfiguration *configuration = [AWSServiceConfiguration configurationWithRegion:AWSRegionAPNortheast1 credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:configuration];
    [[[awsS3 putObject:putRequest] continueWithBlock:^id(BFTask *task){
        if (task.error) {
            NSLog(@"S3 get error: %@", [task.error description]);
        } else {
            NSLog(@"saved to S3");
        }
        return nil;
    }] waitUntilFinished];
}

@end
