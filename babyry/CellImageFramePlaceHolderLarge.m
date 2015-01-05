//
//  CellImageFramePlaceHolderLarge.m
//  babyry
//
//  Created by Kenji Suzuki on 2015/01/03.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "CellImageFramePlaceHolderLarge.h"
#import "DateUtils.h"
#import "ColorUtils.h"

@implementation CellImageFramePlaceHolderLarge

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
}

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    CellImageFramePlaceHolderLarge *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    return view;
}

- (void)setPlaceHolderForCell:(CalendarCollectionViewCell *)cell indexPath:(NSIndexPath *)indexPath role:(NSString *)role candidateCount:(int)candidateCount
{
    if ([role isEqualToString:@"chooser"] && candidateCount < 1 && [DateUtils isInTwodayByIndexPath:indexPath]) {
        // チョイスで、candidateが無い場合、かつ2日以内は黄色いアイコン(Give me Photo用)を付ける
        self.placeHolderIcon.image = [UIImage imageNamed:@"IconGiveMePhoto"];
        self.placeHolderLabel.text = @"Give Me Photo!!";
        self.placeHolderLabel.textColor = [ColorUtils getBabyryColor];
        self.suggestLabel.text = @"アップロードをおねがいしましょう！";
        self.uploadedNumLabel.hidden = YES;
        self.uploadMaxNumLabel.hidden = YES;
    } else {
        // それ以外(Photo Uploaded!! or No Photo)は青いアイコン
        self.placeHolderIcon.image = [UIImage imageNamed:@"IconPhotoFrame"];
        if (candidateCount < 1) {
            // 写真が無ければNo Photo
            self.placeHolderLabel.text = @"No Photo";
            self.suggestLabel.text = @"いますぐアップロード!!";
            self.uploadedNumLabel.hidden = YES;
            self.uploadMaxNumLabel.hidden = YES;
        } else {
            // 写真枚数標示
            self.photoSmileIcon.hidden = YES;
            self.placeHolderLabel.text = @"Photo Uploaded!!";
            self.suggestLabel.text = [NSString stringWithFormat:@"%d枚アップロード済み", candidateCount];
            self.uploadedNumLabel.text = [NSString stringWithFormat:@"%d", candidateCount];
        }
    }
    // 文字にshadow+blurを付ける(ちょっと不満)
    self.placeHolderLabel.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.placeHolderLabel.layer.shadowOffset = CGSizeMake(0, 0);
    self.placeHolderLabel.layer.shadowRadius = 4.0;
    self.placeHolderLabel.layer.shadowOpacity = 1.0;
    self.placeHolderLabel.layer.masksToBounds = NO;
    self.suggestLabel.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.suggestLabel.layer.shadowOffset = CGSizeMake(0, 0);
    self.suggestLabel.layer.shadowRadius = 4.0;
    self.suggestLabel.layer.shadowOpacity = 1.0;
    self.suggestLabel.layer.masksToBounds = NO;
    
    [cell addSubview:self];
}

@end
