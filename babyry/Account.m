//
//  Account.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Account.h"
#import <Parse/Parse.h>

@implementation Account

+ (NSString *) checkEmailRegisterFields:(NSString *)email password:(NSString *)password passwordConfirm:(NSString *)passwordConfirm
{
    NSString *errorMessage = @"";
    
    if (!email || [email isEqualToString:@""]
        || !password|| [password isEqualToString:@""]
        || !passwordConfirm || [passwordConfirm isEqualToString:@""]) {
        errorMessage = @"入力が完了していない項目があります";
    } else if (![self validateEmailWithString:email]) {
        errorMessage = @"メールアドレスを正しく入力してください";
    } else if(![password canBeConvertedToEncoding:NSASCIIStringEncoding]) {
        errorMessage = @"パスワードに全角文字は使用できません";
    } else if ([password length] < 8) {
        errorMessage = @"パスワードは8文字以上を設定してください";
    } else if (![password isEqualToString:passwordConfirm]){
        errorMessage = @"確認用パスワードが一致しません";
    } else {
        PFQuery *emailQuery = [PFQuery queryWithClassName:@"_User"];
        [emailQuery whereKey:@"emailCommon" equalTo:email];
        PFObject *object = [emailQuery getFirstObject];
        if(object) {
            errorMessage = @"既に登録済みのメールアドレスです";
        }
    }
    
    return errorMessage;
}


+ (BOOL)validateEmailWithString:(NSString*)email
{
    NSString *emailRegex = @"[\\S]+@[A-Za-z0-9.-]+\\.[A-Za-z]{1,10}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}

+ (BOOL)validatePincode:(NSString *)pincode
{
    if ([pincode length] != 6) {
        return NO;
    }
    
    NSCharacterSet *digitCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    
    NSScanner *aScanner = [NSScanner localizedScannerWithString:pincode];
    [aScanner setCharactersToBeSkipped:nil];
    
    [aScanner scanCharactersFromSet:digitCharSet intoString:NULL];
    return [aScanner isAtEnd];
}

@end
