//
//  Navigation.m
//  babyry
//
//  Created by hirata.motoi on 2014/07/25.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Navigation.h"
#import "UIColor+Hex.h"
#import "ColorUtils.h"

@implementation Navigation

+ (void)setTitle: (UINavigationItem *)navigationItem withTitle:(NSString *)title withSubtitle:(NSString *)subtitle withFont: (NSString *)font withFontSize: (CGFloat)fontSize withColor: (UIColor *)color
{
    
    UILabel *label = [[UILabel alloc]init];
    label.text = title;

    if (font == nil) {
        font = @"HelveticaNeue-Bold"; // default
    }
    if (fontSize == 0) {
        fontSize = 20.0; // default
    }
    if (color == nil) {
        color = [UIColor_Hex colorWithHexString:@"ffffff" alpha:1.0f];
    }
    
    label.font = [UIFont fontWithName:font size:fontSize];
    label.textColor = color;
    label.adjustsFontSizeToFitWidth = YES;
    
    // 表示最大サイズ
    CGSize bounds = CGSizeMake(280, 44);
    
    // 文字列全体のサイズを取得
    CGSize size;
    if ([NSString instancesRespondToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        CGRect rect = [label.text boundingRectWithSize:bounds
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:@{NSFontAttributeName:label.font}
                                   context:nil];
        size = rect.size;
    } else {
        // for under iOS 7
        UILineBreakMode mode = label.lineBreakMode;
        size = [label.text sizeWithFont:label.font
                             constrainedToSize:bounds
                                 lineBreakMode:mode];
    }
    size.width  = ceilf(size.width);
    size.height = ceilf(size.height);
    label.frame = CGRectMake(0, 0, size.width, size.height);
   
    UIView *titleParent = [[UIView alloc]init];
    if (subtitle != nil) {
        UILabel *subtitleLabel = [self createSubtitleLabel:subtitle withColor:color withFont:font withBounds:bounds];
        NSInteger parentWidth;
        if (label.frame.size.width >= subtitleLabel.frame.size.width) {
            // titleのwidthの方が大きい場合
            parentWidth = label.frame.size.width;
            
            CGRect rect = label.frame;
            rect.origin.x = 0;
            label.frame = rect;
            
            CGRect subtitleRect = subtitleLabel.frame;
            subtitleRect.origin.x = (rect.size.width - subtitleRect.size.width) / 2;
            subtitleRect.origin.y = label.frame.origin.y + label.frame.size.height;
            subtitleLabel.frame = subtitleRect;
        } else {
            // subtitleのwidthの方が大きい場合
            parentWidth = subtitleLabel.frame.size.width;
            
            CGRect subtitleRect = subtitleLabel.frame;
            subtitleRect.origin.x = 0;
            subtitleRect.origin.y = label.frame.origin.y + label.frame.size.height;
            subtitleLabel.frame = subtitleRect;
            
            CGRect rect = label.frame;
            rect.origin.x = (subtitleRect.size.width - rect.size.width) / 2;
            label.frame = rect;
        }
        
        NSInteger parentHeight = label.frame.size.height + subtitleLabel.frame.size.height;
        NSInteger parentX = (320 - parentWidth) / 2;
        NSInteger parentY = (44 - parentHeight) / 2;
        titleParent.frame = CGRectMake(parentX, parentY, parentWidth, parentHeight);
        
        [titleParent addSubview:label];
        [titleParent addSubview:subtitleLabel];
        
    } else {
        int parentX = (320 - label.frame.size.width) / 2;
        int parentY = (44 - label.frame.size.height) / 2;
        titleParent.frame = CGRectMake(parentX, parentY, label.frame.size.width, label.frame.size.height);
        [titleParent addSubview:label];
    }
    
    navigationItem.titleView = titleParent;
}

+ (void)setNavbarColor: (UINavigationBar *)navigationBar withColor:(UIColor *)color withEtcElements:(NSArray *)elements
{
    if (color == nil) {
        color = [ColorUtils getBabyryColor];
    }
    navigationBar.barTintColor = color;
    navigationBar.backgroundColor = color;
    
    for (UIView *element in elements) {
        UIColor *elemColor = [UIColor colorWithCGColor:color.CGColor];
        element.backgroundColor = [elemColor colorWithAlphaComponent:1.0];
    }
}

+ (CGSize)immtableLabelSize: (UILabel *)label widhBounds:(CGSize)bounds
{
    CGSize size;
    if ([NSString instancesRespondToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        CGRect rect = [label.text boundingRectWithSize:bounds
                               options:NSStringDrawingUsesLineFragmentOrigin
                            attributes:@{NSFontAttributeName:label.font}
                               context:nil];
        size = rect.size;
    } else {
        // for under iOS 7
        UILineBreakMode mode = label.lineBreakMode;
        size = [label.text sizeWithFont:label.font
                         constrainedToSize:bounds
                             lineBreakMode:mode];
    }
    return size;
}

+ (UILabel *)createSubtitleLabel:(NSString *)subtitle withColor:color withFont:(UIFont *)font withBounds:(CGSize)bounds
{
    CGFloat subtitleFontSize = 12.0; // 現状は固定
    UILabel *subtitleLabel = [[UILabel alloc]init];
    subtitleLabel.textColor = color;
    subtitleLabel.text = subtitle;
    subtitleLabel.font = [UIFont fontWithName:font size:subtitleFontSize];
    
    // subtitleLabelのサイズを取得
    CGSize subtitleSize = [self immtableLabelSize:subtitleLabel widhBounds:bounds];
    subtitleSize.width = ceilf(subtitleSize.width);
    subtitleSize.height = ceilf(subtitleSize.height);
    subtitleLabel.frame = CGRectMake( 0, 0, subtitleSize.width, subtitleSize.height );
    return subtitleLabel;
}

@end
