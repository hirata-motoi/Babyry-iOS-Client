//
//  AWSSESUtils.m
//  babyry
//
//  Created by Kenji Suzuki on 2014/10/31.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AWSSESUtils.h"
#import "Config.h"
#import "Logger.h"

@implementation AWSSESUtils

+ (void) sendEmailBySES:(AWSServiceConfiguration *)configuration to:(NSString *)toAddress token:(NSString *)token
{
    AWSSES *awsSES = [[AWSSES new] initWithConfiguration:configuration];
    
    AWSSESContent *subject = [[AWSSESContent alloc] init];
    subject.data = [Config config][@"EmailVerifySubject"];
    
    AWSSESContent *messageContent = [[AWSSESContent alloc] init];
    messageContent.data = [[Config config][@"EmailVerifyMessage"] stringByReplacingOccurrencesOfString:@"%token" withString:token];
    
    AWSSESBody *body = [[AWSSESBody alloc] init];
    body.text = messageContent;

    AWSSESMessage *message = [[AWSSESMessage alloc] init];
    message.body = body;
    message.subject = subject;

    AWSSESDestination *destination = [[AWSSESDestination alloc] init];
    NSMutableArray *addressArray = [[NSMutableArray alloc] init];
    [addressArray addObject:toAddress];
    [destination setToAddresses:addressArray];

    AWSSESSendEmailRequest *request = [[AWSSESSendEmailRequest alloc] init];
    request.source = @"info@meaning.co.jp";
    request.message = message;
    request.destination = destination;
    
//    if ([[app env] isEqualToString:@"prod"]) {
        [[awsSES sendEmail:request] continueWithBlock:^id(BFTask *task){
            if (task.error) {
                [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in sending mail %@", task.error]];
            }
            return nil;
        }];
//    }
}

+ (void) resendVerifyEmail:(AWSServiceConfiguration *)configuration email:(NSString *)email
{
    PFQuery *query = [PFQuery queryWithClassName:@"EmailVerify"];
    [query whereKey:@"email" equalTo:email];
    [query whereKey:@"isVerified" equalTo:[NSNumber numberWithBool:NO]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if ([objects count] > 0) {
            [self sendEmailBySES:configuration to:email token:objects[0][@"token"]];
        }
    }];
}

@end
