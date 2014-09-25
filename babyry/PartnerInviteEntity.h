//
//  PartnerInviteEntity.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/24.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PartnerInviteEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * linkComplete;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * pinCode;

@end