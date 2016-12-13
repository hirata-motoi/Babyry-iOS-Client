//
//  Tutorial.h
//  babyry
//
//  Created by hirata.motoi on 2014/09/11.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TutorialStage.h"

@interface Tutorial : NSObject

+ (NSString *)initializeTutorialStage:(NSString *)familyId hasStartedTutorial:(BOOL)hasStartedTutorial partnerUserId:(NSString *)partnerUserId;
+ (TutorialStage *)currentStage;
+ (TutorialStage *)forwardStageWithNextStage:(NSString *)nextStage;
+ (BOOL)underTutorial;
+ (void)upsertTutorialAttributes:(NSString *)key withValue:(NSString *)value;
+ (NSString *)getTutorialAttributes:(NSString *)key;
+ (BOOL)shouldShowDefaultImage;
+ (BOOL)shouldShowFamilyApplyLead;
+ (BOOL)shouldShowTutorialIntroduction;
+ (void)forwardTutorialStageToLast;
+ (void)removeDefaultChild:(NSMutableArray *)childProperties;
+ (void)removeTutorialStage;
+ (BOOL)existsTutorialChild;

@end
