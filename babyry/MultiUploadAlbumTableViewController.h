//
//  MultiUploadAlbumTableViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Parse/Parse.h>

@interface MultiUploadAlbumTableViewController : UIViewController<UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property ALAssetsLibrary *library;
@property NSMutableArray *albumListArray;
@property NSMutableArray *albumImageAssetsArray;

@property UITableView *albumTableView;

@property NSString *childObjectId;
@property NSString *month;
@property NSString *date;
@property NSMutableArray *totalImageNum;
@property NSIndexPath *indexPath;
@property NSMutableDictionary *child;

@property BOOL accessAllowed;

@end
