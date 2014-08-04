//
//  PageContentViewController.h
//  babyrydev
//
//  Created by kenjiszk on 2014/06/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICTutorialOverlay.h"
#import <Parse/Parse.h>
#import "DragView.h"

@interface PageContentViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource, DragViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *pageContentCollectionView;

@property NSUInteger pageIndex;
@property (strong, nonatomic) NSArray *childArray;
@property NSString *childObjectId;

@property ICTutorialOverlay *overlay;
@property UILabel *tutoLabel;

@property NSString *returnValueOfChildName;
@property NSString *returnValueOfChildBirthday;

@property NSMutableArray *bestFlagArray;
@property NSMutableArray *childImages;
@property NSMutableDictionary *childImagesIndexMap;
@property NSMutableArray *scrollPositionData;
@property CGFloat nextSectionHeight;
@property DragView *dragView;
@property BOOL dragging;
@property CGFloat dragViewUpperLimitOffset;
@property CGFloat dragViewLowerLimitOffset;
@property BOOL dragViewZoomed;

@property NSNumber *tutorialStep;

@property PFUser *currentUser;

@property int isFirstLoad;

@property UICollectionViewCell *isNoImageCellForTutorial;

@property UILabel *tutoSkipLabel;
@property BOOL isLoading;
@property NSDateComponents *dateComp;

- (void)drag:(DragView *)dragView;

@end
