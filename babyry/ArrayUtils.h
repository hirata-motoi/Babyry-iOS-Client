//
//  ArrayUtils.h
//  babyry
//
//  Created by hirata.motoi on 2014/08/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface ArrayUtils : NSObject

+ (NSMutableDictionary *)arrayToHash:(NSArray *)array withKeyColumn:(NSString *)keyColumn;

@end
