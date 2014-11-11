//
//  ChildFilterViewController.m
//  babyry
//
//  Created by hirata.motoi on 2014/11/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ChildFilterViewController.h"
#import "ChildFilterListCell.h"
#import "Logger.h"
#import "AWSCommon.h"
#import "Config.h"
#import "ImageCache.h"
#import "ImageTrimming.h"

@interface ChildFilterViewController ()

@end

@implementation ChildFilterViewController {
    NSMutableDictionary *lastImageByChild;
}
@synthesize delegate = _delegate;

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
    
    _childListTable.delegate = self;
    _childListTable.dataSource = self;
    
    UINib *nib = [UINib nibWithNibName:@"ChildFilterListCell" bundle:nil];
    [_childListTable registerNib:nib forCellReuseIdentifier:@"Cell"];
    
    self.backgroundView.layer.cornerRadius = 5.0f;
    self.childListTable.layer.cornerRadius = 5.0f;
    
    [self setupButtons];
    [self setupLastImage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)submit
{
    NSMutableDictionary *childFamilyMap = [[NSMutableDictionary alloc]init];
    for (NSMutableDictionary *section in _childList) {
        for (NSMutableDictionary *child in section[@"childList"]) {
            // selectedのこどもは自分のfamilyIdを、selectedでないこどもは空にする
            childFamilyMap[child[@"childObjectId"]]
                = ([child[@"selected"] isEqualToNumber:[NSNumber numberWithBool:YES]]) ? [PFUser currentUser][@"familyId"] : @"";
        }
    }
    
    if ([self validateChildCount:childFamilyMap]) {
        return;
    }
                             
    [_delegate executeAdmit:_indexNumber withChildFamilyMap:childFamilyMap];
}

- (void)refreshChildListTable:(NSMutableArray *)childList
{
    _childList = childList;
    [_childListTable reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_childList[section][@"childList"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    // 再利用できるセルがあれば再利用する
    ChildFilterListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (!cell) {
        // 再利用できない場合は新規で作成
        cell = [[ChildFilterListCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
    }
    
    NSMutableDictionary *childInfo = _childList[indexPath.section][@"childList"][indexPath.row];
    cell.delegate = self;            
    cell.indexPath = indexPath;
    cell.childNameLabel.text = childInfo[@"name"];
    cell.childNameLabel.font = [UIFont systemFontOfSize:18];
    cell.childNameLabel.numberOfLines = 0;
    cell.imageCountLabel.text = [NSString stringWithFormat:@"%ld枚アップ済", (long)[childInfo[@"imageCount"] integerValue]];
    cell.lastImageView.image = (lastImageByChild[childInfo[@"childObjectId"]]) ? lastImageByChild[childInfo[@"childObjectId"]] : [UIImage imageNamed:@"photoReverse"];
    cell.lastImageView.layer.cornerRadius = 3.0f;
    cell.lastImageView.layer.borderWidth = 1.0f;
    cell.lastImageView.layer.masksToBounds = YES;
    cell.lastImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    CGSize bounds = CGSizeMake(cell.childNameLabel.frame.size.width, tableView.frame.size.height);
    CGSize sizeEmailLabel = [cell.childNameLabel.text
                   boundingRectWithSize:bounds
                   options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                   attributes:[NSDictionary dictionaryWithObject:cell.childNameLabel.font forKey:NSFontAttributeName]
                   context:nil].size;
    
    CGRect rect = cell.childNameLabel.frame;
    rect.size.height = sizeEmailLabel.height;
    cell.childNameLabel.frame = rect;
    
    // デフォルトでチェックマークつける
    cell.selectSwitch.on = YES;
    return cell;
};

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _childList.count;
}

// セルの高さをtextの高さに合わせる
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChildFilterListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.childNameLabel.text = _childList[indexPath.section][@"childList"][indexPath.row][@"name"];
    cell.childNameLabel.font = [UIFont systemFontOfSize:18];
    
    // get cell height
    cell.childNameLabel.numberOfLines = 0;
    CGSize bounds = CGSizeMake(cell.childNameLabel.frame.size.width, tableView.frame.size.height);
    CGSize sizeEmailLabel = [cell.childNameLabel.text
                              boundingRectWithSize:bounds
                              options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                              attributes:[NSDictionary dictionaryWithObject:cell.childNameLabel.font forKey:NSFontAttributeName]
                              context:nil].size;
    
    return sizeEmailLabel.height + 30; // 余白30
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _childList[section][@"nameOfCreatedBy"];
}

// iOS7以降ではsection headerに含まれるアルファベットが大文字に変換されてしまうので
// 表示直前に上書きする
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *sectionHeader = (UITableViewHeaderFooterView *)view;
        sectionHeader.textLabel.text = _childList[section][@"nameOfCreatedBy"];
    }
}

- (BOOL)switchSelected:(BOOL)selected withIndexPath:(NSIndexPath *)indexPath
{
    _childList[indexPath.section][@"childList"][indexPath.row][@"selected"] = [NSNumber numberWithBool:selected];
    
    if ([self hasNoChild]) {
        _childList[indexPath.section][@"childList"][indexPath.row][@"selected"] = [NSNumber numberWithBool:!selected];
        [self showNoChildAlert];
        return NO;
    }
    
    return YES;
}

- (BOOL)hasNoChild
{
    for (NSMutableDictionary *section in _childList) {
        for (NSMutableDictionary *child in section[@"childList"]) {
            if ([child[@"selected"] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
                return NO;
            }
        }
    }
    return YES;
}

- (void)setupButtons
{
    [self setupCloseButton];
    [self setupSubmitButton];
}

- (void)setupCloseButton
{
    UITapGestureRecognizer *closeGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(close)];
    closeGesture.numberOfTapsRequired = 1;
    _closeButton.userInteractionEnabled = YES;
    [_closeButton addGestureRecognizer:closeGesture];
}

- (void)close
{
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (void)setupSubmitButton
{
    UITapGestureRecognizer *submitGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(submit)];
    submitGesture.numberOfTapsRequired = 1;
    [_submitButton addGestureRecognizer:submitGesture];
    _submitButton.layer.cornerRadius = 2.0f;
}

- (void)showNoChildAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"こどもを0人にすることはできません"
                                                    message:@""
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    [alert show];
}

- (BOOL)validateChildCount:(NSMutableDictionary *)childFamilyMap
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self != %@", @""];
    NSArray *selected = [[childFamilyMap allValues] filteredArrayUsingPredicate:predicate];
   
    if (selected.count <= 5) {
        return NO;
    }
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"選択できるこどもは5人までです"
                                                   message:@""
                                                  delegate:nil
                                         cancelButtonTitle:nil
                                         otherButtonTitles:@"OK", nil];
    [alert show];
    return YES;
}

// こども毎に写真(最新のもの)を一枚取得
- (void)setupLastImage
{
    if (!lastImageByChild) {
        lastImageByChild = [[NSMutableDictionary alloc]init];
    }
    
    for (NSMutableDictionary *section in _childList) {
        for (NSMutableDictionary *child in section[@"childList"]) {
            NSString *childObjectId = child[@"childObjectId"];
            NSInteger childImageShardIndex = (long)[child[@"childImageShardIndex"] integerValue];
            
            PFQuery *query = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%ld", (long)childImageShardIndex]];
            [query whereKey:@"imageOf" equalTo:childObjectId];
            [query whereKey:@"bestFlag" notEqualTo:@"removed"];
            [query orderByDescending:@"updatedAt"];
            query.limit = 1;
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (error) {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to get ChildImage child:%@ shardIndx:%ld error:%@", childObjectId, (long)childImageShardIndex, error]];
                    return;
                }
                
                if (objects.count < 1) {
                    return;
                }

                PFObject *childImage = objects[0];
                [self setImageData:childImage withChild:child];
            }];
        }
    }
}

- (void)setImageData:(PFObject *)childImage withChild:(NSMutableDictionary *)child
{
    NSString *childObjectId = child[@"childObjectId"];
    
    // キャッシュからデータを取得
    NSData *imageCacheData = [self getCachedImage:childImage];
    if (imageCacheData) {
        lastImageByChild[childObjectId] = [ImageTrimming makeRectTopImage:[UIImage imageWithData:imageCacheData] ratio:1.0f];
        [_childListTable reloadData];
        return;
    }
   
    AWSS3GetObjectRequest *request = [AWSS3GetObjectRequest new];
    request.bucket = [Config config][@"AWSBucketName"];
    request.key = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"ChildImage%ld", (long)[child[@"childImageShardIndex"] integerValue]], childImage.objectId];
    request.responseCacheControl = @"no-cache";
    AWSS3 *awsS3 = [[AWSS3 new] initWithConfiguration:[AWSCommon getAWSServiceConfiguration:@"S3"]];
    [[awsS3 getObject:request] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        if (!task.error && task.result) {
            AWSS3GetObjectOutput *result = (AWSS3GetObjectOutput *)task.result;
            UIImage *thumbImage = [ImageCache makeThumbNail:[UIImage imageWithData:result.body]];
            NSData *thumbData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(thumbImage, 0.7f)];
            lastImageByChild[childObjectId] = [ImageTrimming makeRectTopImage:[UIImage imageWithData:thumbData] ratio:1.0f];
            
            // 大したcell数がないので毎回reload
            [_childListTable reloadData];
        }
        return nil;
    }];
}

- (NSData *)getCachedImage: (PFObject *)childImage
{
    NSString *cacheDir = [NSString stringWithFormat:@"%@/candidate/%ld/thumbnail", childImage[@"imageOf"], (long)[childImage[@"date"] integerValue]];
    NSString *imageCachePath = [childImage[@"date"] stringValue];
    NSData *imageCacheData = [ImageCache getCache:imageCachePath dir:cacheDir];
    
    if (imageCacheData) {
        return imageCacheData;
    }
    
    cacheDir = [NSString stringWithFormat:@"%@/bestShot/%ld/thumbnail", childImage[@"imageOf"], (long)[childImage[@"date"] integerValue]];
    imageCachePath = childImage.objectId;
    imageCacheData = [ImageCache getCache:imageCachePath dir:cacheDir];
    
    return imageCacheData;
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
