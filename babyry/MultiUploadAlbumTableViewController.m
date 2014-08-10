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
    NSLog(@"get from photo album.");
    _albumListArray = [[NSMutableArray alloc] init];
    _albumImageDic = [[NSMutableDictionary alloc] init];
    //NSMutableArray *assetsArray = [[NSMutableArray alloc] init];
    _library = [[ALAssetsLibrary alloc] init];
    [_library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [_albumListArray addObject:group];
            NSMutableArray *albumImageArray = [[NSMutableArray alloc] init];
            ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (result) {
                    [albumImageArray addObject:result];
                }
            };
            [group enumerateAssetsUsingBlock:assetsEnumerationBlock];
            [_albumImageDic setObject:albumImageArray forKey:[group valueForProperty:ALAssetsGroupPropertyName]];
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
    NSLog(@"album array count %d", [_albumListArray count]);
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
    NSLog(@"table cell index : %d", index);
    NSLog(@"album name %@", [[_albumListArray objectAtIndex:index] valueForProperty:ALAssetsGroupPropertyName]);
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumListTableViewCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"AlbumListTableViewCell"];
    }
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.text = [[_albumListArray objectAtIndex:index] valueForProperty:ALAssetsGroupPropertyName];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d枚", [[_albumImageDic objectForKey:cell.textLabel.text] count]];
    
    UIImage *tmpImage = [UIImage imageWithCGImage:[[[_albumImageDic objectForKey:cell.textLabel.text] lastObject] thumbnail]];
    cell.imageView.image = tmpImage;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int index = [indexPath indexAtPosition:[indexPath length] - 1];
    NSString *albumName = [[_albumListArray objectAtIndex:index] valueForProperty:ALAssetsGroupPropertyName];
    NSLog(@"selected, index : %d, album name : %@", index, albumName);
    
    MultiUploadPickerViewController *multiUploadPickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiUploadPickerViewController"];
    multiUploadPickerViewController.alAssetsArr = [_albumImageDic objectForKey:albumName];
    multiUploadPickerViewController.month = _month;
    multiUploadPickerViewController.childObjectId = _childObjectId;
    multiUploadPickerViewController.date = _date;
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
