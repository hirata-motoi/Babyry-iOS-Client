//
//  FamilyRole.m
//  babyry
//
//  Created by 平田基 on 2014/07/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "FamilyRole.h"
#import "PartnerApply.h"
#import "Logger.h"

@implementation FamilyRole

+ (PFObject *)getFamilyRole:(NSString *)cacheType
{
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyRole"];
    if ([cacheType isEqualToString:@"noCache"]) {
        query.cachePolicy = kPFCachePolicyNetworkOnly;
    } else if ([cacheType isEqualToString:@"useCache"]) {
        query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    } else if ([cacheType isEqualToString:@"NetworkFirst"]) {
        query.cachePolicy = kPFCachePolicyNetworkElseCache;
    } else if ([cacheType isEqualToString:@"cachekOnly"]) {
        query.cachePolicy = kPFCachePolicyCacheOnly;
    } else {
        query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    }
    [query whereKey:@"familyId" equalTo:[PFUser currentUser][@"familyId"]];
    PFObject *object = [query getFirstObject];
    return object;
}

+ (NSString *)selfRole:(NSString *)cacheType
{
    PFObject *object = [self getFamilyRole:cacheType];
    if (object) {
        return ([object[@"uploader"] isEqualToString:[PFUser currentUser][@"userId"]]) ? @"uploader" : @"chooser";
    } else {
        return nil;
    }
}

+ (void)updateCache
{
    PFUser *user = [PFUser currentUser];
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyRole"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    [query whereKey:@"familyId" equalTo:user[@"familyId"]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (object) {
            // すべての項目が埋まっているのであれば、CoreDataのひも付け完了フラグをTRUEに更新する
            if (object[@"uploader"] && ![object[@"uploader"] isEqualToString:@""] && object[@"chooser"] && ![object[@"chooser"] isEqualToString:@""]) {
                [PartnerApply setLinkComplete];
            } else {
                if ([PartnerApply linkComplete]) {
                    // すべての項目が埋まっていないのに、CoreDataのひも付け完了フラグがTRUEの場合、ひも付けが解除されたと見なせるので完了フラグを落とす
                    [PartnerApply unsetLinkComplete];
                    if (![object[@"uploader"] isEqualToString:user[@"userId"]] && ![object[@"chooser"] isEqualToString:user[@"userId"]]) {
                        // uploaderにもchooserにも自分のidが入っていなければ、Familyひも付けから削除されているので、自分のレコードからFamilyIdを落とす
                        user[@"familyId"] = @"";
                        [user saveInBackground];
                    }
                }
            }

        }
    }];
}

+ (void)createFamilyRole:(NSMutableDictionary *)data
{
    PFObject *object = [PFObject objectWithClassName:@"FamilyRole"];
    object[@"familyId"] = data[@"familyId"];
    object[@"uploader"] = data[@"uploader"];
    object[@"chooser"]  = data[@"chooser"];
    [object save];
}

+ (void)createFamilyRoleWithBlock:(NSMutableDictionary *)data withBlock:(PFBooleanResultBlock)block
{
    PFObject *object = [PFObject objectWithClassName:@"FamilyRole"];
    object[@"familyId"] = data[@"familyId"];
    object[@"uploader"] = data[@"uploader"];
    object[@"chooser"]  = data[@"chooser"];
    [object saveInBackgroundWithBlock:block];
}

+ (void)fetchFamilyRole:(NSString *)familyId withBlock:(PFArrayResultBlock)block
{
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyRole"];
    [query whereKey:@"familyId" equalTo:familyId];
    [query findObjectsInBackgroundWithBlock:block];
}

+ (void)switchRole:(NSString *)role
{
    PFObject *familyRole = [FamilyRole getFamilyRole:@"useCache"];
    NSString *uploaderUserId = familyRole[@"uploader"];
    NSString *chooserUserId  = familyRole[@"chooser"];
    NSString *partnerUserId  = ([uploaderUserId isEqualToString:[PFUser currentUser][@"userId"]]) ? chooserUserId : uploaderUserId;

    if ([role isEqualToString:@"uploader"]) {
        familyRole[@"uploader"] = [PFUser currentUser][@"userId"];
        familyRole[@"chooser"]  = partnerUserId;
    } else {
        familyRole[@"uploader"] = partnerUserId;
        familyRole[@"chooser"]  = [PFUser currentUser][@"userId"];
    }
    
    // Segment Controlをdisabled
    [familyRole saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in switchRole : %@", error]];
            return;
        }
        [FamilyRole updateCache];
    }];
}

+ (void) unlinkFamily:(PFBooleanResultBlock)block
{
    PFQuery *query = [PFQuery queryWithClassName:@"FamilyRole"];
    [query whereKey:@"familyId" equalTo:[PFUser currentUser][@"familyId"]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in unlinkFamily, can't get FamilyRole : %@", error]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"エラーが発生しました"
                                                            message:@"データの更新に失敗しました。\n再度お試しください。"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
            return;
        }
        
        NSString *createdBy = object[@"createdBy"];
        
        // createdByがないユーザー = 古いバージョンの時にひも付けがされた人。
        // この人たちがひも付け解除した場合には、解除をした方の人がFamilyIdを引き継ぐと決める
        if (!createdBy) {
            NSString *myId = [PFUser currentUser][@"userId"];
            object[@"createdBy"] = myId;
            if ([object[@"uploader"] isEqualToString:myId]) {
                object[@"chooser"] = @"";
            } else {
                object[@"uploader"] = @"";
            }
        } else {
            if ([object[@"uploader"] isEqualToString:createdBy]) {
                object[@"chooser"] = @"";
            } else {
                object[@"uploader"] = @"";
            }
        }
        [object saveInBackgroundWithBlock:block];
    }];
}

@end
