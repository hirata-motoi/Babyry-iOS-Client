//
//  TutorialBestShot.h
//  babyry
//
//  Created by hirata.motoi on 2014/09/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TutorialBestShot : NSManagedObject

@property (nonatomic, retain) NSNumber * date;
@property (nonatomic, retain) NSString * imageObjectId;

@end
