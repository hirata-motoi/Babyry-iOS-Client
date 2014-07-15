//
//  TagView.h
//  babyry
//
//  Created by 平田基 on 2014/07/10.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>

@class TagView;
@protocol TagViewDelegate <NSObject>
- (void)updateTag:(TagView *)tagView;
@end

@interface TagView : UIImageView
{
    id<TagViewDelegate>delegate;
}
@property (nonatomic,assign) id<TagViewDelegate> delegate;

+ (TagView *)createTag:(PFObject *)tagInfo attached:(BOOL)attached;
- (void)revertTag:(BOOL)attached;
@property NSNumber *tagId;
@property BOOL attached;


@end
