//
//  GenderSegmentControl.m
//  babyry
//
//  Created by hirata.motoi on 2015/01/11.
//  Copyright (c) 2015年 jp.co.meaning. All rights reserved.
//

#import "GenderSegmentControl.h"

@implementation GenderSegmentControl

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (GenderSegmentControl *)initWithParams:(NSMutableDictionary *)params
{
    NSArray *items = [[NSArray alloc]initWithObjects:@"女", @"男", nil];
    self = [super initWithItems:items];
    if (self) {
        _childObjectId = params[@"childObjectId"];
        if ([params[@"gender"] isEqualToString:@"female"]) {
            self.selectedSegmentIndex = 0;
        } else if ([params[@"gender"] isEqualToString:@"male"]) {
            self.selectedSegmentIndex = 1;
        }
        
        self.frame = CGRectMake(0, 0, 100, 30);
    }
    return self;
}

@end
