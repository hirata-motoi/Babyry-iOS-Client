//
//  AWSS3Utils.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/03.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSiOSSDKv2/AWSCore.h>
#import <AWSiOSSDKv2/S3.h>

@interface AWSS3Utils : NSObject

+ (void) saveToS3InBackground:(NSString *)key imageData:(NSData *)imageData;

@end
