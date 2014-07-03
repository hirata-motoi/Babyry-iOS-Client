//
//  NSObject+Retry.h
//  babyry
//
//  Created by 平田基 on 2014/07/03.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Retry)

- (void)for:(NSInteger)times timesTryBlock:(void(^)(void(^)(NSError*)))block;
- (void)for:(NSInteger)times timesTryBlock:(void(^)(void(^)(NSError*)))block callback:(void(^)(NSError* error))callback;

@end
