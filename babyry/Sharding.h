//
//  Sharding.h
//  babyry
//
//  Created by hirata.motoi on 2014/08/09.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface Sharding : NSObject

+ (NSInteger)shardIndexWithClassName: (NSString *)className;
+ (void)setupShardConf;

@end
