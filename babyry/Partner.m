//
//  Partner.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/08.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Partner.h"

@implementation Partner

static Partner *partnerInfo = nil;
static bool isLoading = NO;

+ (Partner *)partnerUser
{
    @synchronized(self){
        if (!partnerInfo) {
            partnerInfo = [Partner new];
        }
    }
    return partnerInfo;
}

- (id)init
{
    PFUser *user = [PFUser currentUser];
    if (!user) {
        return nil;
    }
    
    self = [super init];
    
    Partner *ret = nil;
    
    if (self) {
        PFQuery *query = [PFQuery queryWithClassName:@"_User"];
        [query whereKey:@"familyId" equalTo:user[@"familyId"]];
        [query whereKey:@"userId" notEqualTo:user[@"userId"]];
        NSArray *objects = [query findObjects];
        if (objects.count == 1) {
            ret = objects[0];
        }
    }
    isLoading = NO;
    return ret;
}

+ (void)initialize
{
    @synchronized(self){
        if (!partnerInfo && !isLoading) {
            isLoading = YES;
            [NSThread detachNewThreadSelector:@selector(createNewObject) toTarget:self withObject:nil];
        }
    }
}

+ (void)createNewObject
{
    partnerInfo = [Partner new];
}



@end
