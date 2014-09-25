//
//  Account.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface Account : NSObject

+ (NSString *) checkEmailRegisterFields:(NSString *)email password:(NSString *)password passwordConfirm:(NSString *)passwordConfirm;
+ (void)checkDuplicateEmailWithBlock:(NSString *)email withBlock:(PFArrayResultBlock)block;
+ (NSString *)checkDuplicateEmail:(NSString *)email;
+ (BOOL)validateEmailWithString:(NSString*)email;
+ (BOOL)validatePincode:(NSString *)pincode;

@end
