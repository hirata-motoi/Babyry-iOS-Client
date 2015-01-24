//
//  ImageDownloadInBackground.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/12/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CompletionHandlerType)();

@interface ImageDownloadInBackground : NSObject <NSURLSessionDownloadDelegate>

@property NSMutableArray *completionHandlerArray;

- (void) downloadByPushInBackground:(NSDictionary *)userInfo;

@end
