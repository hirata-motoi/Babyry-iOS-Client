//
//  TagEditViewController.m
//  babyry
//
//  Created by 平田基 on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "TagEditViewController.h"
#import "TagView.h"

@interface TagEditViewController ()

@end

@implementation TagEditViewController

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
    
    // tagのマスター情報を取得
    
    self.tags = [[NSMutableArray alloc]init];
    [self setupTags];
    // _imageInfoからtag情報を抽出
    // tagマスター情報とtag情報を与えてtagオブジェクトを生成
    // viewにはりつける
    // NotifiCenterを実装してtagにおきた変更を受け取る
    // tagにもNotifiCenterを実装して、更新にミスったときなどはtagにメッセージを送る
    
    [self setupGesture];
    self.tagDisplayView.frame = CGRectMake(10, 400, 280, 150);
    
    // tagのattach状態更新処理中はtagを押せないようにする
    self.tagTouchDisabled = NO; // 初期化
    
    // NotificationCenter
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTag:) name:@"updateTag" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupTags
{
    PFQuery *query = [PFQuery queryWithClassName:@"Tag"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            if (objects.count > 0) {
                [self setTagObjects:objects attachedTags:_imageInfo[@"tags"]];
                [self showTags];
            } else {
                // TODO tagのマスター情報がないときはどうしようかな
            }
        }
    }];
}

- (void)setTagObjects:(NSArray *)tagMasterObjects attachedTags:(NSArray *)attachedTags
{
    NSMutableDictionary *tagsMap = [[NSMutableDictionary alloc]init];
    for (NSString *tag in attachedTags) {
        [tagsMap setObject:@"1" forKey:tag];
    }
    
    for (PFObject *tagInfo in tagMasterObjects) {
        BOOL attached = ([tagsMap objectForKey:tagInfo[@"tagId"]]) ? true : false;
        TagView *tag = [TagView createTag:tagInfo attached:attached];
        [self.tags addObject:tag];
    }
}

- (void)showTags
{
    for (TagView *tag in self.tags) {
        [self.tagDisplayView addSubview:tag];
    }
}

- (void)setupGesture
{
    UITapGestureRecognizer *backgroundViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideTagView:)];
    backgroundViewTapGestureRecognizer.numberOfTapsRequired = 1;
    backgroundViewTapGestureRecognizer.delegate = self;
    [_backgroundView addGestureRecognizer:backgroundViewTapGestureRecognizer];
    
    // イベントがなぜか伝搬してしまうので空処理を設定しておく
    UITapGestureRecognizer *tagDisplayViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(blockGesture:)];
    tagDisplayViewTapGestureRecognizer.numberOfTapsRequired = 1;
    _tagDisplayView.userInteractionEnabled = YES;
    tagDisplayViewTapGestureRecognizer.delegate = self;
    [_tagDisplayView addGestureRecognizer:tagDisplayViewTapGestureRecognizer];
}

- (void)hideTagView:(id)sender
{
    self.view.hidden = YES;
}

- (void)blockGesture:(id)sender
{
    NSLog(@"blockGesture");
    // do nothing
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    //iOS6未満でsuperviewのジェスチャーが優先されてしまうバグ（？）を回避
    if (touch.view != gestureRecognizer.view
        && [touch.view isKindOfClass:[UIControl class]])
    {
        return false;
    }
    return true;
}

- (void)updateTag:(NSNotification *)notification
{
    TagView *tagView = (TagView *)[notification object];
    NSNumber *tagId = tagView.tagId;
    
    
    NSMutableArray *attachedTagsList = _imageInfo[@"tags"];
    if (!attachedTagsList) {
        attachedTagsList = [[NSMutableArray alloc]init];
    }
    NSArray *originalTagList = [NSArray arrayWithArray:attachedTagsList];
    
    if (tagView.attached) {
        // 今attachされた
        NSLog(@"attached");
        [attachedTagsList addObject:tagId];
    } else {
        // 今detachされた
        NSLog(@"detached");
        [attachedTagsList removeObject:tagId];
    }
    
    NSLog(@"attachedTagsList : %@", attachedTagsList);
    
    // 一応重複を排除
    attachedTagsList = [NSMutableArray arrayWithArray: [[[NSSet alloc] initWithArray:[NSArray arrayWithArray:attachedTagsList]]allObjects]];

    // 一回ChildImageオブジェクトを最新にしてから更新処理
    NSLog(@"_imageInfo : %@", _imageInfo);
    [_imageInfo fetchInBackgroundWithBlock:^(PFObject *object, NSError *error){
        _imageInfo[@"tags"] = attachedTagsList;
        [_imageInfo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (!succeeded) {
                NSLog(@"failed");
                // 失敗したことを通知
                NSString *notificationName = [NSString stringWithFormat:@"tagUpdateFailed:%@", [tagView.tagId stringValue]];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:nil];
                // 戻す
                _imageInfo[@"tags"] = originalTagList;
            }
        }];
    }];
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
