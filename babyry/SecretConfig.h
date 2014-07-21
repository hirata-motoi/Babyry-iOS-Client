//
//  SecretConfig.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/07/22.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SecretConfig : NSObject

+ (NSString *) getParseApplicationId;
+ (NSString *) getParseClientKey;
+ (NSString *) getTwitterConsumerKey;
+ (NSString *) getTwitterSecretKey;

@end
