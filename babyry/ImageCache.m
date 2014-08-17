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

// ${prefix}-${imageObjectId}のキャッシュをタイムスタンプでソートして返す
+ (NSArray *) getListOfMultiUploadCache:(NSString *)prefix
{
    NSString *prefixWithHyphen = [NSString stringWithFormat:@"%@%@", prefix, @"-"];
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirPath = [array objectAtIndex:0];
    NSString *imageCacheDirPath = [cacheDirPath stringByAppendingPathComponent:@"ImageCache"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *bundleDirectory = [fileManager contentsOfDirectoryAtPath:imageCacheDirPath error:nil];
    
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self BEGINSWITH %@", prefixWithHyphen];
    NSArray *multiCache = [bundleDirectory filteredArrayUsingPredicate:filter];
    
    NSMutableArray *attributes = [NSMutableArray array];
    
    for (NSString *cache in multiCache) {
        // ファイル属性にファイルパスを追加するためにDictionaryを用意しておく
        NSMutableDictionary *tmpDictionary = [NSMutableDictionary dictionary];
        
        NSString *filepath = [imageCacheDirPath stringByAppendingPathComponent:cache];
        // ファイル情報（属性）を取得
        NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:filepath error:nil];
        
        // tmp配列に属性を格納
        [tmpDictionary setDictionary:attr];
        
        // tmp配列にファイルパスを格納
        [tmpDictionary setObject:filepath forKey:@"FilePath"];
        
        [attributes addObject:tmpDictionary];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:NSFileCreationDate ascending:YES];
    NSArray *sortarray = [NSArray arrayWithObject:sortDescriptor];
    
    // 並び替えられたファイル配列
    NSArray *sortedMultiCache = [attributes sortedArrayUsingDescriptors:sortarray];
    
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    for (NSMutableDictionary *attr in sortedMultiCache) {
        NSArray *splitArray = [[attr objectForKey:@"FilePath"] componentsSeparatedByString:@"/"];
        [returnArray addObject:[splitArray lastObject]];
    }
    return (NSArray *)returnArray;
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

+(void)updateTimeStamp:name
{
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirPath = [array objectAtIndex:0];
    NSString *imageCacheDirPath = [cacheDirPath stringByAppendingPathComponent:@"ImageCache"];
    NSString *imageCacheFilePath = [imageCacheDirPath stringByAppendingPathComponent:name];
    
    NSDictionary *attrs = @{
                            NSFileModificationDate: [NSDate date]
                            };
    
    NSFileManager *fs = [NSFileManager defaultManager];
    [fs setAttributes:attrs ofItemAtPath:imageCacheFilePath error:nil];
    
    // 変更後の属性を一覧表示して結果を確認。
    attrs = [fs attributesOfItemAtPath:imageCacheFilePath error:nil];
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
    float width = 320.0f;
    float height = width * orgImage.size.height/orgImage.size.width;
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    [orgImage drawInRect:CGRectMake(0, 0, width, height)];
    UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return thumbImage;
}

@end
