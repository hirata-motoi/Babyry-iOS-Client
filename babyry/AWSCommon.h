//
//  AWSCommon.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/10/31.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSiOSSDKv2/AWSCore.h>
#import <AWSiOSSDKv2/S3.h>
#import <AWSiOSSDKv2/SES.h>

@interface AWSCommon : NSObject

+ (AWSServiceConfiguration *) getAWSServiceConfiguration:(NSString *)region;

@end
