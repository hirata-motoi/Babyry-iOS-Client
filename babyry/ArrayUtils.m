//
//  ArrayUtils.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ArrayUtils.h"

@implementation ArrayUtils


+ (NSMutableDictionary *)arrayToHash:(NSArray *)array withKeyColumn:(NSString *)keyColumn
{
    NSMutableDictionary *hash = [[NSMutableDictionary alloc]init];
    for (PFObject *elem in array) {
        NSString *key = elem[keyColumn];
        if (![hash objectForKey:key]) {
            [hash setObject:[[NSMutableArray alloc]init] forKey:key];
        }
        [[hash objectForKey:key] addObject:elem];
    }
    return hash;
}

@end
