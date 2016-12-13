//
//  ImageTrimming.m
//  babyry
//
//  Created by kenjiszk on 2014/06/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageTrimming.h"
#import "ImageCache.h"
#import "UIImage+ImageEffects.h"
#import "ColorUtils.h"

@implementation ImageTrimming

+ (UIImage *) makeRectImage:(UIImage *)orgImage
{
    if (orgImage.size.width == orgImage.size.height) {
        return orgImage;
    }
    // 短い辺にあわせて正方形を作る
    int newImageSize;
    CGRect trimArea;
    if (orgImage.size.width > orgImage.size.height) {
        // 横長
        newImageSize = orgImage.size.height;
        trimArea = CGRectMake((orgImage.size.width - newImageSize)/2, 0, newImageSize, newImageSize);
    } else {
        // 縦長
        newImageSize = orgImage.size.width;
        trimArea = CGRectMake(0, (orgImage.size.height - newImageSize)/2, newImageSize, newImageSize);
    }

    CGImageRef srcImageRef = [orgImage CGImage];
    CGImageRef trimmedImageRef = CGImageCreateWithImageInRect(srcImageRef, trimArea);
    UIImage *trimmedImage = [UIImage imageWithCGImage:trimmedImageRef];

    // UIImageで保持している方だけreleaseする必要がある
    // You have to call CGImageRelease only when you use CGImageCreate, Copy or Retain.
    CGImageRelease(trimmedImageRef);

    return trimmedImage;
}

+ (UIImage *) makeRectTopImage:(UIImage *)orgImage ratio:(float)ratio
{
    // TopImageは width : height = 1 : 3/4 にする
    // ratio = height/width = 3/4
    int newImageSize;
    CGRect trimArea;
    if (orgImage.size.width * ratio >= orgImage.size.height) {
        // 横長
        newImageSize = orgImage.size.height;
        trimArea = CGRectMake((orgImage.size.width - newImageSize/ratio)/2, 0, newImageSize/ratio, newImageSize);
    } else {
        // 縦長
        newImageSize = orgImage.size.width;
        trimArea = CGRectMake(0, (orgImage.size.height - newImageSize*ratio)/2, newImageSize, newImageSize*ratio);
    }
    CGImageRef srcImageRef = [orgImage CGImage];
    CGImageRef trimmedImageRef = CGImageCreateWithImageInRect(srcImageRef, trimArea);
    UIImage *trimmedImage = [UIImage imageWithCGImage:trimmedImageRef];

    // UIImageで保持している方だけreleaseする必要がある
    // You have to call CGImageRelease only when you use CGImageCreate, Copy or Retain.
    CGImageRelease(trimmedImageRef);
    
    return trimmedImage;
}

+ (UIImage *) resizeImageForUpload:(UIImage *)orgImage
{
    float imageWidth = orgImage.size.width;
    float imageHeight = orgImage.size.height;
    
    // 長い方の辺を1000にする
    float longSide = 1000;
    if (imageWidth < longSide && imageHeight < longSide){
        // 両辺とも1500以下なのでそのまま返す
        return orgImage;
    } else {
        float scale = (imageWidth > imageHeight ? longSide/imageWidth : longSide/imageHeight);
        CGSize resizedSize = CGSizeMake(imageWidth * scale, imageHeight * scale);
        UIGraphicsBeginImageContext(resizedSize);
        [orgImage drawInRect:CGRectMake(0, 0, resizedSize.width, resizedSize.height)];
        UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return resizedImage;
    }
}

+ (UIImage *) makeMultiCandidateImageWithBlur:(NSArray *)candidatePathArray childObjectId:(NSString *)chidObjectId ymd:(NSString *)ymd cellFrame:(CGRect)cellFrame
{
    UIImage *returnImage = nil;

    long candidateCount = [candidatePathArray count];
    if (candidateCount == 0) {
        return nil;
    } else if (candidateCount == 1) {
        // 一枚の時は画像にブラーかけるだけ
        NSData *imageCacheData = [ImageCache getCache:candidatePathArray[0] dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", chidObjectId, ymd]];
        UIImage *cacheImage = [UIImage imageWithData:imageCacheData];
        UIImage *trimmedImage;
        trimmedImage = [ImageTrimming makeRectTopImage:cacheImage ratio:(cellFrame.size.height/cellFrame.size.width)];
        UIImage *trimmedImageWithBlur = [trimmedImage applyBlurWithRadius:4 tintColor:[ColorUtils getBlurTintColor] saturationDeltaFactor:1 maskImage:nil];
        returnImage = trimmedImageWithBlur;
    } else if (candidateCount == 2) {
        // 2枚の時は上下に分ける
        UIGraphicsBeginImageContext(CGSizeMake(cellFrame.size.width, cellFrame.size.height));
        for (int i = 0; i < 2; i++) {
            NSData *imageCacheData = [ImageCache getCache:candidatePathArray[i] dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", chidObjectId, ymd]];
            UIImage *cacheImage = [UIImage imageWithData:imageCacheData];
            UIImage *trimmedImage;
            trimmedImage = [ImageTrimming makeRectTopImage:cacheImage ratio:(cellFrame.size.height/2/cellFrame.size.width)];
            UIImage *trimmedImageWithBlur = [trimmedImage applyBlurWithRadius:4 tintColor:[ColorUtils getBlurTintColor] saturationDeltaFactor:1 maskImage:nil];
            [trimmedImageWithBlur drawInRect:CGRectMake(0, cellFrame.size.height/2*i, cellFrame.size.width, cellFrame.size.height/2)];
        }
        returnImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    } else if (candidateCount == 3) {
        // 3枚の時は、一枚目を上、二三枚目を下に
        UIGraphicsBeginImageContext(CGSizeMake(cellFrame.size.width, cellFrame.size.height));
        for (int i = 0; i < 3; i++) {
            NSData *imageCacheData = [ImageCache getCache:candidatePathArray[i] dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", chidObjectId, ymd]];
            UIImage *cacheImage = [UIImage imageWithData:imageCacheData];
            UIImage *trimmedImage;
            if (i == 0) {
                trimmedImage = [ImageTrimming makeRectTopImage:cacheImage ratio:(cellFrame.size.height/2/cellFrame.size.width)];
                UIImage *trimmedImageWithBlur = [trimmedImage applyBlurWithRadius:4 tintColor:[ColorUtils getBlurTintColor] saturationDeltaFactor:1 maskImage:nil];
                [trimmedImageWithBlur drawInRect:CGRectMake(0, 0, cellFrame.size.width, cellFrame.size.height/2)];
            } else {
                trimmedImage = [ImageTrimming makeRectTopImage:cacheImage ratio:(cellFrame.size.height/cellFrame.size.width)];
                UIImage *trimmedImageWithBlur = [trimmedImage applyBlurWithRadius:4 tintColor:[ColorUtils getBlurTintColor] saturationDeltaFactor:1 maskImage:nil];
                [trimmedImageWithBlur drawInRect:CGRectMake(cellFrame.size.width/2*(i-1), cellFrame.size.height/2, cellFrame.size.width/2, cellFrame.size.height/2)];
            }
        }
        returnImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    } else {
        // 4枚以上なら最初の4枚を使って画像を作る
        UIGraphicsBeginImageContext(CGSizeMake(cellFrame.size.width, cellFrame.size.height));
        for (int i = 0; i < 4; i++) {
            NSData *imageCacheData = [ImageCache getCache:candidatePathArray[i] dir:[NSString stringWithFormat:@"%@/candidate/%@/thumbnail", chidObjectId, ymd]];
            UIImage *cacheImage = [UIImage imageWithData:imageCacheData];
            UIImage *trimmedImage = [ImageTrimming makeRectTopImage:cacheImage ratio:(cellFrame.size.height/cellFrame.size.width)];
            UIImage *trimmedImageWithBlur = [trimmedImage applyBlurWithRadius:4 tintColor:[ColorUtils getBlurTintColor] saturationDeltaFactor:1 maskImage:nil];
            [trimmedImageWithBlur drawInRect:CGRectMake(cellFrame.size.width/2*(i%2), cellFrame.size.height/2*floor(i/2), cellFrame.size.width/2, cellFrame.size.height/2)];
        }
        returnImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return returnImage;
}

+ (UIImage *) makeCellIconForMenu:(UIImage *)orgImage size:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [orgImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newThumbnail;
}

@end
