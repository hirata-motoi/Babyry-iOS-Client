//
//  ChildPropertyUtils.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/22.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "ChildPropertyUtils.h"
#import "ChildProperties.h"
#import "Logger.h"

@implementation ChildPropertyUtils

- (void)saveChildProperty:(NSString *)childObjectId withParams:(NSMutableDictionary *)params
{
    // リセット用に保持
    NSMutableDictionary *childProperty = [ChildProperties getChildProperty:childObjectId];
    // coredataに保存
    [ChildProperties updateChildPropertyWithObjectId:childObjectId withParams:params];
    // parseを更新
    PFQuery *query = [PFQuery queryWithClassName:@"Child"];
    [query whereKey:@"objectId" equalTo:childObjectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to get Child for saveChildProperty childObjectId:%@ error:%@", childObjectId, error]];
            // TODO
            // coredataを戻す処理はこの中で実装
            // ページをreloadしたりとかの処理をdelegateで実装しておく
            [self resetChildProperty:(NSMutableDictionary *)childProperty withParams:(NSMutableDictionary *)params];
            [self showAlert];
            return;
        }
        if (objects.count < 1) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Child NOT FOUND for saveChildProperty childObjectId:%@ error:%@", childObjectId, error]];
            [self resetChildProperty:(NSMutableDictionary *)childProperty withParams:(NSMutableDictionary *)params];
            [self showAlert];
            return;
        }

        PFObject *child = objects[0];
        for (NSString *key in [params allKeys]) {
            child[key] = params[key];
        }
        [child saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Failed to save Child childObjectId:%@ error:%@", childObjectId, error]];
                [self resetChildProperty:(NSMutableDictionary *)childProperty withParams:(NSMutableDictionary *)params];
                [self showAlert];
                return;
            }
        }];
    }];
}

- (void)resetChildProperty:(NSMutableDictionary *)childProperty withParams:(NSMutableDictionary *)params
{
    NSMutableDictionary *resetParams = [[NSMutableDictionary alloc]init];
    for (NSString *key in params.allKeys) {
        resetParams[key] = childProperty[key];
    }
    [ChildProperties updateChildPropertyWithObjectId:childProperty[@"objectId"] withParams:resetParams];

    // TODO delegate methodをたたく
    [_delegate resetFields];
//    [self setupChildProperties];
//    [_profileTable reloadData];
}

- (void)showAlert
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"ネットワークエラー"
                                                   message:@"ネットワークエラーが発生しました"
                                                  delegate:self
                                         cancelButtonTitle:@""
                                         otherButtonTitles:@"OK", nil];
    [alert show];
}

- (UIAlertController *)iconEditActionSheet:(NSString *)childObjectId
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
   
    if (childObjectId) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"ベストショットから選択" style: UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [_delegate openIconEdit:childObjectId];
        }]];
    }
    [alertController addAction:[UIAlertAction actionWithTitle:@"アルバムから選択" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [_delegate openAlbumPicker:childObjectId];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"キャンセル" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
//    [self presentViewController:alertController animated:YES completion:nil];
    return alertController;
}


@end
