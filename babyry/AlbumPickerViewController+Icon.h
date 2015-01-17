//
//  AlbumPickerViewController+Icon.h
//  babyry
//
//  Created by hirata.motoi on 2015/01/13.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageSelectToolView.h"

@class AlbumPickerViewController;

@interface AlbumPickerViewController_Icon : NSObject <ImageSelectToolViewDelegate>

@property (weak) AlbumPickerViewController *albumPickerViewController;

- (void) logicViewDidLoad;
- (void) logicSendImageButton:(NSIndexPath *)indexPath;

@end
