//
//  Account.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Account.h"
#import "IdIssue.h"
#import "Logger.h"
#import "AWSCommon.h"
#import "AWSSESUtils.h"

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
    }
    
    return errorMessage;
}

+ (NSString *)checkDuplicateEmail:(NSString *)email
{
    NSString *errorMessage = @"";
    
    PFQuery *emailQuery = [PFQuery queryWithClassName:@"_User"];
    [emailQuery whereKey:@"emailCommon" equalTo:email];
    PFObject *object = [emailQuery getFirstObject];
    if (object) {
        errorMessage = @"登録済みのメールアドレスです";
    }
    
    return errorMessage;
}

+ (void)checkDuplicateEmailWithBlock:(NSString *)email withBlock:(PFArrayResultBlock)block
{
    PFQuery *emailQuery = [PFQuery queryWithClassName:@"_User"];
    [emailQuery whereKey:@"emailCommon" equalTo:email];
    [emailQuery findObjectsInBackgroundWithBlock:block];
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

+ (void)sendVerifyEmail:(NSString *)email
{
    // Email認証用のレコード
    // 既にレコードあれば飛ばす
    PFQuery *emailQuery = [PFQuery queryWithClassName:@"EmailVerify"];
    [emailQuery whereKey:@"email" equalTo:email];
    [emailQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if ([objects count] == 0) {
            PFObject *emailObject = [PFObject objectWithClassName:@"EmailVerify"];
            emailObject[@"email"] = email;
            IdIssue *idIssue = [[IdIssue alloc] init];
            emailObject[@"token"] = [idIssue randomStringWithLength:32];
            emailObject[@"isVerified"] = [NSNumber numberWithBool:NO];
            [emailObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                if (error) {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in create token recorde : %@", error]];
                    return;
                }
                if (succeeded && [[app env] isEqualToString:@"prod"]) {
                    [AWSSESUtils sendEmailBySES:[AWSCommon getAWSServiceConfiguration:@"SES"] to:emailObject[@"email"] token:emailObject[@"token"]];
                }
            }];
        }
    }];
}
    
@end
