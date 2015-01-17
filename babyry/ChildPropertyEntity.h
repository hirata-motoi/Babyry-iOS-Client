//
//  ChildPropertyEntity.h
//  babyry
//
//  Created by hirata.motoi on 2014/10/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ChildPropertyEntity : NSManagedObject

@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSString * createdBy;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSDate * birthday;
@property (nonatomic, retain) NSString * familyId;
@property (nonatomic, retain) NSNumber * childImageShardIndex;
@property (nonatomic, retain) NSNumber * commentShardIndex;
@property (nonatomic, retain) NSString * sex;
@property (nonatomic, retain) NSNumber * calendarStartDate;
@property (nonatomic, retain) NSNumber * oldestChildImageDate;
@property (nonatomic, retain) NSDate * lastDisplayedAt;
@property (nonatomic, retain) NSNumber * iconVersion;

@end
