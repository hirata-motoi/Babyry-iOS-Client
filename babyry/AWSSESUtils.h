//
//  AWSSESUtils.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/10/31.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSiOSSDKv2/AWSCore.h>
#import <AWSiOSSDKv2/SES.h>

@interface AWSSESUtils : NSObject

+ (void) sendVerifyEmail:(AWSServiceConfiguration *)configuration to:(NSString *)toAddress token:(NSString *)token;
+ (void) resendVerifyEmail:(AWSServiceConfiguration *)configuration email:(NSString *)email;

@end
