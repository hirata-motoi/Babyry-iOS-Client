//
//  Tutorial.m
//  babyry
//
//  Created by hirata.motoi on 2014/09/11.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Tutorial.h"
#import "TutorialStage.h"
#import "Config.h"
#import "DateUtils.h"
#import "TutorialAttributes.h"
#import "ImageCache.h"

@implementation Tutorial

+ (NSString *)initializeTutorialStage:(NSString *)familyId hasStartedTutorial:(BOOL)hasStartedTutorial partnerUserId:(NSString *)partnerUserId
{
    TutorialStage *tutorialStage = [TutorialStage MR_findFirst];
    if (tutorialStage) {
        return tutorialStage.currentStage;
    }
   
    tutorialStage = [TutorialStage MR_createEntity];
    if (hasStartedTutorial) {
        if (familyId) {
            if ([partnerUserId isEqualToString:@""]) {
                // botと紐づいている状態
                tutorialStage.currentStage = @"familyApplyExec";
            } else {
                tutorialStage.currentStage = @"tutorialFinished";
            }
        } else {
            // チュートリアルを経験していてfamilyIdがないケースは現状の仕様ではない
            // 今後紐付け解除が実装されれば出てくるかも
            tutorialStage.currentStage = @"familyApplyExec";
        }
    } else {
        if (familyId) {
            // tutorialをやっていないがfamilyIdがあるユーザ == 招待されたユーザ
            tutorialStage.currentStage = @"tutorialFinished";
        } else {
            // 始めたばかりのユーザ
            tutorialStage.currentStage = @"introduction";
        }
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    return tutorialStage.currentStage;
}

+ (TutorialStage *)currentStage
{
    TutorialStage *tutorialStage = [TutorialStage MR_findFirst];
    return tutorialStage;
}

+ (BOOL)underTutorial
{
    TutorialStage *currentStage = [self currentStage];
    if (!currentStage) {
        return NO;
    }
    return ![currentStage.currentStage isEqualToString:@"tutorialFinished"];
}

+ (BOOL)shouldShowDefaultImage
{
    TutorialStage *currentStage = [self currentStage];
    if (!currentStage) {
        return NO;
    }
    
    if (
        [currentStage.currentStage isEqualToString:@"introduction"] ||
        [currentStage.currentStage isEqualToString:@"chooseByUser"] ||
        [currentStage.currentStage isEqualToString:@"partChange"]   ||
        [currentStage.currentStage isEqualToString:@"addChild"]
    ) {
        return YES;
    }
    return NO;
}

+ (TutorialStage *)forwardStageWithNextStage:(NSString *)nextStage
{
    NSArray *tutorialStages = [Config config][@"tutorialStages"];
    TutorialStage *currentStage = [self currentStage];
    if (!currentStage || [currentStage.currentStage isEqualToString:tutorialStages[ tutorialStages.count - 1 ]]) {
        return nil;
    }
   
    BOOL isValidStage = NO;
    for (NSString *stage in tutorialStages) {
        if ([stage isEqualToString:nextStage]) {
            isValidStage = YES;
            break;
        }
    }
    if (!isValidStage) {
        return currentStage.currentStage;
    }
    
    currentStage.currentStage = nextStage;
   
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    return currentStage;
}

+ (void)upsertTutorialAttributes:(NSString *)key withValue:(NSString *)value
{
    TutorialAttributes *attribute = [TutorialAttributes MR_findFirstByAttribute:@"key" withValue:key];
    if (!attribute) {
        attribute = [TutorialAttributes MR_createEntity];
        attribute.key = key;
    }
    attribute.value = value;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

+ (NSString *)getTutorialAttributes:(NSString *)key
{
    TutorialAttributes *attribute = [TutorialAttributes MR_findFirstByAttribute:@"key" withValue:key];
    if (attribute) {
        return attribute.value;
    }
    return @"";
}

// stageがfamilyApply or familyApplyExec の場合に真
+ (BOOL)shouldShowFamilyApplyLead
{
    TutorialStage *currentStage = [self currentStage];
    if (!currentStage) {
        return NO;
    }
    if ([currentStage.currentStage isEqualToString:@"familyApply"] || [currentStage.currentStage isEqualToString:@"familyApplyExec"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)shouldShowTutorialIntroduction
{
    TutorialStage *currentStage = [self currentStage];
    if (!currentStage) {
        return NO;
    }
    
    if ([currentStage.currentStage isEqualToString:@"introduction"]) {
        return YES;
    }
    return NO;
}

+ (void)forwardTutorialStageToLast
{
    TutorialStage *currentStage = [self currentStage];
    currentStage.currentStage = @"familyApplyExec";
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

+ (void)removeDefaultChild:(NSMutableArray *)childProperties
{
    [ImageCache removeAllCache];
    // ViewControllerのchildPropertiesからデフォルトのこどもを削除
    NSString *tutorialChildObjectId = [Tutorial getTutorialAttributes:@"tutorialChildObjectId"];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"objectId = %@", tutorialChildObjectId];
    NSArray *tutorialChildObjects = [childProperties filteredArrayUsingPredicate:p];
    if (tutorialChildObjects.count > 0) {
        [childProperties removeObject:tutorialChildObjects[0]];
    }
}

+ (void)removeTutorialStage
{
    TutorialStage *currentStage = [Tutorial currentStage];
    [currentStage MR_deleteEntity];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

@end
