//
//  CommentViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "CommentViewController.h"
#import "PageContentViewController.h"
#import "CommentTableViewCell.h"
#import "NotificationHistory.h"
#import "Partner.h"
#import "PushNotification.h"
#import "UIColor+Hex.h"
#import "Logger.h"
#import "ChildProperties.h"

@interface CommentViewController ()

@end

static const NSInteger secondsForOneMinute = 60;
static const NSInteger secondsForOneHour = secondsForOneMinute * 60;
static const NSInteger secondsForOneDay = secondsForOneHour * 24;
static const NSInteger secondsForOneMonth = secondsForOneDay * 30;
static const NSInteger secondsForOneYear = secondsForOneMonth * 12;

@implementation CommentViewController {
    NSMutableDictionary *childProperty;
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
    
    childProperty = [ChildProperties getChildProperty:_childObjectId];
    
    _commentTableContainer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    
    _commentTableView.dataSource = self;
    _commentTableView.delegate = self;
    _commentTableView.layer.borderColor = [UIColor whiteColor].CGColor;
    _commentTableView.layer.borderWidth = 1;
    _commentTableView.layer.cornerRadius = 5;
    _commentTableView.separatorColor = [UIColor_Hex colorWithHexString:@"FFFFFF" alpha:0.3];
    _commentTableView.tableFooterView = [[UIView alloc]init];
    
    // text field
    _commentTextView = [[UIPlaceHolderTextView alloc] init];
    _commentTextView.delegate = self;
    _commentTextView.textColor = [UIColor blackColor];
    _commentTextView.placeholder = @"コメントを追加";
    _commentTextView.layer.cornerRadius = 5;
    
    // comment系設置
    _commentTextView.frame = CGRectMake(10, _commentTableContainer.frame.size.height - 40, 250, 30);
    _commentTextView.hidden = NO;
    [_commentTableContainer addSubview:_commentTextView];
    _commentSubmitButton.frame = CGRectMake(265, _commentTableContainer.frame.size.height - 40, 44, 30);
    _commentSubmitButton.hidden = NO;
    [_commentTableContainer addSubview:_commentSubmitButton];
    
    _isGettingComment = NO;
    [self getCommentFromParse];
    
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
    
    UINib *nib = [UINib nibWithNibName:@"CommentTableViewCell" bundle:nil];
    [_commentTableView registerNib:nib forCellReuseIdentifier:@"Cell"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!_commentTimer || ![_commentTimer isValid]) {
        _commentTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(getCommentFromParse) userInfo:nil repeats:YES];
        [_commentTimer fire];
    }
    
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
    if ([_commentArray count] > 0) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[_commentArray count]-1 inSection:0];
        [_commentTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    // super
    [super viewWillDisappear:animated];
    
    [_commentTimer invalidate];
    
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
    if (_isGettingComment) {
        return;
    }
    _isGettingComment = YES;
    
    PFQuery *commentQuery = [PFQuery queryWithClassName:[NSString stringWithFormat:@"Comment%ld", (long)[childProperty[@"commentShardIndex"] integerValue]]];
    [commentQuery whereKey:@"childId" equalTo:_childObjectId];
    [commentQuery whereKey:@"date" equalTo:[NSNumber numberWithInteger:[_date integerValue]]];
    [commentQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error) {
            _commentArray = [[NSMutableArray alloc] initWithArray:objects];
            
            if ([_commentArray count] > 0) {
                [self reloadData];
               NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_commentArray count]-1 inSection:0];
               [_commentTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            } else {
                [self reloadData];
            }
        } else {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getCommentFromParse : %@", error]];
        }
        _isGettingComment = NO;
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
    return [_commentArray count];
}

// indexPathの位置にあるセルを返す
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 0;
    cell.backgroundColor = [UIColor clearColor];

    cell.commentUserName.text = @"";
    cell.pastTime.text = @"";
    cell.commentText.text = @"";
    cell.commentText.numberOfLines = 0;
    
    // nickName
    PFObject *commentObject = [_commentArray objectAtIndex:indexPath.row];
    if ([commentObject[@"commentBy"] isEqualToString:[PFUser currentUser][@"userId"]]) {
        [cell.commentUserName setAttributedText:[self stringWithAttribute:[PFUser currentUser][@"nickName"]]];
    } else {
        // ニックネーム取得 (ニックネームはかわることがあるのでいちいちクエリ発行 (ただし、キャッシュ優先))
        PFQuery *nickQuery = [PFQuery queryWithClassName:@"_User"];
        [nickQuery whereKey:@"userId" equalTo:commentObject[@"commentBy"]];
        nickQuery.cachePolicy = kPFCachePolicyCacheElseNetwork;
        PFObject *nickObject = [nickQuery getFirstObject];
        [cell.commentUserName setAttributedText:[self stringWithAttribute:nickObject[@"nickName"]]];
    }
    
    // comment本文
    [cell.commentText setAttributedText:[self stringWithAttribute:commentObject[@"comment"]]];
    CGSize bounds = CGSizeMake(cell.commentText.frame.size.width, tableView.frame.size.height);
    CGSize sizeCommentText = [cell.commentText.text
                   boundingRectWithSize:bounds
                   options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                   attributes:[NSDictionary dictionaryWithObject:cell.commentText.font forKey:NSFontAttributeName]
                   context:nil].size;
    
    CGRect rect = cell.commentText.frame;
    rect.size.height = sizeCommentText.height;
    cell.commentText.frame = rect;
   
    // 投稿日時
    [cell.pastTime setAttributedText:[self stringWithAttribute:[self calcPastTime:commentObject.createdAt]]];
    
    return cell;
}

// セルの高さをtextの高さに合わせる
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [_commentArray count]) {
        return _commentTextView.frame.size.height;
    }
    CommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.commentUserName.text = @"nickName"; // dummy
    cell.commentText.text = [_commentArray objectAtIndex:indexPath.row][@"comment"];
    
    // get cell height
    cell.commentText.numberOfLines = 0;
    CGSize bounds = CGSizeMake(cell.commentText.frame.size.width, tableView.frame.size.height);
    CGSize sizeCommentText = [cell.commentText.text
                              boundingRectWithSize:bounds
                              options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                              attributes:[NSDictionary dictionaryWithObject:cell.commentText.font forKey:NSFontAttributeName]
                              context:nil].size;
    
    return sizeCommentText.height + cell.commentUserName.frame.size.height + 10; // 余白10
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    // Get userInfo
    NSDictionary *userInfo;
    userInfo = [notification userInfo];
    
    // Calc overlap of keyboardFrame and textViewFrame
    CGRect keyboardFrame;
    keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view.superview convertRect:keyboardFrame fromView:nil];
    float originY = self.view.frame.size.height - keyboardFrame.size.height - _commentTableContainer.frame.size.height +44;
    
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
    if ([_commentArray count] > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_commentArray count]-1 inSection:0];
        [_commentTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    [self.view endEditing:YES];
}

- (void)submitComment
{
    if ( _commentTextView && ![_commentTextView.text isEqualToString:@""] ) {
        // Insert To Parse
        PFObject *dailyComment = [PFObject objectWithClassName:[NSString stringWithFormat:@"Comment%ld", (long)[childProperty[@"commentShardIndex"] integerValue]]];
        dailyComment[@"comment"] = _commentTextView.text;
        // D(文字)つけないとwhere句のfieldに指定出来ないので付ける
        dailyComment[@"date"] = [NSNumber numberWithInteger:[_date integerValue]];
        dailyComment[@"childId"] = _childObjectId;
        dailyComment[@"commentBy"] = [PFUser currentUser][@"userId"];
        // Parseに突っ込む前にViewだけ更新
        [_commentArray addObject:dailyComment];
        [self reloadData];
        
        if ([_commentArray count] > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_commentArray count]-1 inSection:0];
            [_commentTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
        [dailyComment saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in submitComment : %@", error]];
                [_commentArray removeObject:dailyComment];
                [self reloadData];
            } else {
                [self createNotificationHistory];
                [self sendPushNotification:dailyComment];
            }
        }];
        _commentTextView.text = @"";
    }
    [self.view endEditing:YES];
}

- (void)reloadData
{
    [_commentTableView reloadData];
}

- (void)blockGesture
{
    // do nothing
}

- (NSMutableAttributedString *)stringWithAttribute:(NSString *)str
{
    if ([str length] == 0) {
        str = @"";
    }
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

- (NSString *)calcPastTime: (NSDate *)postDate
{
    // 現在時刻を取得
    NSDate *now = [NSDate date];
    // 現在時刻との差分
    NSTimeInterval delta = [now timeIntervalSinceDate:postDate];
 
    int deltaInt = [[NSNumber numberWithDouble:delta] intValue];
    NSString *pastTimeString;
    if (deltaInt < secondsForOneMinute) {
        // 1分以内:今と表記
        pastTimeString = @"今";
    } else if (deltaInt < secondsForOneHour) {
        // 1時間以内:分単位で表記
        int min = deltaInt / secondsForOneMinute;
        pastTimeString = [NSString stringWithFormat:@"%d分前", min];
    } else if (deltaInt < secondsForOneDay) {
        // 1日以内:時間単位で表記
        int hour = deltaInt / secondsForOneHour;
        pastTimeString = [NSString stringWithFormat:@"%d時間前", hour];
    } else if (deltaInt < secondsForOneMonth) {
        // 1ヶ月以内:日単位で表記
        int day = deltaInt / secondsForOneDay;
        pastTimeString = [NSString stringWithFormat:@"%d日前", day];
    } else if (deltaInt < secondsForOneYear) {
        // 1年以内:月単位で表記
        int month = deltaInt / secondsForOneMonth;
        pastTimeString = [NSString stringWithFormat:@"%dヶ月前", month];
    } else {
        // 1年以上:年単位で表記
        int year = deltaInt / secondsForOneYear;
        pastTimeString = [NSString stringWithFormat:@"%d年前", year];
    }
    return pastTimeString;
}

- (void)createNotificationHistory
{
    PFObject *partner = (PFObject *)[Partner partnerUser];
    [NotificationHistory createNotificationHistoryWithType:@"commentPosted" withTo:partner[@"userId"] withChild:_childObjectId withDate:[_date integerValue]];
}

- (void)sendPushNotification:(PFObject *)dailyComment
{
    // TODO push通知送信用methodで可変長の引数をとれるように対応する
    NSMutableDictionary *transitionInfoDic = [[NSMutableDictionary alloc] init];
    transitionInfoDic[@"event"] = @"commentPosted";
    transitionInfoDic[@"date"] = _date;
    transitionInfoDic[@"section"] = [NSString stringWithFormat:@"%d", _indexPath.section];
    transitionInfoDic[@"row"] = [NSString stringWithFormat:@"%d", _indexPath.row];
    transitionInfoDic[@"childObjectId"] = _childObjectId;
    NSString *message = [NSString stringWithFormat:@"%@さん\n%@", [PFUser currentUser][@"nickName"], dailyComment[@"comment"]];
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    NSMutableDictionary *data = [[NSMutableDictionary alloc]init];
    options[@"data"] = data;
    data[@"alert"] = message;
    data[@"badge"] = @"Increment";
    data[@"transitionInfo"] = transitionInfoDic;
    [PushNotification sendInBackground:@"commentPosted" withOptions:options];
}

@end
