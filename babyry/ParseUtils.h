//
//  ParseUtils.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/19.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface ParseUtils : NSObject

+ (NSDictionary *) pfObjectToDic:(PFObject *)object;

@end
