//
//  ImageCache.m
//  babyry
//
//  Created by kenjiszk on 2014/06/09.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageCache.h"

@implementation ImageCache

+ (void) setCache:name image:(NSData *) image
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
    //NSLog(@"saved at %@", savedPath);
}

+ (NSData *) getCache:name
{
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirPath = [array objectAtIndex:0];
    NSString *imageCacheDirPath = [cacheDirPath stringByAppendingPathComponent:@"ImageCache"];
    NSString *imageCacheFilePath = [imageCacheDirPath stringByAppendingPathComponent:name];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:imageCacheFilePath]) {
        return [[NSData alloc] initWithContentsOfFile:imageCacheFilePath];
    } else {
        return nil;
    }
}

+ (void) removeCache:name
{
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirPath = [array objectAtIndex:0];
    NSString *imageCacheDirPath = [cacheDirPath stringByAppendingPathComponent:@"ImageCache"];
    NSString *imageCacheFilePath = [imageCacheDirPath stringByAppendingPathComponent:name];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:imageCacheFilePath]) {
        NSError *error;
        BOOL result = [fileManager removeItemAtPath:imageCacheFilePath error:&error];
        if (!result) {
            NSLog(@"failed to remove cache.");
        }
    }
}

+ (NSDate *) returnTimestamp:name
{
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirPath = [array objectAtIndex:0];
    NSString *imageCacheDirPath = [cacheDirPath stringByAppendingPathComponent:@"ImageCache"];
    NSString *imageCacheFilePath = [imageCacheDirPath stringByAppendingPathComponent:name];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:imageCacheFilePath]) {
        NSMutableDictionary *fileAttribute = [NSMutableDictionary dictionaryWithDictionary:[[NSFileManager defaultManager] attributesOfItemAtPath:imageCacheFilePath error:nil]];
        return [fileAttribute objectForKey:@"NSFileModificationDate"];
    } else {
        return [NSDate dateWithTimeIntervalSinceNow:-30*365*24*60*60];
    }
}

// dirName :
//      ImageCache
//      Parse/PFFileCache
//      ParseKeyValueCache
+(NSArray *) listCachedImage:(NSString *)dirName
{
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirPath = [array objectAtIndex:0];
    NSString *imageCacheDirPath = [cacheDirPath stringByAppendingPathComponent:dirName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    return [fileManager contentsOfDirectoryAtPath:imageCacheDirPath error:&error];
}

// Image以外のキャッシュもあるけどね。。。
+(void) removeAllCache
{
    for (NSString *cacheDir in @[@"ImageCache", @"Parse/PFFileCache", @"ParseKeyValueCache"]) {
        NSArray *array = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cacheDirPath = [array objectAtIndex:0];
        NSString *imageCacheDirPath = [cacheDirPath stringByAppendingPathComponent:cacheDir];
        for (NSString *fileName in [self listCachedImage:cacheDir]) {
            NSString *imageCacheFilePath = [imageCacheDirPath stringByAppendingPathComponent:fileName];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if([fileManager fileExistsAtPath:imageCacheFilePath]) {
                NSError *error;
                BOOL result = [fileManager removeItemAtPath:imageCacheFilePath error:&error];
                if (!result) {
                    NSLog(@"failed to remove cache. %@", imageCacheFilePath);
                }
            }
        }
    }
}

// このクラスでいいのか？という疑問は置いておいて
+ (UIImage *) makeThumbNail:(UIImage *)orgImage
{
    float width = 100.0f;
    float height = width * orgImage.size.height/orgImage.size.width;
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    [orgImage drawInRect:CGRectMake(0, 0, width, height)];
    UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return thumbImage;
}

@end
