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
#import "Account.h"

@implementation TmpUser

+ (void) setTmpUserToCoreData:(NSString *)username password:(NSString *)password
{
    NSString *TmpUserDataKeyName = [Config config][@"TmpUserDataKeyName"];
    TmpUserData *tud = [TmpUserData MR_findFirstByAttribute:@"name" withValue:TmpUserDataKeyName];
    
    if (tud) {
        // 新規ログイン完了した後に呼ぶので、もし古いログイン情報があったら上書きをしないと駄目
        tud.username = username;
        tud.password = password;
        tud.isRegistered = NO;
        tud.createdAt = [DateUtils setSystemTimezone:[NSDate date]];
        tud.updatedAt = [DateUtils setSystemTimezone:[NSDate date]];
    } else {
        TmpUserData *newTud = [TmpUserData MR_createEntity];
        newTud.name = TmpUserDataKeyName;
        newTud.username = username;
        newTud.password = password;
        tud.isRegistered = NO;
        newTud.createdAt = [DateUtils setSystemTimezone:[NSDate date]];
        newTud.updatedAt = [DateUtils setSystemTimezone:[NSDate date]];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

+ (void)removeTmpUser
{
    [self removeTmpUserFromCoreData];

    PFUser *currentUser = [PFUser currentUser];
    [currentUser deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [Logger writeOneShot:@"warn" message:[NSString stringWithFormat:@"Failed to delete tmp user userId:%@ error:%@", currentUser[@"userId"], error]];
        }
    }];
}

+ (void)removeTmpUserFromCoreData
{
    NSString *TmpUserDataKeyName = [Config config][@"TmpUserDataKeyName"];
    TmpUserData *tud = [TmpUserData MR_findFirstByAttribute:@"name" withValue:TmpUserDataKeyName];
    
    if (!tud) {
        return;
    }
    
    [tud MR_deleteEntity];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

+ (BOOL) loginTmpUserByCoreData
{
    NSString *TmpUserDataKeyName = [Config config][@"TmpUserDataKeyName"];
    TmpUserData *tud = [TmpUserData MR_findFirstByAttribute:@"name" withValue:TmpUserDataKeyName];
    if (tud){
        // 既に本会員登録済みなら飛ばす
        if (tud.isRegistered) {
            return NO;
        }
        // username passowrdが無くても飛ばす
        if (!tud.username || !tud.password){
            return NO;
        }
        PFUser *user = [PFUser logInWithUsername:tud.username password:tud.password];
        if (user) {
            [Logger writeOneShot:@"info" message:[NSString stringWithFormat:@"Login as %@", tud.username]];
			return YES;
        }
    }
	return NO;
}

+ (BOOL) checkRegistered
{
    NSString *TmpUserDataKeyName = [Config config][@"TmpUserDataKeyName"];
    TmpUserData *tud = [TmpUserData MR_findFirstByAttribute:@"name" withValue:TmpUserDataKeyName];
    if (tud){
        if (tud.isRegistered) {
            return YES;
        }
    }
    
    // 1.0.1時代のユーザー用
    // 1.0.1はTmpUserがいなかったので、1.0.1からアップデートした人は本登録済みでもCoreDataにレコードが無い
    // そのため、userレコードを確認する
    // キャッシュされているPFUserを使うので、あくまでも救済用。
    if ([Account validateEmailWithString:[PFUser currentUser][@"emailCommon"]]) {
        return YES;
    }
    
    return NO;
}

+ (void) registerComplete
{
    NSString *TmpUserDataKeyName = [Config config][@"TmpUserDataKeyName"];
    TmpUserData *tud = [TmpUserData MR_findFirstByAttribute:@"name" withValue:TmpUserDataKeyName];
    if (tud){
        tud.isRegistered = YES;
        tud.updatedAt = [DateUtils setSystemTimezone:[NSDate date]];
        tud.username = nil;
        tud.password = nil;
    } else {
        TmpUserData *newTud = [TmpUserData MR_createEntity];
        newTud.name = TmpUserDataKeyName;
        newTud.isRegistered = YES;
        newTud.updatedAt = [DateUtils setSystemTimezone:[NSDate date]];
        newTud.username = nil;
        newTud.password = nil;
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

@end
