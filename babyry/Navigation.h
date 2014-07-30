//
//  Navigation.h
//  babyry
//
//  Created by hirata.motoi on 2014/07/25.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Navigation : NSObject
+ (void)setTitle: (UINavigationItem *)navigationItem withTitle:(NSString *)title withFont:(NSString *)font withFontSize:(CGFloat)fontSize withColor:(UIColor *)color;
+ (void)setNavbarColor: (UINavigationBar *)navigationBar withColor:(UIColor *)color withEtcElements:(NSArray *)elements;
@end
