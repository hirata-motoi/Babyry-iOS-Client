//
//  ImageCache.m
//  babyry
//
//  Created by kenjiszk on 2014/06/09.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageCache.h"

@implementation ImageCache

- (void) setCache:name image:(NSData *) image
{
    // Cache Dir
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirPath = [array objectAtIndex:0];
    
    // Create ImageCache dir if not found
    NSString *imageCacheDirPath = [cacheDirPath stringByAppendingPathComponent:@"ImageCache"];
    // 次にFileManagerを用いて、ディレクトリの作成を行います。
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:imageCacheDirPath]) {
        NSError *error = nil;
        BOOL created = [fileManager createDirectoryAtPath:imageCacheDirPath withIntermediateDirectories:YES attributes:nil error:&error];
        // 作成に失敗した場合は、原因をログに出します。
        if (!created) {
            NSLog(@"failed to create directory. reason is %@ - %@", error, error.userInfo);
        }
    }
    // save iamge
    NSString *savedPath = [imageCacheDirPath stringByAppendingPathComponent:name];
    NSError *error = nil;
    BOOL success = [fileManager createFileAtPath:savedPath contents:image attributes:nil];
    if (!success) {
        NSLog(@"failed to save image. reason is %@ - %@", error, error.userInfo);
    }
    NSLog(@"saved at %@", savedPath);
}

- (NSData *) getCache:date
{
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirPath = [array objectAtIndex:0];
    NSString *imageCacheDirPath = [cacheDirPath stringByAppendingPathComponent:@"ImageCache"];
    NSString *imageCacheFilePath = [imageCacheDirPath stringByAppendingPathComponent:date];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:imageCacheFilePath]) {
        return [[NSData alloc] initWithContentsOfFile:imageCacheFilePath];
    } else {
        return nil;
    }
}


@end
