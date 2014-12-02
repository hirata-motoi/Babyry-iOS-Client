//
//  AlbumPickerViewController+Multi.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

// 循環参照避けるため
@class AlbumPickerViewController;

@interface AlbumPickerViewController_Multi : NSObject

@property (weak) AlbumPickerViewController *albumPickerViewController;

- (void) logicViewDidLoad;
- (void) logicSendImageButton;

@end
