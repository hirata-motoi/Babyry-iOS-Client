//
//  PushNotification.h
//  babyry
//
//  Created by 平田基 on 2014/07/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface PushNotification : NSObject

+ (void)sendInBackground:(NSString *)event withOptions:(NSDictionary *)options;

@end
