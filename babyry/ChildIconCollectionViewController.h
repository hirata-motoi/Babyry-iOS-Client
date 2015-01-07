//
//  ChildIconCollectionViewController.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/06.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChildIconCollectionViewController : UICollectionViewController
@property (strong, nonatomic) IBOutlet UICollectionView *childIconCollectionView;

@property NSString *childObjectId;

@end
