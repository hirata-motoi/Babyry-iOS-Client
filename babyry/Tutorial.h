//
//  Tutorial.h
//  babyry
//
//  Created by hirata.motoi on 2014/09/11.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tutorial : NSObject

+ (void)initializeTutorialStage:(BOOL)hasFamilyId;
+ (NSString *)currentStage;
+ (NSString *)updateStage:(NSString *)preStage;
+ (BOOL)underTutorial;

@end
