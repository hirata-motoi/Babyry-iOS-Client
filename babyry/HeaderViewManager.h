//
//  HeaderViewManager.h
//  babyry
//
//  Created by hirata.motoi on 2014/11/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@protocol HeaderViewManagerDelegate <NSObject>

- (void)showHeaderView:(NSString *)type;
- (void)hideHeaderView;

@end

@interface HeaderViewManager : NSObject
{
    id<HeaderViewManagerDelegate>delegate;
}
@property (nonatomic, assign) id<HeaderViewManagerDelegate> delegate;

- (void)setupHeaderView:(BOOL)doBackground;
- (void)invalidateTimer;
- (void)validateTimer;

@end
