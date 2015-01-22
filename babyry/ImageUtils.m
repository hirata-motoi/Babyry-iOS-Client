//
//  ImageUtils.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/09.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ImageUtils.h"

@implementation ImageUtils

+ (NSString *)contentTypeForImageData:(NSData *)data
{
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
    }
    return nil;
}

+ (UIImage *)filterImage:(UIImage *)originImage withFilterName:(NSString *)filterName
{
    CIImage *filteredImage = [[CIImage alloc] initWithCGImage:originImage.CGImage];
    CIFilter *filter = [CIFilter filterWithName:filterName];
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
