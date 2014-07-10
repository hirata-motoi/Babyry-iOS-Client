//
//  UploadViewController.m
//  babyrydev
//
//  Created by kenjiszk on 2014/06/04.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "UploadViewController.h"
#import "PageContentViewController.h"
#import "ImageCache.h"
#import "ViewController.h"
#import "ImageTrimming.h"

@interface UploadViewController ()

@end

@implementation UploadViewController

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
    
    // disable commentTableView
    _commentView.hidden = YES;
    
    float imageViewAspect = _uploadedImageView.frame.size.width/_uploadedImageView.frame.size.height;
    float imageAspect = _uploadedImage.size.width/_uploadedImage.size.height;
    
    // 横長バージョン
    // 枠より、画像の方が横長、枠の縦を縮める
    if (imageAspect >= imageViewAspect){
        CGRect frame = _uploadedImageView.frame;
        frame.size.height = frame.size.width/imageAspect;
        _uploadedImageView.frame = frame;
    // 縦長バージョン
    // 枠より、画像の方が縦長、枠の横を縮める
    } else {
        CGRect frame = _uploadedImageView.frame;
        frame.size.width = frame.size.height*imageAspect;
        _uploadedImageView.frame = frame;
    }
    
    // set uploadedImage
    CGRect frame = _uploadedImageView.frame;
    frame.origin.x = (self.view.frame.size.width - _uploadedImageView.frame.size.width)/2;
    frame.origin.y = (self.view.frame.size.height - _uploadedImageView.frame.size.height)/2;
    _uploadedImageView.frame = frame;
    _uploadedImageView.image = _uploadedImage;
    
    // set label
    NSString *yyyy = [_month substringToIndex:4];
    NSString *mm = [_month substringWithRange:NSMakeRange(4, 2)];
    NSString *dd = [_date substringWithRange:NSMakeRange(6, 2)];
    _uploadMonthLabel.text = [NSString stringWithFormat:@"%@/%@", yyyy, mm];
    _uploadDateLabel.text = [NSString stringWithFormat:@"%@", dd];
    _uploadNameLabel.text = _name;
    
    // set button shape
    _openPhotoLibraryLabel.layer.cornerRadius = _openPhotoLibraryLabel.frame.size.height/2;
    _uploadViewBackLabel.layer.cornerRadius = _uploadViewBackLabel.frame.size.height/2;
    _uploadViewCommentLabel.layer.cornerRadius = _uploadViewCommentLabel.frame.size.height/2;
    
    // get pageIndex, imageIndex
    NSLog(@"received childObjectId:%@ month:%@ date:%@ image:%@", _childObjectId, _month, _date, _uploadedImageView.image);
    
    // UICollectionViewの土台を作成
    _commentTableView.delegate = self;
    _commentTableView.dataSource = self;
    
    _cellHeightArray = [[NSMutableArray alloc] init];
    
    // text field
    _commentTextField.delegate = self;
    _commentTextField.layer.borderColor = [[UIColor blackColor] CGColor];
    _commentTextField.layer.borderWidth = 1;
    
    _defaultCommentViewRect = _commentView.frame;
    
    [_commentSendButton addTarget:self action:@selector(sendComment:) forControlEvents:UIControlEventTouchDown];
    
    // getcomment
    //_commentArray = [[NSArray alloc] init];
    [self getCommentFromParse];
    
    // Parseからちゃんとしたサイズの画像を取得
    PFQuery *originalImageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
    originalImageQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [originalImageQuery whereKey:@"imageOf" equalTo:_childObjectId];
    [originalImageQuery whereKey:@"bestFlag" equalTo:@"choosed"];
    [originalImageQuery whereKey:@"date" equalTo:[NSString stringWithFormat:@"D%@", _date]];
    [originalImageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ([objects count] > 0) {
            PFObject * object = [objects objectAtIndex:0];
            [object[@"imageFile"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error){
                if(!error){
                    _uploadedImageView.image = [UIImage imageWithData:data];
                }
            }];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    // super
    [super viewWillAppear:animated];
    
    // Start observing
    if (!_keyboradObserving) {
        NSNotificationCenter *center;
        center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [center addObserver:self selector:@selector(keybaordWillHide:) name:UIKeyboardWillHideNotification object:nil];
        _keyboradObserving = YES;
    }
    
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [_commentView addGestureRecognizer:singleTapGestureRecognizer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // super
    [super viewWillDisappear:animated];
    
    // Stop observing
    if (_keyboradObserving) {
        NSNotificationCenter *center;
        center = [NSNotificationCenter defaultCenter];
        [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        _keyboradObserving = NO;
    }
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

- (IBAction)openPhotoLibrary:(UIButton *)sender {
// インタフェース使用可能なら
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
	{
        // UIImageControllerの初期化
		UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
		[imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
		[imagePickerController setAllowsEditing:NO];
		[imagePickerController setDelegate:self];
		
        [self presentViewController:imagePickerController animated:YES completion: nil];
	}
	else
	{
		NSLog(@"photo library invalid.");
	}
}

- (IBAction)uploadViewBackButton:(UIButton *)sender {

    // このロジックはすごい微妙！！！！
    // album viewから戻るときはaddSubviewしているから自分と親(pageview)をけす
    // (TODO : 本当はPageViewControllerかどうかを判定する必要ある)
    // topから個別画面にいったときに戻るなら、dismissviewcontroler実行
    if(self.parentViewController) {
        [self.view removeFromSuperview];
        [self.parentViewController.view removeFromSuperview];
    } else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (IBAction)uploadViewCommentButton:(UIButton *)sender {
    //NSLog(@"comment");
    if (_commentView.hidden == YES) {
        _commentView.hidden = NO;
    } else {
        _commentView.hidden = YES;
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // 拡張子取得
    NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    NSString *fileExtension = [[assetURL path] pathExtension];
    
    // オリジナルイメージ取得
	UIImage *originalImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];

    // リサイズ
    UIImage *resizedImage = [ImageTrimming resizeImageForUpload:originalImage];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    // ImageViewにセット
    [self.uploadedImageView setImage:resizedImage];
    
    NSLog(@"Make PFFile");
    NSData *imageData = [[NSData alloc] init];
    // PNGは透過しないとだめなのでやる
    // その他はJPG
    // TODO 画像圧縮率
    if ([fileExtension isEqualToString:@"PNG"]) {
        imageData = UIImagePNGRepresentation(resizedImage);
    } else {
        imageData = UIImageJPEGRepresentation(resizedImage, 0.7f);
    }
    NSLog(@"resize %f %f", originalImage.size.width, resizedImage.size.width);

    PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@%@", _childObjectId, _date] data:imageData];
    
    // Parseに既に画像があるかどうかを確認
    PFQuery *imageQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
    [imageQuery whereKey:@"imageOf" equalTo:_childObjectId];
    [imageQuery whereKey:@"date" equalTo:[NSString stringWithFormat:@"D%@", _date]];
    [imageQuery whereKey:@"bestFlag" equalTo:@"choosed"];
    
    NSArray *imageArray = [imageQuery findObjects];
    // imageArrayが一つ以上あったら(objectId指定だから一つしか無いはずだけど)上書き
    if ([imageArray count] > 1) {
        NSLog(@"これはあり得ないエラー");
    } else if ([imageArray count] == 1) {
        //NSLog(@"image objectId%@", imageArray[0]);
        imageArray[0][@"imageFile"] = imageFile;
        //ほんとはいらないけど念のため
        imageArray[0][@"bestFlag"] = @"choosed";
        [imageArray[0] saveInBackground];
    // 一つもないなら新たに追加
    } else {
        NSLog(@"Insert To Parse");
        PFObject *childImage = [PFObject objectWithClassName:[NSString stringWithFormat:@"ChildImage%@", _month]];
        childImage[@"imageFile"] = imageFile;
        // D(文字)つけないとwhere句のfieldに指定出来ないので付ける
        childImage[@"date"] = [NSString stringWithFormat:@"D%@", _date];
        childImage[@"imageOf"] = _childObjectId;
        childImage[@"bestFlag"] = @"choosed";
        [childImage saveInBackground];
    }
    
    // Cache set use thumbnail (フォトライブラリにあるやつは正方形になってるし使わない)
    UIImage *thumbImage = [ImageCache makeThumbNail:resizedImage];
    [ImageCache setCache:[NSString stringWithFormat:@"%@%@thumb", _childObjectId, _date] image:UIImageJPEGRepresentation(thumbImage, 0.7f)];
    
    // topのviewに設定する
    // このやり方でいいのかは不明 (MultiUploadViewControllerと同じ処理、ここなおすならそっちも直す)
    ViewController *pvc = (ViewController *)[self presentingViewController];
    if (pvc) {
        int childIndex = pvc.currentPageIndex;
        for (int i = 0; i < [[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"date"] count]; i++){
            if ([[[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"date"] objectAtIndex:i] isEqualToString:_date]) {
                //NSLog(@"%@",[[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"date"] objectAtIndex:i]);
                //NSLog(@"%@",[[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"thumbImages"] objectAtIndex:i]);
                [[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"thumbImages"] replaceObjectAtIndex:i withObject:thumbImage];
                //NSLog(@"%@",[[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"orgImages"] objectAtIndex:i]);
                [[[pvc.childArray objectAtIndex:childIndex] objectForKey:@"orgImages"] replaceObjectAtIndex:i withObject:resizedImage];
            }
        }
    }
    
    NSLog(@"saved");
}

// tableViewにいくつセクションがあるか。明記しない場合は1つ
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //NSLog(@"numberOfSectionsInTableView");
    return 1;
}

// section目のセクションにいくつ行があるかを返す
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //NSLog(@"numberOfRowsInSection %d", [_commentArray count]);
    return [_commentArray count];
}

// indexPathの位置にあるセルを返す
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"cellForRowAtIndexPath");
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text = [NSString stringWithFormat:@"%@のコメント\n%@", [_commentArray objectAtIndex:indexPath.row][@"commentBy"], [_commentArray objectAtIndex:indexPath.row][@"comment"]];

    return cell;
}

// セルの高さをtextの高さに合わせる
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"heightForRowAtIndexPath");
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.textLabel.numberOfLines = 0;
    // 調整のために改行いくつか入れる
    cell.textLabel.text = [NSString stringWithFormat:@"\n%@\n\n", [_commentArray objectAtIndex:indexPath.row][@"comment"]];

    // get cell height
    CGSize bounds = CGSizeMake(tableView.frame.size.width, tableView.frame.size.height);
    CGSize size = [cell.textLabel.text sizeWithFont:cell.textLabel.font constrainedToSize:bounds lineBreakMode:NSLineBreakByClipping];
    CGSize detailSize = [cell.detailTextLabel.text sizeWithFont: cell.detailTextLabel.font constrainedToSize: bounds lineBreakMode: NSLineBreakByCharWrapping];

    return size.height + detailSize.height;
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    //NSLog(@"keyboardWillShow");
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    // Calc overlap of keyboardFrame and textViewFrame
    CGRect keyboardFrame;
    CGRect textViewFrame;
    keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [_commentView.superview convertRect:keyboardFrame fromView:nil];
    textViewFrame = _commentView.frame;
    float overlap;
    overlap = MAX(0.0f, CGRectGetMaxY(textViewFrame) - CGRectGetMinY(keyboardFrame));
    //NSLog(@"overlap %f", overlap);
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
        CGRect viewFrame = _commentView.frame;
        viewFrame.size.height -= overlap;
        _commentView.frame = viewFrame;
    
        CGRect fieldFrame = _commentTextField.frame;
        fieldFrame.origin.y -= overlap;
        _commentTextField.frame = fieldFrame;

        CGRect buttonFrame = _commentSendButton.frame;
        buttonFrame.origin.y -= overlap;
        _commentSendButton.frame = buttonFrame;
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];

}

- (void)keybaordWillHide:(NSNotification*)notification
{
    //NSLog(@"keyboardWillHide");
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];

    CGRect textViewFrame;
    textViewFrame = _commentView.frame;
    float overlap;
    overlap = MAX(0.0f, CGRectGetMaxY(_defaultCommentViewRect) - CGRectGetMaxY(textViewFrame));
    NSLog(@"overlap %f", overlap);

    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
        CGRect viewFrame = _commentView.frame;
        viewFrame.size.height += overlap;
        _commentView.frame = viewFrame;
    
        CGRect fieldFrame = _commentTextField.frame;
        fieldFrame.origin.y += overlap;
        _commentTextField.frame = fieldFrame;

        CGRect buttonFrame = _commentSendButton.frame;
        buttonFrame.origin.y += overlap;
        _commentSendButton.frame = buttonFrame;
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

-(void)handleSingleTap:(id) sender
{
    [self.view endEditing:YES];
}

-(void)sendComment:(id)selector
{
    NSLog(@"Send Comment");
    NSLog(@"%@", _commentTextField.text);
    
    // Insert To Parse
    PFObject *dailyComment = [PFObject objectWithClassName:[NSString stringWithFormat:@"DailyComment%@", _month]];
    dailyComment[@"comment"] = _commentTextField.text;
    // D(文字)つけないとwhere句のfieldに指定出来ないので付ける
    dailyComment[@"date"] = [NSString stringWithFormat:@"D%@", _date];
    dailyComment[@"childId"] = _childObjectId;
    dailyComment[@"commentBy"] = [PFUser currentUser].objectId;
    [dailyComment saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        if(success) {
            [self getCommentFromParse];
/*            // TODP : Parseにとりにいかなくてもクライアント側で表示したい（なんかうまく行ってない）
            [_commentTableView beginUpdates];
            NSLog(@"beginUpdated");
            //NSMutableArray *items = [[NSMutableArray alloc] init];
            //[items addObject:@"ADD CEL"];
            NSIndexPath * path = [NSIndexPath indexPathForRow:[_commentArray count] inSection:0];
            NSLog(@"path set");
            _commentArray = [_commentArray arrayByAddingObject:@"ADD CELL"];
            NSLog(@"commentArray set");
            [_commentTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationBottom];
            NSLog(@"comment table view set");


            [_commentTableView endUpdates];
            NSLog(@"end update");
            [_commentTableView reloadData];
            NSLog(@"reload data");
            //NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_commentArray count]-1 inSection:0];
            //[_commentTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];*/
        }
    }];
    _commentTextField.text = @"";
    [self.view endEditing:YES];
}

-(void)getCommentFromParse
{
    PFQuery *commentQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"DailyComment%@", _month]];
    [commentQuery whereKey:@"childId" equalTo:_childObjectId];
    [commentQuery whereKey:@"date" equalTo:[NSString stringWithFormat:@"D%@", _date]];
    [commentQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error) {
            _commentArray = objects;
            if ([_commentArray count] > 0) {
                [_commentTableView reloadData];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_commentArray count]-1 inSection:0];
                [_commentTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        }
    }];
}

@end
