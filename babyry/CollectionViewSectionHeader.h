//
//  CollectionViewSectionHeader.h
//  babyry
//
//  Created by hirata.motoi on 2014/08/13.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CollectionViewSectionHeader;
@protocol CollectionViewSectionHeaderDelegate <NSObject>
- (void)toggleCells:(NSInteger)sectionIndex;
@end


@interface CollectionViewSectionHeader : UIView
@property (nonatomic,assign) id<CollectionViewSectionHeaderDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *yearLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property NSInteger sectionIndex;

+ (instancetype)view;
- (void)setParmetersWithYear:(NSInteger)year withMonth:(NSInteger)month withName:(NSString *)name;
@end
