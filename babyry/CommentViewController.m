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
    
    _commentTableView.dataSource = self;
    _commentTableView.delegate = self;
    
    // text field
    _commentTextField.delegate = self;
    _commentTextField.textColor = [UIColor whiteColor];
    _commentTextField.attributedPlaceholder = [self stringWithAttribute:@"コメントを追加"];
    
    [self getCommentFromParse];
    
    [self.closeCommentViewButton addTarget:self action:@selector(closeCommentView) forControlEvents:UIControlEventTouchUpInside];
    [self.commentSubmitButton addTarget:self action:@selector(submitComment) forControlEvents:UIControlEventTouchUpInside];
    [self hideKeyBoardOnUnforcusingTextForm];
    
    // viewWillAppearが呼ばれないことがあるので、ここにもobservingを書いておく
    if (!_keyboardObserving) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [center addObserver:self selector:@selector(keybaordWillHide:) name:UIKeyboardWillHideNotification object:nil];
        _keyboardObserving = YES;
    }
    
    UITapGestureRecognizer *commentViewContainerTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(blockGesture)];
    commentViewContainerTap.numberOfTapsRequired = 1;
    [_commentViewContainer addGestureRecognizer:commentViewContainerTap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Start observing
    if (!_keyboardObserving) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [center addObserver:self selector:@selector(keybaordWillHide:) name:UIKeyboardWillHideNotification object:nil];
        _keyboardObserving = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[_commentArray count] inSection:0];
    [_commentTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
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
    PFQuery *commentQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"DailyComment%@", _month]];
    [commentQuery whereKey:@"childId" equalTo:_childObjectId];
    [commentQuery whereKey:@"date" equalTo:[NSString stringWithFormat:@"D%@", _date]];
    [commentQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error) {
            _commentArray = objects;
            
            // まずcellの高さの合計を算出してtableViewの高さを合わせる
            // reloadDataが別スレッドの処理で、reloadDataの完了をキャッチできないため
            if ([_commentArray count] > 0) {
                [self reloadData];
                //[self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
               NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_commentArray count] inSection:0];
               [_commentTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            } else {
                [self reloadData];
            }
        }
    }];
}

- (void)closeCommentView
{
    [self hideKeyBoard];
    self.view.hidden = YES;
    self.uploadViewController.operationView.hidden = NO;
}

// tableViewにいくつセクションがあるか。明記しない場合は1つ
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// section目のセクションにいくつ行があるかを返す
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // 1 : コメント追加form
    return [_commentArray count] + 1;
}

// indexPathの位置にあるセルを返す
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    cell.textLabel.numberOfLines = 0;
    cell.backgroundColor = [UIColor clearColor];
    for (UIView *view in [cell.contentView subviews]) {
        if (view.tag == 8888 || view.tag == 9999) {
            view.hidden = YES; // コメント入力用formとボタンを隠す
        }
    }
    cell.textLabel.text = @"";
    cell.detailTextLabel.text = @"";
    
    // 最後のcellはコメント編集text field
    if (indexPath.row == [_commentArray count]) {
        cell.backgroundColor = [UIColor clearColor];
        
        UITableViewCell *commentEditCell = [_commentTableView cellForRowAtIndexPath:indexPath];
        _commentTextField.frame = CGRectMake(0, 0, 250, 30);
        _commentTextField.hidden = NO;
        _commentTextField.tag = 8888;
        [cell.contentView addSubview:_commentTextField];
        _commentSubmitButton.frame = CGRectMake(260, 10, 30, 20);
        _commentSubmitButton.hidden = YES;
        _commentSubmitButton.tag = 9999;
        [cell.contentView addSubview:_commentSubmitButton];
        
        [self adjustTableViewHeight];
        
        return cell;
    }
    
    if ([[_commentArray objectAtIndex:indexPath.row][@"commentBy"] isEqualToString:[PFUser currentUser][@"userId"]]) {
        [cell.textLabel setAttributedText:[self stringWithAttribute:[PFUser currentUser][@"nickName"]]];
    } else {
        // ニックネーム取得 (ニックネームはかわることがあるのでいちいちクエリ発行 (ただし、キャッシュ優先))
        PFQuery *nickQuery = [PFQuery queryWithClassName:@"_User"];
        [nickQuery whereKey:@"userId" equalTo:[_commentArray objectAtIndex:indexPath.row][@"commentBy"]];
        nickQuery.cachePolicy = kPFCachePolicyCacheElseNetwork;
        PFObject *nickObject = [nickQuery getFirstObject];
        [cell.textLabel setAttributedText:[self stringWithAttribute:nickObject[@"nickName"]]];
    }
    cell.detailTextLabel.text = [_commentArray objectAtIndex:indexPath.row][@"comment"];
    [cell.detailTextLabel setAttributedText:[self stringWithAttribute:[_commentArray objectAtIndex:indexPath.row][@"comment"]]];
    return cell;
}

// セルの高さをtextの高さに合わせる
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [_commentArray count]) {
        return _commentTextField.frame.size.height;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    cell.textLabel.numberOfLines = 0;
    

    cell.textLabel.text = @"nickName"; // dummy
    cell.detailTextLabel.text = [_commentArray objectAtIndex:indexPath.row][@"comment"];
    
    // get cell height
    CGSize bounds = CGSizeMake(tableView.frame.size.width, tableView.frame.size.height);
    CGSize size = [cell.textLabel.text
                   boundingRectWithSize:bounds
                   options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                   attributes:[NSDictionary dictionaryWithObject:cell.textLabel.font forKey:NSFontAttributeName]
                   context:nil].size;
    CGSize detailSize = [cell.detailTextLabel.text
                   boundingRectWithSize:bounds
                   options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                   attributes:[NSDictionary dictionaryWithObject:cell.textLabel.font forKey:NSFontAttributeName]
                   context:nil].size;
    
    return size.height + detailSize.height;
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    _commentSubmitButton.hidden = NO;
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    // Calc overlap of keyboardFrame and textViewFrame
    CGRect keyboardFrame;
    keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view.superview convertRect:keyboardFrame fromView:nil];
    float originY = MAX(0.0f, self.view.frame.size.height - keyboardFrame.size.height - _commentTableContainer.frame.size.height);

    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    animations = ^(void) {
        CGRect rect = _commentTableContainer.frame;
        rect.origin.y = originY;
        _commentTableContainer.frame = rect;
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

- (void)keybaordWillHide:(NSNotification*)notification
{
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];

    float originY = MAX(0.0f, self.view.frame.size.height - _commentTableContainer.frame.size.height);
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    void (^animations)(void);
    duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animations = ^(void) {
        CGRect rect = _commentTableContainer.frame;
        rect.origin.y = originY;
        _commentTableContainer.frame = rect;
    };
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:animations completion:nil];
}

- (void) hideKeyBoardOnUnforcusingTextForm
{
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [_commentTableView
     addGestureRecognizer:singleTapGestureRecognizer];
}

-(void)hideKeyBoard
{
    NSLog(@"hideKeyBoard");
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_commentArray count] inSection:0];
    [_commentTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    [self.view endEditing:YES];
}

- (void)submitComment
{
    
    if ( _commentTextField && ![_commentTextField.text isEqualToString:@""] ) {
        // Insert To Parse
        PFObject *dailyComment = [PFObject objectWithClassName:[NSString stringWithFormat:@"DailyComment%@", _month]];
        dailyComment[@"comment"] = _commentTextField.text;
        // D(文字)つけないとwhere句のfieldに指定出来ないので付ける
        dailyComment[@"date"] = [NSString stringWithFormat:@"D%@", _date];
        dailyComment[@"childId"] = _childObjectId;
        dailyComment[@"commentBy"] = [PFUser currentUser][@"userId"];
        // Parseに突っ込む前にViewだけ更新
        [_commentArray addObject:dailyComment];
        [self reloadData];
        
        if ([_commentArray count] > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_commentArray count] inSection:0];
            [_commentTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
        [dailyComment saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
            if (error) {
                [_commentArray removeObject:dailyComment];
                [self reloadData];
            }
        }];
        _commentTextField.text = @"";
    }
    [self.view endEditing:YES];
}

- (void)reloadData
{
    [self adjustTableViewHeight];
    [_commentTableView reloadData];
}


- (void)adjustTableViewHeight
{
    NSInteger cellHeightSum = 0;
    cellHeightSum += 44; // TODO no magic number コメント追加cellの高さ
    for (int i = [_commentArray count] - 1; i >= 0; i--) {
        UITableViewCell * cell = [self tableView:_commentTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        NSLog(@"index:%d  cell:%@", i, cell);
        cellHeightSum += cell.frame.size.height;
        if (cellHeightSum > 250) {
            break;
        }
    }
    
    CGRect rect = _commentTableView.frame;
    CGRect containerRect = _commentTableContainer.frame;
    
    if (cellHeightSum > 250) {
        rect.size.height = 250;
    } else {
        rect.size.height = cellHeightSum;
    }
    containerRect.size.height = rect.size.height + 10;
    containerRect.origin.y = self.view.frame.size.height - containerRect.size.height;
    _commentTableContainer.frame = containerRect;
    _commentTableView.frame = rect;
}


- (void)blockGesture
{
    // do nothing
}

- (NSMutableAttributedString *)stringWithAttribute:(NSString *)str
{
    // NSShadowオブジェクト
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[UIColor colorWithRed:0. green:0. blue:0. alpha:1.]];
    [shadow setShadowBlurRadius:4.0];
    [shadow setShadowOffset:CGSizeMake(2, 2)];
    
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:str];
    
    // 影
    [attrStr addAttribute:NSShadowAttributeName
                    value:shadow
                    range:NSMakeRange(0, [attrStr length])];
    
    // 文字色
    [attrStr addAttribute:NSForegroundColorAttributeName
                    value:[UIColor colorWithRed:1. green:1. blue:1. alpha:1.]
                    range:NSMakeRange(0, [attrStr length])];
    return attrStr;
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
