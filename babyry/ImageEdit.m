//
//  ImageEdit.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageEdit.h"

@implementation ImageEdit

+ (UIImage *)filterImage:(UIImage *)originImage
{
    CIImage *filteredImage = [[CIImage alloc] initWithCGImage:originImage.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIMinimumComponent"];
    [filter setValue:filteredImage forKey:@"inputImage"];
    filteredImage = filter.outputImage;
    
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    CGImageRef imageRef = [ciContext createCGImage:filteredImage
                                          fromRect:[filteredImage extent]];
    UIImage *outputImage  = [UIImage imageWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    return outputImage;
}

@end
