//
//  ImageUtils.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/09.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageUtils : NSObject

+ (NSString *)contentTypeForImageData:(NSData *)data;
+ (UIImage *)filterImage:(UIImage *)originImage withFilterName:(NSString *)filterName;

@end
