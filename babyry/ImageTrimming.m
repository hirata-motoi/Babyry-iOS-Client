//
//  ImageTrimming.m
//  babyry
//
//  Created by kenjiszk on 2014/06/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageTrimming.h"

@implementation ImageTrimming

- (UIImage *) makeRectImage:(UIImage *)orgImage
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
    
    return trimmedImage;
}

@end
