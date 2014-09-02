//
//  MultiUploadAlbumTableViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "MultiUploadAlbumTableViewController.h"
#import "MultiUploadPickerViewController.h"
#import "Navigation.h"

@interface MultiUploadAlbumTableViewController ()

@end

@implementation MultiUploadAlbumTableViewController

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
    
    // フォトアルバムからリスト取得しておく
    _albumListArray = [[NSMutableArray alloc] init];
    _albumImageAssetsArray = [[NSMutableArray alloc] init];
    _library = [[ALAssetsLibrary alloc] init];

    [_library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            [_albumListArray addObject:group];
        } else if (!group) {
            [_library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                if (group && [[group valueForProperty:ALAssetsGroupPropertyType] intValue] != 16) {
                    [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                    [_albumListArray addObject:group];
                } else if (!group) {
                    for (ALAssetsGroup *group in _albumListArray) {
                        NSMutableArray *albumImageArray = [[NSMutableArray alloc] init];
                        ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                            if (result) {
                                [albumImageArray addObject:result];
                            }
                        };
                        [group enumerateAssetsUsingBlock:assetsEnumerationBlock];
                        if ([albumImageArray count] > 0) {
                            [_albumImageAssetsArray addObject:albumImageArray];
                        } else {
                            // アルバムの中に画像が0枚なので表示しない
                            [_albumListArray removeObject:group];
                        }
                    }
                    
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

    _albumTableView = [[UITableView alloc] init];
    _albumTableView.delegate = self;
    _albumTableView.dataSource = self;
    _albumTableView.backgroundColor = [UIColor whiteColor];
    CGRect frame = self.view.frame;
    frame.origin.y += 64;
    frame.size.height -= 64;
    _albumTableView.frame = frame;
    [self.view addSubview:_albumTableView];
}

/////////////////////////////////////////////////////////////////
// アルバム一覧のtableviewようのメソッド
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_albumListArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO : ハードコード！！！
    return 70.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int index = [indexPath indexAtPosition:[indexPath length] - 1];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumListTableViewCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"AlbumListTableViewCell"];
    }
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.text = [[_albumListArray objectAtIndex:index] valueForProperty:ALAssetsGroupPropertyName];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d枚", [[_albumImageAssetsArray objectAtIndex:index] count]];
    
    UIImage *tmpImage = [UIImage imageWithCGImage:[[[_albumImageAssetsArray objectAtIndex:index] lastObject] thumbnail]];
    cell.imageView.image = tmpImage;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int index = [indexPath indexAtPosition:[indexPath length] - 1];
    
    MultiUploadPickerViewController *multiUploadPickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadPickerViewController"];
    multiUploadPickerViewController.alAssetsArr = [_albumImageAssetsArray objectAtIndex:index];
    multiUploadPickerViewController.month = _month;
    multiUploadPickerViewController.childObjectId = _childObjectId;
    multiUploadPickerViewController.date = _date;
    multiUploadPickerViewController.child = _child;
    if (_totalImageNum){
        multiUploadPickerViewController.totalImageNum = _totalImageNum;
        multiUploadPickerViewController.indexPath = _indexPath;
    }
    [self presentViewController:multiUploadPickerViewController animated:YES completion:NULL];
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
