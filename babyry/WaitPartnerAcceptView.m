//
//  WaitPartnerAcceptView.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/09/01.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "WaitPartnerAcceptView.h"
#import "UIColor+Hex.h"
#import "ColorUtils.h"
#import <Parse/Parse.h>
#import "Logger.h"
#import "FamilyApply.h"
#import "FamilyApplyViewController.h"
#import "Child.h"
#import "MBProgressHUD.h"

@implementation WaitPartnerAcceptView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

+ (instancetype)view
{
    NSString *className = NSStringFromClass([self class]);
    WaitPartnerAcceptView *view = [[[NSBundle mainBundle] loadNibNamed:className owner:nil options:0] firstObject];
    view.backgroundColor = [UIColor_Hex colorWithHexString:@"000000" alpha:0.7];
    view.layer.cornerRadius = 5;
    view.withdrawLabel.layer.cornerRadius = 5;
    
    view.withdrawLabel.userInteractionEnabled = YES;
    
    return view;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (IBAction)withdrawAction:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"申請を取り下げますか？"
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"キャンセル"
                                          otherButtonTitles:@"取り下げる", nil
                          ];
    [alert show];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
        {
        }
            break;
        case 1:
        {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.superview animated:YES];
            hud.labelText = @"データ同期中";
            PFUser *user = [PFUser currentUser];
            [user refreshInBackgroundWithBlock:^(PFObject *object, NSError *error){
                if (error) {
                    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in refresh user at WaitPartnerAccept : %@", error]];
                    [self closeSelf:NO];
                    [hud hide:YES];
                    return;
                }
                
                NSString *familyId = [[NSString alloc] initWithString:user[@"familyId"]];
                user[@"familyId"] = @"";
                [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                    if(error) {
                        [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in delete user familyId at WaitPartnerAccept : %@", error]];
                        [self closeSelf:YES];
                        [hud hide:YES];
                        return;
                    }
                    
                    [FamilyApply deleteApply];
                    [Child deleteByFamilyId:familyId];
                    [hud hide:YES];
                    [Logger writeOneShot:@"info" message:[NSString stringWithFormat:@"FamilyApply delete deletedBy:%@ familyId:%@", [PFUser currentUser][@"userId"], familyId]];
                    [self closeSelf:YES];
                }];
            }];
        }
            break;
    }
}

-(void) closeSelf:(BOOL) isSucceeded
{
    [self.superview removeFromSuperview];
    if (isSucceeded) {
        FamilyApplyViewController * familyApplyViewController = [_parentViewController.storyboard instantiateViewControllerWithIdentifier:@"FamilyApplyViewController"];
        [_parentViewController.navigationController pushViewController:familyApplyViewController animated:YES];
    }
}

@end
