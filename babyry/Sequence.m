//
//  Sequence.m
//  babyry
//
//  Created by Motoi Hirata on 2014/06/15.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "Sequence.h"

@implementation Sequence

-(NSString *)issueSequenceId:(NSString *)type {
    NSLog(@"issueSequenceId start");
    // リクエストを送信
    // 送信したいURLを作成し、Requestを作成します。
    NSURL *url = [NSURL URLWithString:@"http://babyryserver5002/sequence/issue"];
    
    NSMutableDictionary * params = [[NSMutableDictionary alloc]init];
    [params setObject:type forKey:@"type"];
    
    NSString *bodyString = [self buildParameters:params];
    NSData   *httpBody   = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url
                                                            cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                        timeoutInterval:20];
    // POST の HTTP Request を作成
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded"                 forHTTPHeaderField:@"Content-Type"];
    [req setValue:[NSString stringWithFormat:@"%d", [httpBody length]] forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:httpBody];
    [req setHTTPShouldHandleCookies:YES];
    
    //レスポンス
    NSURLResponse *resp;
    NSError *err;
    NSError *error;
    
    //HTTPリクエスト送信
    NSData *response = [NSURLConnection sendSynchronousRequest:req
                                             returningResponse:&resp error:&err];
    NSMutableDictionary *result = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:&error];
    
    NSLog(@"sequence id : %@", result);
    
    return [result objectForKey:@"id"];
}

- (NSString *)buildParameters:(NSMutableDictionary *)params {
    NSMutableString *s = [NSMutableString string];
    
    NSString *key;
    for ( key in params ) {
        NSString *uriEncodedValue = [self uriEncodeForString:[params objectForKey:key]];
        [s appendFormat:@"%@=%@&", key, uriEncodedValue];
    }
    
    if ( [s length] > 0 ) {
        [s deleteCharactersInRange:NSMakeRange([s length]-1, 1)];
    }
    return s;
}

- (NSString *)uriEncodeForString:(NSString *)str {
    NSString *escapedString = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                   kCFAllocatorDefault,
                                                                                                   (CFStringRef)str, // ←エンコード前の文字列(NSStringクラス)
                                                                                                   NULL,
                                                                                                   (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                   kCFStringEncodingUTF8));
    return escapedString;
}

@end
