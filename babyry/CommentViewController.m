//
//  CommentViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "CommentViewController.h"
#import "PageContentViewController.h"

@interface CommentViewController ()

@end

@implementation CommentViewController

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
    
    _commentTableView.delegate = self;
    _commentTableView.dataSource = self;
    
    // text field
    _commentTextField.delegate = self;
    _commentTextField.borderStyle = UITextBorderStyleRoundedRect;
    _commentTextField.layer.borderColor = [[UIColor blackColor] CGColor];
    _commentTextField.layer.borderWidth = 1;
    [self getCommentFromParse];
    
    [self.closeCommentViewButton addTarget:self action:@selector(closeCommentView) forControlEvents:UIControlEventTouchUpInside];
    [self.submitCommentButton addTarget:self action:@selector(submitComment) forControlEvents:UIControlEventTouchUpInside];
    [self hideKeyBoardOnUnforcusingTextForm];
    
    NSLog(@"keyboardObserving %hhd", _keyboardObserving);
    
    // viewWillAppearが呼ばれないことがあるので、ここにもobservingを書いておく
    if (!_keyboardObserving) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [center addObserver:self selector:@selector(keybaordWillHide:) name:UIKeyboardWillHideNotification object:nil];
        _keyboardObserving = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"comment viewWillAppear");
    [super viewWillAppear:animated];
    
    NSLog(@"comment viewWillAppear");
    // Start observing
    if (!_keyboardObserving) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [center addObserver:self selector:@selector(keybaordWillHide:) name:UIKeyboardWillHideNotification object:nil];
        _keyboardObserving = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    // super
    [super viewWillDisappear:animated];
    
    // Stop observing
    if (_keyboardObserving) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        _keyboardObserving = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)getCommentFromParse
{
    NSLog(@"getCommentFromParse month:%@ date:%@ childObjectId:%@", _month, _date, _childObjectId);
    PFQuery *commentQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"DailyComment%@", _month]];
    [commentQuery whereKey:@"childId" equalTo:_childObjectId];
    [commentQuery whereKey:@"date" equalTo:[NSString stringWithFormat:@"D%@", _date]];
    [commentQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error) {
            _commentArray = objects;
            if ([_commentArray count] > 0) {
                [_commentTableView reloadData];
                if ([_commentArray count] > 0) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_commentArray count]-1 inSection:0];
                    [_commentTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                }
            }
        }
    }];
}

- (void)closeCommentView
{
    self.view.hidden = YES;
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
    // ニックネーム取得 (ニックネームはかわることがあるのでいちいちクエリ発行 (ただし、キャッシュ優先))
    PFQuery *nickQuery = [PFQuery queryWithClassName:@"_User"];
    [nickQuery whereKey:@"userId" equalTo:[_commentArray objectAtIndex:indexPath.row][@"commentBy"]];
    nickQuery.cachePolicy = kPFCachePolicyCacheElseNetwork;
    PFObject *nickObject = [nickQuery getFirstObject];
    cell.textLabel.text = [NSString stringWithFormat:@"%@のコメント\n%@", nickObject[@"nickName"], [_commentArray objectAtIndex:indexPath.row][@"comment"]];
    
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
    CGSize size = [cell.textLabel.text
                   boundingRectWithSize:bounds
                   options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                   attributes:[NSDictionary dictionaryWithObject:cell.textLabel.font forKey:NSFontAttributeName]
                   context:nil].size;
    
    return size.height;
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    NSLog(@"keyboardWillShow");
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    // Calc overlap of keyboardFrame and textViewFrame
    CGRect keyboardFrame;
    CGRect textViewFrame;
    keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view.superview convertRect:keyboardFrame fromView:nil];
    textViewFrame = self.view.frame;
    float overlap;
    overlap = MAX(0.0f, CGRectGetMaxY(textViewFrame) - CGRectGetMinY(keyboardFrame));
    NSLog(@"overlap %f", overlap);
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    NSLog(@"%@", NSStringFromCGRect(_commentTextField.frame));
    
    animations = ^(void) {
        CGPoint scrollViewPoint = _commentScrollView.contentOffset;
        scrollViewPoint.y = overlap;
        [_commentScrollView setContentOffset:scrollViewPoint animated:YES];
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
    
}

- (void)keybaordWillHide:(NSNotification*)notification
{
    NSLog(@"keyboardWillHide");
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    CGRect textViewFrame;
    textViewFrame = self.view.frame;
    float overlap;
    overlap = MAX(0.0f, CGRectGetMaxY(_defaultCommentViewRect) - CGRectGetMaxY(textViewFrame));
    NSLog(@"overlap %f", overlap);
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
        CGPoint scrollViewPoint = _commentScrollView.contentOffset;
        scrollViewPoint.y = 0;
        [_commentScrollView setContentOffset:scrollViewPoint animated:YES];
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

- (void) hideKeyBoardOnUnforcusingTextForm
{
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [_commentTableView addGestureRecognizer:singleTapGestureRecognizer];
}

-(void)hideKeyBoard:(id) sender
{
    [self.view endEditing:YES];
}

- (void)submitComment
{
    NSLog(@"Send Comment");
    NSLog(@"%@", _commentTextField.text);
    
    if (!_commentTextField.text || ![_commentTextField.text isEqualToString:@""]) {
        // Insert To Parse
        PFObject *dailyComment = [PFObject objectWithClassName:[NSString stringWithFormat:@"DailyComment%@", _month]];
        dailyComment[@"comment"] = _commentTextField.text;
        // D(文字)つけないとwhere句のfieldに指定出来ないので付ける
        dailyComment[@"date"] = [NSString stringWithFormat:@"D%@", _date];
        dailyComment[@"childId"] = _childObjectId;
        dailyComment[@"commentBy"] = [PFUser currentUser][@"userId"];
        // Parseに突っ込む前にViewだけ更新
        _commentArray = [_commentArray arrayByAddingObject:dailyComment];
        [_commentTableView reloadData];
        if ([_commentArray count] > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_commentArray count]-1 inSection:0];
            [_commentTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
        [dailyComment saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
            if(success) {
                [self getCommentFromParse];
                [_commentTableView endUpdates];
                NSLog(@"end update");
                [_commentTableView reloadData];
                NSLog(@"reload data");
            }
        }];
        _commentTextField.text = @"";
    }
    [self.view endEditing:YES];
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
