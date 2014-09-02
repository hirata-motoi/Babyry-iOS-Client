//
//  FamilyApply.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

typedef void (^GetApplyingEmailBlock)(NSString *email);

@interface FamilyApply : NSObject

+ (PFObject *)getFamilyApply;
+ (NSString *)selfRole;
+ (void)deleteApply;
+ (void)getApplyingEmailWithBlock:(GetApplyingEmailBlock)block;

@end
