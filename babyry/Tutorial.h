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

+ (void)initializeTutorialStage:(BOOL)hasFamilyId;
+ (TutorialStage *)currentStage;
+ (TutorialStage *)updateStage;
+ (BOOL)underTutorial;
+ (void)upsertTutorialAttributes:(NSString *)key withValue:(NSString *)value;
+ (NSString *)getTutorialAttributes:(NSString *)key;
+ (BOOL)shouldShowDefaultImage;

@end
