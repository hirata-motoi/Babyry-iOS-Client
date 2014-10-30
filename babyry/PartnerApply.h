//
//  PartnerApply.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/16.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CheckPartnerApplyBlock)(BOOL existsApply);
typedef void (^RemovePartnerApplyBlock)();

@interface PartnerApply : NSObject

+ (BOOL) linkComplete;
+ (void) setLinkComplete;
+ (void) unsetLinkComplete;
+ (NSNumber *) issuePinCode;
+ (void) registerApplyList;
+ (void) removePartnerInvitedFromCoreData;
+ (void) removePartnerInviteFromCoreData;
+ (void)syncPartnerApply;
+ (void) removeApplyListWithBlock:(RemovePartnerApplyBlock)block;
+ (void)checkPartnerApplyListWithBlock:(CheckPartnerApplyBlock)block;

@end
