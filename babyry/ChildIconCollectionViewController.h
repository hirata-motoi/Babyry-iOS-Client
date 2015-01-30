//
//  ChildIconCollectionViewController.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/06.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageSelectToolView.h"

@protocol ChildIconCollectionViewControllerDelegate <NSObject>

- (void)submit:(NSData *)imageData withChildObjectId:(NSString *)childObjectId;

@end

@interface ChildIconCollectionViewController : UICollectionViewController<ImageSelectToolViewDelegate>
@property (strong, nonatomic) IBOutlet UICollectionView *childIconCollectionView;
@property (nonatomic, assign)id<ChildIconCollectionViewControllerDelegate>delegate;

@property NSString *childObjectId;

@end
