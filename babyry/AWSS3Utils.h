//
//  AWSS3Utils.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/12/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSiOSSDKv2/AWSCore.h>
#import <AWSiOSSDKv2/S3.h>

typedef void (^makeCacheFromS3Block)();
typedef void (^SimpleDownloadBlock)(NSMutableDictionary *params);

@interface AWSS3Utils : NSObject

- (void)makeCacheFromS3:(NSMutableArray *)downloadQueue configuration:(AWSServiceConfiguration *)configuration withBlock:(makeCacheFromS3Block)block;
+ (void)singleDownloadWithKey:(NSString *)key withBlock:(SimpleDownloadBlock)block;
@end
