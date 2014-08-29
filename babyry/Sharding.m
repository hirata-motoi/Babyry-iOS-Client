//
//  Sharding.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/09.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Sharding.h"
#import "Logger.h"

@implementation Sharding

static NSMutableDictionary *shardConf = nil;

+ (NSInteger)shardIndexWithClassName:(NSString *)className
{
    NSArray *settings = shardConf[className];
    if (!settings || settings.count < 1) {
        return 1;
    }
    
    NSInteger rateSum = 0;
    for (PFObject *row in settings) {
        rateSum += [row[@"rate"] integerValue];
    }
  
    NSInteger shardIndex = [settings[ settings.count - 1 ][@"shardIndex"] integerValue]; // 初期値は最後のindex
    NSInteger sum = 0;
    NSInteger rand = arc4random() % rateSum;
    for (PFObject *row in settings) {
        sum += [row[@"rate"] integerValue];
        
        if (sum >= rand) {
            shardIndex = [row[@"shardIndex"] integerValue];
            break;
        }
    }
    return shardIndex;
}

+ (void)setupShardConf
{
    shardConf = [[NSMutableDictionary alloc]init];
    PFQuery *query = [PFQuery queryWithClassName:@"ShardConf"];
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *object in objects) {
                NSString *className = object[@"targetClassName"];
                NSMutableArray *rows;
                if (shardConf[className]) {
                    rows = shardConf[className];
                } else {
                    rows = [[NSMutableArray alloc]init];
                    shardConf[className] = rows;
                }
                
                [rows addObject:object];
            }
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in setupShardConf : %@", error]];
        }
    }];
}

@end
