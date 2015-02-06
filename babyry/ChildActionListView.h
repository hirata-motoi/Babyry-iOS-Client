//
//  ChildActionListView.h
//  babyry
//
//  Created by hirata.motoi on 2015/02/05.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChildActionListViewDelegate <NSObject>

- (void)removeChild:(NSString *)childObjectId;

@end

@interface ChildActionListView : UIView<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic,assign) id<ChildActionListViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITableView *actionListTable;
@property NSString *childObjectId;

+ (instancetype)view;

@end
