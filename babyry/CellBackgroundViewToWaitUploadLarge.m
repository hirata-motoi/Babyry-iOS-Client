//
//  CellBackgroundViewToWaitUploadLarge.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "CellBackgroundViewToWaitUploadLarge.h"

@implementation CellBackgroundViewToWaitUploadLarge

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // 初期化
    _iconView.image = [self filterImage: [UIImage imageNamed:@"imageIcon"]];
}

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    return [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
}


// TODO 共通classへ切り出し
- (UIImage *)filterImage:(UIImage *)originImage
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


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
