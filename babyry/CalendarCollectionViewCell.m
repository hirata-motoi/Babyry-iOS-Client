//
//  CalendarCollectionViewCell.m
//  babyry
//
//  Created by 平田基 on 2014/07/14.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "CalendarCollectionViewCell.h"

@implementation CalendarCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)rotate
{
    CALayer* layer = self.layer;
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    // Y軸での回転アニメーション
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
    animation.duration = 0.4;   // 速度(秒数)
    animation.repeatCount = 1;  // 繰り返す回数
    animation.fromValue = [NSNumber numberWithFloat:0.0];       // 開始角度
    animation.toValue = [NSNumber numberWithFloat:2 * M_PI];    // 終了角度（１周）
    
    // Layerにアニメーションを登録
    [layer addAnimation:animation forKey:@"rotation-y"];
    
    //終了時の処理を登録
    [CATransaction setValue:^{
        layer.transform = CATransform3DIdentity;//今回の例だと不要(だと思う)ですが、layerの変形を初期状態に戻します
    } forKey:kCATransactionCompletionBlock];
    
    // コミット→アニメーション開始
    [CATransaction commit];
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
