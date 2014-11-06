//
//  AlbumPickerViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AlbumPickerViewController.h"
#import <Parse/Parse.h>
#import "NotificationHistory.h"
#import "MultiUploadViewController+Logic.h"
#import "ChildProperties.h"
#import "UploadPickerCollectionViewSectionHeader.h"
#import "AlbumPickerViewController+Multi.h"
#import "AlbumPickerViewController+Single.h"

@interface AlbumPickerViewController ()

@end

@implementation AlbumPickerViewController {
    AlbumPickerViewController_Multi *logicMulti;
    AlbumPickerViewController_Single *logicSingle;
    CGSize cellSize;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _childProperty = [ChildProperties getChildProperty:_childObjectId];
    cellSize = CGSizeMake(self.view.frame.size.width/4 -3, self.view.frame.size.width/4 -3);
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [_hud hide:YES];
    
    _albumImageCollectionView.delegate = self;
    _albumImageCollectionView.dataSource = self;
    [_albumImageCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"AlbumTableViewControllerCell"];
    
    _selectedImageCollectionView.delegate = self;
    _selectedImageCollectionView.dataSource = self;
    [_selectedImageCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"AlbumTableViewControllerSelectedCell"];
    
    _backLabel.layer.cornerRadius = 10;
    _backLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    _backLabel.layer.borderWidth = 2;
    
    _sendImageLabel.layer.cornerRadius = 10;
    _sendImageLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    _sendImageLabel.layer.borderWidth = 2;
    
    if ([_uploadType isEqualToString:@"multi"]) {
        logicMulti = [[AlbumPickerViewController_Multi alloc] init];
        logicMulti.albumPickerViewController = self;
    } else if ([_uploadType isEqualToString:@"single"]) {
        logicSingle = [[AlbumPickerViewController_Single alloc] init];
        logicSingle.albumPickerViewController = self;
    }
    
    [[self logic] logicViewDidLoad];
    [self setPickerWithScrollToDate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)logic
{
    return
    (logicMulti) ? logicMulti :
    (logicSingle) ? logicSingle : nil;
}

- (void) setPickerWithScrollToDate
{
    _sectionImageDic = [[NSMutableDictionary alloc] init];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps;
    _sectionDateByIndex = [[NSMutableArray alloc] init];
    for (ALAsset *asset in _alAssetsArr) {
        NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
        comps = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:assetDate];
        NSString *key = [NSString stringWithFormat:@"%04d/%02d/%02d", comps.year, comps.month, comps.day];
        if (!_sectionImageDic[key]) {
            _sectionImageDic[key] = [[NSMutableArray alloc] init];
            [_sectionDateByIndex addObject:key];
            _checkedImageFragDic[key] = [[NSMutableArray alloc] init];
        }
        [_sectionImageDic[key] addObject:asset];
        [_checkedImageFragDic[key] addObject:@"NO"];
    }
    [_albumImageCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"AlbumImageCollectionViewHeader"];
    
    // dateからscroll位置(indexPath)決定
    NSIndexPath *skipIndexPath;
    int sectionInt = 0;
    for (NSString *dateWithSlash in _sectionDateByIndex) {
        NSString *dateWithoutSlash = [dateWithSlash stringByReplacingOccurrencesOfString:@"/" withString:@""];
        skipIndexPath = [NSIndexPath indexPathForRow:0 inSection:sectionInt];
        if ([dateWithoutSlash intValue] >= [_date intValue]) {
            break;
        }
        sectionInt++;
    }
    [_albumImageCollectionView scrollToItemAtIndexPath:skipIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
}

// セルの数を指定するメソッド
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView.tag == 1) {
        return [_sectionImageDic[_sectionDateByIndex[section]] count];
    } else if (collectionView.tag == 2) {
        return [_checkedImageArray count];
    }
    return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (collectionView.tag == 1) {
        return [_sectionImageDic count];
    }
    return 1;
}

// セルの大きさを指定するメソッド
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return cellSize;
}

// 指定された場所のセルを作るメソッド
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag == 1) {
        //セルを再利用 or 再生成
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AlbumTableViewControllerCell" forIndexPath:indexPath];
        for (UIView *view in [cell subviews]) {
            [view removeFromSuperview];
        }
        
        // sectionからAssetを取得
        ALAsset *asset = _sectionImageDic[_sectionDateByIndex[indexPath.section]][indexPath.row];
        
        // 画像を貼付け
        cell.backgroundColor = [UIColor blueColor];
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:[asset thumbnail]]];
        
        // check icon
        UIImage *checkIcon = [UIImage imageNamed:@"ImageCheckIcon"];
        UIImageView *checkIconView = [[UIImageView alloc] initWithImage:checkIcon];
        CGRect frame = cell.frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        checkIconView.frame = frame;
        [cell addSubview:checkIconView];
        if ([_checkedImageFragDic[_sectionDateByIndex[indexPath.section]][indexPath.row] isEqualToString:@"NO"]) {
            checkIconView.hidden = YES;
        } else {
            checkIconView.hidden = NO;
        }
        
        // singleの場合はチェックアイコン自体が要らない
        if ([_uploadType isEqualToString:@"single"]) {
            checkIconView.hidden = YES;
        }
        
        return cell;
        
    } else if (collectionView.tag == 2) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AlbumTableViewControllerSelectedCell" forIndexPath:indexPath];
        for (UIView *view in [cell subviews]) {
            [view removeFromSuperview];
        }
        cell.backgroundColor = [UIColor blueColor];
        // _checkedImageArrayにはindexPathが入っているので、その画像を取り出す
        NSIndexPath *albumImageIndex = [_checkedImageArray objectAtIndex:indexPath.row];
        ALAsset *asset = _sectionImageDic[_sectionDateByIndex[albumImageIndex.section]][albumImageIndex.row];
        UIImage *img = [UIImage imageWithCGImage:[asset thumbnail]];
        cell.backgroundView = [[UIImageView alloc] initWithImage:img];
        
        return cell;
    }
    
    return nil;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag == 1) {
        if ([_uploadType isEqualToString:@"single"]) {
            [[self logic] logicSendImageButton:indexPath];
            return;
        }
        if([_checkedImageFragDic[_sectionDateByIndex[indexPath.section]][indexPath.row] isEqualToString:@"NO"]) {
            if ([_checkedImageArray count] >= _multiUploadMax) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"上限数を超えています"
                                                                message:[NSString stringWithFormat:@"一度にアップロードできる写真は%d枚です", _multiUploadMax]
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil
                                      ];
                [alert show];
                return;
            }
            [_checkedImageArray addObject:indexPath];
            [_checkedImageFragDic[_sectionDateByIndex[indexPath.section]] replaceObjectAtIndex:indexPath.row withObject:@"YES"];
        } else {
            [_checkedImageFragDic[_sectionDateByIndex[indexPath.section]] replaceObjectAtIndex:indexPath.row withObject:@"NO"];
            // checkedImageFragDicから抜く
            int i = 0;
            // forでまわしているときにremoveするとforがおかしくなるのでいったんremoveKeyに入れてあとでremoveする
            int removeKey = -1;
            for (NSIndexPath *index in _checkedImageArray) {
                if ([index isEqual:indexPath]) {
                    removeKey = i;
                }
                i++;
            }
            if (removeKey > -1) {
                [_checkedImageArray removeObjectAtIndex:removeKey];
            }
        }
        [_albumImageCollectionView reloadData];
        [_selectedImageCollectionView reloadData];
        
        // scroll to last
        NSInteger item = [self collectionView:_selectedImageCollectionView numberOfItemsInSection:0] - 1;
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:item inSection:0];
        if (item > 1) {
            [_selectedImageCollectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (collectionView.tag == 1) {
        return CGSizeMake(self.view.frame.size.width, 30);
    } else {
        return CGSizeMake(0, 0);
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag == 1) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"AlbumImageCollectionViewHeader" forIndexPath:indexPath];
        
        UploadPickerCollectionViewSectionHeader *header = [UploadPickerCollectionViewSectionHeader view];
        [header setDate:_sectionDateByIndex[indexPath.section]];
        
        [headerView addSubview:header];
        
        return headerView;
    } else if (collectionView.tag == 2) {
        return nil;
    }
    
    return nil;
}

- (IBAction)sendImageButton:(id)sender {
    [[self logic] logicSendImageButton];
}

- (void)disableNotificationHistory
{
    NSArray *targetTypes = [NSArray arrayWithObjects:@"requestPhoto", nil];
    for (NSString *type in targetTypes) {
        if (_notificationHistoryByDay && _notificationHistoryByDay[type]) {
            for (PFObject *notificationHistory in _notificationHistoryByDay[type]) {
                [NotificationHistory disableDisplayedNotificationsWithObject:notificationHistory];
            }
            [_notificationHistoryByDay[type] removeAllObjects];
        }
    }
}

- (IBAction)backButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
