//
//  AlbumPickerViewController+Single.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/06.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AlbumPickerViewController;

@interface AlbumPickerViewController_Single : NSObject

@property (weak) AlbumPickerViewController *albumPickerViewController;

- (void) logicViewDidLoad;
- (void) logicSendImageButton:(NSIndexPath *)indexPath;

@end
