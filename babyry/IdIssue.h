//
//  IdIssue.h
//  babyry
//
//  Created by 平田基 on 2014/07/03.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface IdIssue : NSObject
- (NSString *)issue: (NSString*)type;
- (NSString *)randomStringWithLength: (int)length;
@property NSString *issuedId;
@end
