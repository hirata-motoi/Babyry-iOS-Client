//
//  NSObject+Retry.m
//  babyry
//
//  Created by 平田基 on 2014/07/03.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "NSObject+Retry.h"

@implementation NSObject (Retry)

- (void)for:(NSInteger)times timesTryBlock:(void(^)(void(^)(NSError*)))block;
{
    [self for:times timesTryBlock:block callback:^(NSError* error) {} ];
}

- (void)for:(NSInteger)times timesTryBlock:(void(^)(void(^)(NSError*)))block callback:(void(^)(NSError* error))callback;
{
    block(^(NSError* error)
    {
        if (error != nil)
        {
            if (times > 1) {
                [self for:times - 1 timesTryBlock:block callback:callback];
            } else {
                callback(error);
            }
            return;
        }
        
        callback(nil);
    });
}

@end
