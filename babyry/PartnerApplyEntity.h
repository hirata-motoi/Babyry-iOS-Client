//
//  PartnerApplyEntity.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/22.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PartnerApplyEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * linkComplete;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * pinCode;

@end
