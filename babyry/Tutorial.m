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

@implementation Tutorial

+ (void)initializeTutorialStage:(BOOL)hasFamilyId
{
    TutorialStage *tutorialStage = [TutorialStage MR_findFirst];
    if (tutorialStage) {
        return;
    }
    
    // tutorial stageがない かつ familyIdがない → tutorial未開始のユーザ → tutorial必要
    // tutorial stageがない かつ familyIdがある → tutorial実装前のアプリで始めたユーザ → tutorialは不要
    NSArray *tutorialStages = [Config config][@"tutorialStages"];
    NSString *firstStage = (hasFamilyId) ? tutorialStages[tutorialStages.count - 1] : tutorialStages[0];
    TutorialStage *newTutorialStage = [TutorialStage MR_createEntity];
    newTutorialStage.currentStage = firstStage;
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

// 引数が空の場合はexception
// rowがない場合はexception
+ (TutorialStage *)updateStage
{
    NSArray *tutorialStages = [Config config][@"tutorialStages"];
    TutorialStage *currentStage = [self currentStage];
    if (!currentStage || [currentStage.currentStage isEqualToString:tutorialStages[ tutorialStages.count - 1 ]]) {
        return nil;
    }
   
    for (int i = 0; i < tutorialStages.count; i++) {
        if ([currentStage.currentStage isEqualToString: tutorialStages[i]]) {
            currentStage.currentStage = tutorialStages[i + 1];
            break;                       
        }
    }
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

@end
