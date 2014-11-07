//
//  AlbumTableViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AlbumTableViewController.h"
#import "AlbumPickerViewController.h"
#import "Navigation.h"

@interface AlbumTableViewController ()

@end

@implementation AlbumTableViewController
{
    ALAssetsLibrary *library;
    NSMutableArray *albumListArray;
    NSMutableArray *albumImageAssetsArray;
    UITableView *albumTableView;
    BOOL accessAllowed;
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
    
    [Navigation setTitle:self.navigationItem withTitle:@"アルバム一覧" withSubtitle:nil withFont:nil withFontSize:0 withColor:nil];
    
    accessAllowed = NO;
    
    // フォトアルバムからリスト取得しておく
    NSMutableArray *albumListAll = [[NSMutableArray alloc]init];
    
    albumListArray = [[NSMutableArray alloc] init];
    albumImageAssetsArray = [[NSMutableArray alloc] init];
    library = [[ALAssetsLibrary alloc] init];
    
    if (![self isPhotoAccessEnableWithIsShowAlert:YES]) {
        return;
    }
    
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            [albumListAll addObject:group];
        } else if (!group) {
            [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                if (group && [[group valueForProperty:ALAssetsGroupPropertyType] intValue] != 16) {
                    [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                    [albumListAll addObject:group];
                } else if (!group) {
                    for (ALAssetsGroup *group in albumListAll) {
                        NSMutableArray *albumImageArray = [[NSMutableArray alloc] init];
                        ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                            if (result) {
                                [albumImageArray addObject:result];
                            }
                        };
                        [group enumerateAssetsUsingBlock:assetsEnumerationBlock];
                        if ([albumImageArray count] > 0) {
                            [albumImageAssetsArray addObject:albumImageArray];
                            [albumListArray addObject:group];
                        }
                    }
                    [self createAlbumTable];
                    accessAllowed = YES;
                }
            } failureBlock:nil];
        }
    } failureBlock:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (accessAllowed) {
        [self createAlbumTable];
    }
}

- (void) createAlbumTable
{
    albumTableView = [[UITableView alloc] init];
    albumTableView.delegate = self;
    albumTableView.dataSource = self;
    albumTableView.backgroundColor = [UIColor whiteColor];
    CGRect frame = self.view.frame;
    frame.origin.y += 64;
    frame.size.height -= 64;
    albumTableView.frame = frame;
    [self.view addSubview:albumTableView];
}

/////////////////////////////////////////////////////////////////
// アルバム一覧のtableviewようのメソッド
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [albumListArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO : ハードコード！！！
    return 70.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = [indexPath indexAtPosition:[indexPath length] - 1];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumListTableViewCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"AlbumListTableViewCell"];
    }
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.text = [[albumListArray objectAtIndex:index] valueForProperty:ALAssetsGroupPropertyName];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d枚", [[albumImageAssetsArray objectAtIndex:index] count]];
    
    UIImage *tmpImage = [UIImage imageWithCGImage:[[[albumImageAssetsArray objectAtIndex:index] lastObject] thumbnail]];
    cell.imageView.image = tmpImage;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = [indexPath indexAtPosition:[indexPath length] - 1];
    
    AlbumPickerViewController *albumPickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumPickerViewController"];
    albumPickerViewController.alAssetsArr = [albumImageAssetsArray objectAtIndex:index];
    albumPickerViewController.month = _month;
    albumPickerViewController.childObjectId = _childObjectId;
    albumPickerViewController.date = _date;
    albumPickerViewController.notificationHistoryByDay = _notificationHistoryByDay;
    albumPickerViewController.uploadType = _uploadType;
    if (_totalImageNum){
        albumPickerViewController.totalImageNum = _totalImageNum;
        albumPickerViewController.indexPath = _indexPath;
    }
    if ([_uploadType isEqualToString:@"single"]) {
        albumPickerViewController.section = _section;
        albumPickerViewController.uploadViewController = _uploadViewController;
    }
    [self presentViewController:albumPickerViewController animated:YES completion:NULL];
}

// このアプリの写真への認証状態を取得する
- (BOOL)isPhotoAccessEnableWithIsShowAlert:(BOOL)_isShowAlert {
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    
    BOOL isAuthorization = NO;
    
    switch (status) {
        case ALAuthorizationStatusAuthorized: // 写真へのアクセスが許可されている
            isAuthorization = YES;
            break;
        case ALAuthorizationStatusNotDetermined: // 写真へのアクセスを許可するか選択されていない
            isAuthorization = YES; // 許可されるかわからないがYESにしておく
            break;
        case ALAuthorizationStatusRestricted: // 設定 > 一般 > 機能制限で利用が制限されている
        {
            isAuthorization = NO;
            if (_isShowAlert) {
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@"エラー"
                                          message:@"写真へのアクセスが許可されていません。\n設定 > 一般 > 機能制限で許可してください。"
                                          delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                [alertView show];
            }
        }
            break;
            
        case ALAuthorizationStatusDenied: // 設定 > プライバシー > 写真で利用が制限されている
        {
            isAuthorization = NO;
            if (_isShowAlert) {
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@"エラー"
                                          message:@"写真へのアクセスが許可されていません。\n設定 > プライバシー > 写真で許可してください。"
                                          delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                [alertView show];
            }
        }
            break;
            
        default:
            break;
    }
    return isAuthorization;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end

