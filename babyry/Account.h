//
//  Account.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Account : NSObject

+ (NSString *) checkEmailRegisterFields:(NSString *)email password:(NSString *)password passwordConfirm:(NSString *)passwordConfirm;
+ (BOOL)validateEmailWithString:(NSString*)email;
+ (BOOL)validatePincode:(NSString *)pincode;

@end
