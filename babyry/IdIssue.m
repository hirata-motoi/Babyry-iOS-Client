//
//  IdIssue.m
//  babyry
//
//  Created by 平田基 on 2014/07/03.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "IdIssue.h"
#import "NSObject+Retry.h"

@implementation IdIssue
@synthesize issuedId;

- (NSString*)issue: (NSString*)type
{
    // 初期化
    issuedId = NULL;
    // かっちょわるいがまあ今はいっか
    if ([type isEqualToString:@"family"]) {
        return [self issueFamilyId];
    } else if ([type isEqualToString:@"user"]) {
        return [self issueUserId];
    }
    return @""; // TODO 取得できなかった場合は「エラーが発生しました。少し時間をおいて再度お試しください」を表示
}

// 最初の文字はfで始まる
// A-Za-z0-9の5文字
- (NSString *)issueFamilyId
{
    [self for:3 timesTryBlock:^(void(^callback)(NSError* error))
    {
        if (issuedId) {
            return;
        }
            
        NSString *id = [NSString stringWithFormat:@"%@%@", @"f", [self randomStringWithLength:5]];
        PFQuery *query = [PFQuery queryWithClassName:@"_User"];
        [query whereKey:@"familyId" equalTo:id];
        NSArray *objects = [query findObjects];
        
        if (objects.count > 0) {
            // 重複しているIDがあったので再発行
            NSString *errorDomain = @"com.inazumatv.APP_NAME";
            NSInteger errorCode = 12345;
            NSDictionary *errorUserInfo = @{NSLocalizedDescriptionKey: @"Error Description",
                                            NSLocalizedRecoverySuggestionErrorKey: @"Error Suggestion"};
            callback([[NSError alloc] initWithDomain:errorDomain code:errorCode userInfo:errorUserInfo]);
            return;
        } else {
            issuedId = id;
            callback(nil);
        }
    }
    callback:^(NSError *error){
        if (error)
            NSLog(@"Doh! Tried 3 times but failed.");
        else
            NSLog(@"Done.");
    }];
    return issuedId;
}

// 最初の文字はuで始まる
- (NSString *)issueUserId
{
    NSString *str = [self randomStringWithLength:5];
    return [NSString stringWithFormat:@"%@%@", @"u", str];
}

- (NSString *)randomStringWithLength: (int)length
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    
    for (int i = 0; i < length; i++) {
        [randomString appendFormat:@"%C", [letters characterAtIndex:arc4random() % [letters length]]];
    }
    
    return randomString;
}

@end
