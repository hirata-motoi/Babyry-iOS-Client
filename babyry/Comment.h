//
//  Comment.h
//  babyry
//
//  Created by Kenji Suzuki on 2015/01/18.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Comment : NSObject

+ (NSMutableDictionary *)getAllCommentNum;
+ (void) updateCommentNumEntity:(NSString *)childObjectId;

@end
