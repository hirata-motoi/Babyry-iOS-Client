//
//  TmpUser.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/13.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TmpUser : NSObject

+ (void) setTmpUserToCoreData:(NSString *)username password:(NSString *)password;
+ (void) removeTmpUser;
+ (void) removeTmpUserFromCoreData;
+ (void) loginTmpUserByCoreData;
+ (BOOL) checkRegistered;
+ (void) registerComplete;

@end
