//
//  TmpUserData.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/13.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TmpUserData : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * isRegistered;

@end
