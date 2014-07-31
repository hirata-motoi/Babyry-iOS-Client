//
//  Navigation.m
//  babyry
//
//  Created by hirata.motoi on 2014/07/25.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Navigation.h"
#import "UIColor+Hex.h"

@implementation Navigation

+ (void)setTitle: (UINavigationItem *)navigationItem withTitle:(NSString *)title withFont: (NSString *)font withFontSize: (CGFloat)fontSize withColor: (UIColor *)color
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
        color = [UIColor_Hex colorWithHexString:@"ffbd22" alpha:1.0f];
    }
    label.font = [UIFont fontWithName:font size:fontSize];
    label.textColor = color;
    
    // 表示最大サイズ
    CGSize bounds = CGSizeMake(320, 44);
    
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
        CGSize size = [label.text sizeWithFont:label.font
                             constrainedToSize:bounds
                                 lineBreakMode:mode];
    }
    size.width  = ceilf(size.width);
    size.height = ceilf(size.height);
  
    int labelX = (320 - size.width) / 2;
    int labelY = (44 - size.height) / 2;
    label.frame = CGRectMake(labelX, labelY, size.width, size.height);
    navigationItem.titleView = label;
}

+ (void)setNavbarColor: (UINavigationBar *)navigationBar withColor:(UIColor *)color withEtcElements:(NSArray *)elements
{
    if (color == nil) {
        color = [UIColor_Hex colorWithHexString:@"EEEEEE" alpha:0.6f];
    }
    navigationBar.backgroundColor = color;
    
    for (UIView *element in elements) {
        element.backgroundColor = color;
    }
}
@end
