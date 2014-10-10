//
//  ChildProperties.h
//  babyry
//
//  Created by hirata.motoi on 2014/10/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

typedef void (^UpdateChildPropertiesAsyncBlock)();

@interface ChildProperties : NSObject

+ (void)syncChildProperties;
+ (void)asyncChildProperties;
+ (void)asyncChildPropertiesWithBlock:(UpdateChildPropertiesAsyncBlock)block;
+ (NSMutableDictionary *)getChildProperty:(NSString *)childObjectId;
+ (NSMutableArray *)getChildProperties;
+ (void)updateChildPropertyWithObjectId:(NSString *)childObjectId withParams:(NSMutableDictionary *)params;

@end
