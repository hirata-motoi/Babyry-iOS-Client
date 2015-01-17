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

@end
