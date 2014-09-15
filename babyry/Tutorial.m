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
    NSLog(@"stage : %@", firstStage);
    TutorialStage *newTutorialStage = [TutorialStage MR_createEntity];
    newTutorialStage.currentStage = firstStage;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

+ (NSString *)currentStage
{
    TutorialStage *tutorialStage = [TutorialStage MR_findFirst];
    
    if (!tutorialStage) {
        NSString *firstStage = [Config config][@"tutorialStages"][0];
        TutorialStage *newTutorialStage = [TutorialStage MR_createEntity];
        newTutorialStage.currentStage = firstStage;
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        return firstStage;
    }
    
    return tutorialStage.currentStage;
}

+ (BOOL)underTutorial
{
    NSString *currentStage = [self currentStage];
    if (!currentStage) {
        return NO;
    }
    return ![currentStage isEqualToString:@"tutorialFinished"];
}

// 引数が空の場合はexception
// rowがない場合はexception
+ (NSString *)updateStage:(NSString *)preStage
{
    if (!preStage) {
        @throw @"invalid argument";
    }
    TutorialStage *tutorialStage = [TutorialStage MR_findFirst];
    if (!tutorialStage) {
        @throw @"can't find currentTutorialStage";
    }
   
    NSString *nextStage = @"";
    NSArray *tutorialStages = [Config config][@"tutorialStages"];
    for (int i = 0; i < tutorialStages.count; i++) {
        if ([preStage isEqualToString: tutorialStages[i]]) {
            tutorialStage.currentStage = tutorialStages[i + 1];
            break;                       
        }
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    return tutorialStage.currentStage;
}

@end
