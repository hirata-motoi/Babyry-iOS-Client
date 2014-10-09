//
//  ParseUtils.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/19.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ParseUtils.h"

@implementation ParseUtils

+ (NSMutableDictionary *)pfObjectToDic:(PFObject *)object
{
    NSMutableDictionary *mutDic = [[NSMutableDictionary alloc] init];
    for (NSString *key in [object allKeys]) {
        [mutDic setObject:[object objectForKey:key] forKey:key];
    }
    [mutDic setObject:object.objectId forKey:@"objectId"];
    
    return [[NSMutableDictionary alloc] initWithDictionary:mutDic];
}

@end
