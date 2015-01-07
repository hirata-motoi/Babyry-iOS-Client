//
//  ChildIconManager.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/06.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

typedef void (^SaveToAWSBlock)();
               
@interface ChildIconManager : NSObject

+ (void)updateChildIcon:(NSData *)imageData withChildObjectId:(NSString *)childObjectId;
+ (void)syncChildIconsInBackground;

@end
