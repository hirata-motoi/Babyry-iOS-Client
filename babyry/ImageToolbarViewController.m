//
//  ImageToolbarViewController.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/08/11.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImageToolbarViewController.h"

@interface ImageToolbarViewController ()

@end

@implementation ImageToolbarViewController

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
    
    CGRect frame = CGRectMake(0, 0, 320, 44);
    self.view.frame = frame;
    
    UITapGestureRecognizer *commentViewContainerTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(blockGesture)];
    commentViewContainerTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:commentViewContainerTap];
    
    UITapGestureRecognizer *imageTrashViewTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageTrash)];
    imageTrashViewTap.numberOfTapsRequired = 1;
    [_imageTrashView.customView addGestureRecognizer:imageTrashViewTap];
    
    UITapGestureRecognizer *imageSaveViewTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageSave)];
    imageSaveViewTap.numberOfTapsRequired = 1;
    [_imageSaveView.customView addGestureRecognizer:imageSaveViewTap];
    
    UITapGestureRecognizer *imageCommentViewTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageComment)];
    imageCommentViewTap.numberOfTapsRequired = 1;
    [_imageCommentView.customView addGestureRecognizer:imageCommentViewTap];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)blockGesture
{
    // do nothing
}

- (void)imageTrash
{
    NSLog(@"imageTrash");
}

- (void)imageSave
{
    NSLog(@"imageSave");
}

- (void)imageComment
{
    NSLog(@"imageComment");
    CGRect currentFrame = _commentView.frame;
    if (currentFrame.origin.y <= 20 + 44) {
        NSLog(@"hide commentView");
        currentFrame.origin.y = self.parentViewController.view.frame.size.height;
        currentFrame.origin.x = self.view.frame.size.width;
        //[_commentViewTopButton setTitle:@"コメントを表示" forState:UIControlStateNormal];
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _commentView.frame = currentFrame;
                         }
                         completion:^(BOOL finished){
//                             _commentTableContainer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.0];
//                             _commentIconImageView.hidden = NO;
//                             _commentNumIcon.hidden = NO;
                         }];
    } else {
        NSLog(@"open commentView");
        currentFrame.origin.y = 20 + 44;
        currentFrame.origin.x = 0;
//        [_commentViewTopButton setTitle:@"コメントを隠す" forState:UIControlStateNormal];
//        _commentTableContainer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
//        _commentIconImageView.hidden = YES;
//        _commentNumIcon.hidden = YES;
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _commentView.frame = currentFrame;
                         }
                         completion:^(BOOL finished){
                         }];
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

@end
