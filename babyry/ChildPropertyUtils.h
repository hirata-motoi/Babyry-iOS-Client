//
//  ChildPropertyUtils.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/22.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ChildPropertyUtilsDelegate <NSObject>

- (void)resetFields;
- (void)openIconEdit:(NSString *)childObjectId;
- (void)openAlbumPicker:(NSString *)childObjectId;

@end

@interface ChildPropertyUtils : NSObject<UIActionSheetDelegate>
@property (nonatomic,assign) id<ChildPropertyUtilsDelegate> delegate;

- (void)saveChildProperty:(NSString *)childObjectId withParams:(NSMutableDictionary *)params;
- (UIAlertController *)iconEditAlertController:(NSString *)childObjectId;
- (UIActionSheet *)iconEditActionSheet:(NSString *)childObjectId;

@end
