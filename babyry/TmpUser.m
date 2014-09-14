//
//  TmpUser.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/13.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TmpUser.h"
#import "TmpUserData.h"
#import "Config.h"
#import "DateUtils.h"
#import <Parse/Parse.h>
#import "Logger.h"

@implementation TmpUser

+ (void) setTmpUserToCoreData:(NSString *)username password:(NSString *)password
{
    NSString *TmpUserDataKeyName = [Config config][@"TmpUserDataKeyName"];
    TmpUserData *tud = [TmpUserData MR_findFirstByAttribute:@"name" withValue:TmpUserDataKeyName];
    
    if (tud) {
        // 新規ログイン完了した後に呼ぶので、もし古いログイン情報があったら上書きをしないと駄目
        tud.username = username;
        tud.password = password;
        tud.isRegistered = [NSNumber numberWithBool:YES];
        tud.createdAt = [DateUtils setSystemTimezone:[NSDate date]];
        tud.updatedAt = [DateUtils setSystemTimezone:[NSDate date]];
    } else {
        TmpUserData *newTud = [TmpUserData MR_createEntity];
        newTud.name = TmpUserDataKeyName;
        newTud.username = username;
        newTud.password = password;
        tud.isRegistered = [NSNumber numberWithBool:YES];
        newTud.createdAt = [DateUtils setSystemTimezone:[NSDate date]];
        newTud.updatedAt = [DateUtils setSystemTimezone:[NSDate date]];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

+ (void) loginTmpUserByCoreData
{
    NSString *TmpUserDataKeyName = [Config config][@"TmpUserDataKeyName"];
    TmpUserData *tud = [TmpUserData MR_findFirstByAttribute:@"name" withValue:TmpUserDataKeyName];
    if (tud){
        // 既に本会員登録済みなら飛ばす
        if (tud.isRegistered) {
            return;
        }
        PFUser *user = [PFUser logInWithUsername:tud.username password:tud.password];
        if (user) {
            [Logger writeOneShot:@"info" message:[NSString stringWithFormat:@"Login as %@", tud.username]];
        }
    }
}

@end
