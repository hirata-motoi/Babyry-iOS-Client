//
//  PartnerInvitedEntity.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/21.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PartnerInvitedEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * inputtedPinCode;
@property (nonatomic, retain) NSString * familyId;

@end
