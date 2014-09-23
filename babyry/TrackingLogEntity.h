//
//  TrackingLogEntity.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/18.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TrackingLogEntity : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * logName;
@property (nonatomic, retain) NSString * lastViewController;

@end
