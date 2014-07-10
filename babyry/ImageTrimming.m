//
//  ImageTrimming.m
//  babyry
//
//  Created by kenjiszk on 2014/06/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageTrimming.h"

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

@end
