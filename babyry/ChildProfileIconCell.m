//
//  ChildProfileIconCell.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/10.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ChildProfileIconCell.h"

@implementation ChildProfileIconCell

- (void)awakeFromNib {
    // Initialization code
    
    _childNameEditField.hidden = YES;
    _saveButton.hidden = YES;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openEditField)];
    tapGesture.numberOfTapsRequired = 1;
    _childNameLabel.userInteractionEnabled = YES;
    [_childNameLabel addGestureRecognizer:tapGesture];
    
    UITapGestureRecognizer *iconEditGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openIconEdit)];
    iconEditGesture.numberOfTapsRequired = 1;
    [_iconContainer addGestureRecognizer:iconEditGesture];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)openEditField
{
    [_delegate setTargetChild:_childObjectId];
    _childNameLabel.hidden = YES;
    _childNameEditField.text = _childNameLabel.text;
    _childNameEditField.hidden = NO;
    _saveButton.hidden = NO;
    [_childNameEditField becomeFirstResponder];
    [_delegate showOverlay];
}

- (void)closeEditField
{
    _childNameEditField.hidden = YES;
    _saveButton.hidden = YES;
    _childNameLabel.hidden = NO;
    [_childNameEditField resignFirstResponder];
    
}

- (IBAction)save:(id)sender {
    _childNameLabel.text = _childNameEditField.text;
    NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
    params[@"name"] =_childNameEditField.text;
    [_delegate saveChildProperty:_childObjectId withParams:params];
    
    [self closeEditField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    [self closeEditField];
    
    return TRUE;
}

- (void)openIconEdit
{
    [_delegate openIconEdit:_childObjectId];
}


@end
