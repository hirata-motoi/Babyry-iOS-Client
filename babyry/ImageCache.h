//
//  ImageCache.h
//  babyry
//
//  Created by kenjiszk on 2014/06/09.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageCache : NSObject

+ (void) setCache:name image:(NSData *)image dir:(NSString *)dir;
+ (NSData *) getCache:(NSString *)name dir:(NSString *)dir;
+ (UIImage *) makeThumbNail:(UIImage *)orgImage;
+ (void) removeCache:name;
+ (NSDate *) returnTimestamp:name;
+ (NSArray *) listCachedImage:(NSString *)dirName;
+ (void) removeAllCache;
+ (void)updateTimeStamp:name;
+ (NSArray *) getListOfMultiUploadCache:(NSString *)dir;

@end
