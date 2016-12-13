//
//  CommentNumEntity.h
//  babyry
//
//  Created by Kenji Suzuki on 2015/01/18.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CommentNumEntity : NSManagedObject

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSNumber * value;

@end
