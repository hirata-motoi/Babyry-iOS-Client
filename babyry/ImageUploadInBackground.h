//
//  ImageUploadInBackground.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

// Class Info
// 各ViewControllerにて画像をUploadすると、popViewControllerなどでそのViewControllerが消えてしまうと
// そのjobも途中で消えてしまう。
// そのため、画像をバックグラウンドで処理する時はこのClassを使用する事にする。
// 基本的にViewController(基底ViewController)にObserverを登録して、Observer経由で呼び出すこと。
// (ViewControllerから呼ぶ場合は直接読んでも良い)

#import <Foundation/Foundation.h>

@interface ImageUploadInBackground : NSObject

+ (void)setMultiUploadImageDataSet:(NSMutableDictionary *)property multiUploadImageDataArray:(NSMutableArray *)imageDataArray multiUploadImageDataTypeArray:(NSMutableArray *)imageDataTypeArray date:(NSString *)date indexPath:(NSIndexPath *)indexPath;
+ (int)numOfWillUploadImages;
+ (void)multiUploadToParseInBackground;

@end
