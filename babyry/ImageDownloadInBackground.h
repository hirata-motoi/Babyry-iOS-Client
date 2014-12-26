//
//  ImageDownloadInBackground.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/12/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageDownloadInBackground : NSObject

- (void) downloadByPushInBackground:(NSNumber *)date childObjectId:(NSString *)childObjectId;

@end
