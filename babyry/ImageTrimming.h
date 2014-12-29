//
//  ImageTrimming.h
//  babyry
//
//  Created by kenjiszk on 2014/06/17.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageTrimming : NSObject

+ (UIImage *) makeRectImage:(UIImage *)orgImage;
+ (UIImage *) makeRectTopImage:(UIImage *)orgImage ratio:(float)ratio;
+ (UIImage *) resizeImageForUpload:(UIImage *)orgImage;
+ (UIImage *) makeMultiCandidateImageWithBlur:(NSArray *)candidatePathArray childObjectId:(NSString *)chidObjectId ymd:(NSString *)ymd cellFrame:(CGRect)cellFrame;

@end
