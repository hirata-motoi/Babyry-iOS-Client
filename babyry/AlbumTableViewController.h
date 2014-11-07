//
//  AlbumTableViewController.h
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Parse/Parse.h>
#import "UploadViewController.h"

@interface AlbumTableViewController : UIViewController<UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property NSString *childObjectId;
@property NSString *month;
@property NSString *date;
@property NSMutableArray *totalImageNum;
@property NSIndexPath *indexPath;
@property NSMutableDictionary *notificationHistoryByDay;

@property NSMutableDictionary *section;
@property UploadViewController *uploadViewController;

@property NSString *uploadType;

@end
