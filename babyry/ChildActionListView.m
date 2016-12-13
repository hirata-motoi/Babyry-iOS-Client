//
//  ChildActionListView.m
//  babyry
//
//  Created by hirata.motoi on 2015/02/05.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ChildActionListView.h"

@implementation ChildActionListView

const int iconHeight = 20;

- (void)awakeFromNib
{
    [super awakeFromNib];
    [_actionListTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"CellIdentifier"];
    _actionListTable.delegate = self;
    _actionListTable.dataSource = self;
}

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    return [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
}

- (void)removeChild
{
    [_delegate removeChild:_childObjectId];
}

#pragma mark - TableView Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // テーブルに表示するデータ件数を返す;
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    
    // 初期化
    if (indexPath.row == 0) {
        // 削除アイコン
        UIImage *removeIcon = [UIImage imageNamed:@"TrashWhite"];
        int width = removeIcon.size.width;
        int height = removeIcon.size.height;
        float scale = height / iconHeight;
        UIImageView *removeIconView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"TrashWhite"]];
        CGRect rect = CGRectMake(0, (cell.frame.size.height - iconHeight)/2, width/scale, height/scale);
        removeIconView.frame = rect;
        [cell.contentView addSubview:removeIconView];
       
        // 削除label
        UILabel *label = [[UILabel alloc]init];
        label.textColor = [UIColor whiteColor];
        label.text = @"こどもを削除する";
        [label sizeToFit];
        CGRect labelRect = label.frame;
        labelRect.origin.x = labelRect.origin.x + width/scale + 15;
        labelRect.origin.y = (cell.frame.size.height - labelRect.size.height)/2;
        label.frame = labelRect;
        [cell.contentView addSubview:label];
        
        // どういうわけかcellのselectができないので透明のボタンを用意
        UIButton *removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [removeButton addTarget:self action:@selector(removeChild) forControlEvents:UIControlEventTouchUpInside];
        [removeButton setTitle:@"" forState:UIControlStateNormal];
        removeButton.frame = cell.bounds;
        [cell addSubview:removeButton];
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// セルの高さをtextの高さに合わせる
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}


@end
