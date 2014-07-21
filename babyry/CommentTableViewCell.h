//
//  CommentTableViewCell.h
//  babyry
//
//  Created by 平田基 on 2014/07/21.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *commentUserName;
@property (weak, nonatomic) IBOutlet UILabel *pastTime;
@property (weak, nonatomic) IBOutlet UILabel *commentText;

@end
