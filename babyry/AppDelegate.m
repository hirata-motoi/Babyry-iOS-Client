//
//  AppDelegate.m
//  babyrydev
//
//  Created by kenjiszk on 2014/05/30.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <ParseCrashReporting/ParseCrashReporting.h>
#import "PageContentViewController.h"
#import "Config.h"
#import "AppSetting.h"
#import "DateUtils.h"
#import "Logger.h"
#import "FamilyRole.h"
#import "ImageDownloadInBackground.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //3.5inchと4inchを読み分けする
    CGRect rect = [UIScreen mainScreen].bounds;
    if (rect.size.height == 480) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"3_5_inch" bundle:nil];
        UIViewController* rootViewController = [storyboard instantiateInitialViewController];
        
        self.window.rootViewController = rootViewController;
    }
    
    // global変数
    [self setGlobalVariables];
    
    // CoreData
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"babyry.sqlite"];
    [self setupFirstLaunchUUID];
    
    // Parse Crash Report
    [ParseCrashReporting enable];
    
    // Parse Authentification
    [Parse setApplicationId:[Config secretConfig][@"ParseApplicationId"] clientKey:[Config secretConfig][@"ParseClientKey"]];
    
    // Facebood Auth
    [PFFacebookUtils initializeFacebook];
    
    // Customize the Page Indicator
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    pageControl.backgroundColor = [UIColor whiteColor];
    
    // Register for push notifications
    [application unregisterForRemoteNotifications];
    NSString *currentVersion = [[UIDevice currentDevice] systemVersion];
    if([currentVersion compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending){
        // i0S7以前の処理
        [application registerForRemoteNotificationTypes:
         UIRemoteNotificationTypeBadge |
         UIRemoteNotificationTypeAlert |
         UIRemoteNotificationTypeSound |
         UIRemoteNotificationTypeNewsstandContentAvailability];
    } else {
        // iOS8の処理
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        
        [application registerForRemoteNotifications];
        [application registerUserNotificationSettings:settings];
    }
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // Crittercism
//    [Crittercism enableWithAppID:[Config secretConfig][@"CrittercismAppId"]];
    
    [self setTrackingLogName:@""];
    
    // TransitionByPushNotification初期化
    [TransitionByPushNotification initialize];
    
    // push通知から飛んだ場合userInfoに値がある
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo != nil) {
        if (userInfo[@"transitionInfo"] && [PFUser currentUser]) {
            [TransitionByPushNotification setInfo:userInfo[@"transitionInfo"]];
            [TransitionByPushNotification setAppLaunchedFlag];
        }
    }
    
    // Override point for customization after application launch.
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    currentInstallation[@"badge"] = [NSNumber numberWithInt:0];
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
        if (error) {
            [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"Error in getting device token %@", error]];
        }
    }];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)err{
    [Logger writeOneShot:@"crit" message:[NSString stringWithFormat:@"failed to get device token %@", err]];
}

//- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
//    /* バッジの追加、消すタイミングは追々の課題なのでいまはつけない
//    NSInteger badgeNumber = [application applicationIconBadgeNumber];
//    [application setApplicationIconBadgeNumber:++badgeNumber];
//    NSLog(@"receive remote notification %d", badgeNumber);
//    */
//}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    if (![PFUser currentUser]) {
        return;
    }
    
    if (application.applicationState == UIApplicationStateInactive) {
        // アプリがバックグラウンドで起動している時に、push通知が届きpush通知から起動
        [PFPush handlePush:userInfo];
        if (userInfo[@"transitionInfo"]) {
            if ([userInfo[@"transitionInfo"][@"event"] isEqualToString:@"imageUpload"]
                || [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"bestShotChosen"]
                || [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"commentPosted"]
                || [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"receiveApply"]
                || [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"admitApply"]
                || [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"requestPhoto"]) {
                [TransitionByPushNotification setInfo:userInfo[@"transitionInfo"]];
            }
        }
        
        if (userInfo[@"transitionInfo"] && [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"partSwitched"]){
            // キャッシュを更新しておく
            [FamilyRole selfRole:@"noCache"];
            [FamilyRole updateFamilyRoleCacheWithBlock:^(){
                NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
                [[NSNotificationCenter defaultCenter] postNotification:n];
            }];
        }
        
        // 各クラスに通知用
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didReceiveRemoteNotification" object:nil];
        
        completionHandler(UIBackgroundFetchResultNewData);
    }
    
    if (application.applicationState == UIApplicationStateBackground) {
        // backgourndでpushを受け取った時に発動、裏で画像データを読む
        
        if (userInfo[@"transitionInfo"][@"imageIds"]) {
            // 多重でpushがくるのでインスタンス化
            ImageDownloadInBackground *imageDownloadInBackground = [[ImageDownloadInBackground alloc] init];
            imageDownloadInBackground.completionHandler = completionHandler;
            [imageDownloadInBackground downloadByPushInBackground:userInfo[@"transitionInfo"]];
        }
    }
    
    if (application.applicationState == UIApplicationStateActive) {
        // アプリが起動している時に、push通知が届きpush通知から起動
        
        // パート変更の場合にはフォラグラウンドでもお知らせ
        if (userInfo[@"transitionInfo"] && [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"partSwitched"]){
            // キャッシュを更新しておく
            [FamilyRole selfRole:@"noCache"];
            [FamilyRole updateFamilyRoleCacheWithBlock:^(){
                NSNotification *n = [NSNotification notificationWithName:@"childPropertiesChanged" object:nil];
                [[NSNotificationCenter defaultCenter] postNotification:n];
            }];
            [PFPush handlePush:userInfo];
        }
        
        if (userInfo[@"transitionInfo"]
            && ([userInfo[@"transitionInfo"][@"event"] isEqualToString:@"requestPhoto"]
                || [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"childAdded"]
                || [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"admitApply"]
                || [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"receiveApply"])) {
                [PFPush handlePush:userInfo];
            }
        
        if (userInfo[@"transitionInfo"] && [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"calendarAdded"]) {
            NSNotification *n = [NSNotification notificationWithName:@"receivedCalendarAddedNotification" object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:n];
        }
        if (userInfo[@"transitionInfo"] && [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"childIconChanged"]) {
            NSNotification *n = [NSNotification notificationWithName:@"childIconChanged" object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:n];
        }
        if (userInfo[@"transitionInfo"] &&
            (
             [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"admitApply"]  ||
             [userInfo[@"transitionInfo"][@"event"] isEqualToString:@"receiveApply"]
             )
            ) {
            NSNotification *n = [NSNotification notificationWithName:@"receivedApplyEvent" object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:n];
        }
        
        // 各クラスに通知用
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didReceiveRemoteNotification" object:nil];
        
        completionHandler(UIBackgroundFetchResultNewData);
    }
}

- (void) application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    // このメソッドを書いておくと、バックグラウンドでNSURLSessionが呼ばれていた場合、そのdelegate method(ダウンロードが完了した場合のcallbackとか)が一斉に呼び出される
    // 書いておかないと、アプリがforegroundになったときに一斉に呼ばれるので×
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    // badgeを消す
    [UIApplication sharedApplication].applicationIconBadgeNumber = -1;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self insertLastLog];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    [self setTrackingLogName:@"applicationWillEnterForeground"];
    
    NSNotification *n = [NSNotification notificationWithName:@"applicationWillEnterForeground" object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:n];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // Facebook
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self insertLastLog];
    [MagicalRecord cleanUp];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

- (void)setGlobalVariables
{
    // env
#ifdef DEBUG
    _env = @"dev";
#else
    _env = @"prod";
#endif
}

- (void)setupFirstLaunchUUID
{
    NSString *UUIDKeyName = [Config config][@"UUIDKeyName"];
    AppSetting *as = [AppSetting MR_findFirstByAttribute:@"name" withValue:UUIDKeyName];
    if (as) {
        return;
    }
    
    AppSetting *newAs = [AppSetting MR_createEntity];
    newAs.name = UUIDKeyName;
    newAs.value = [[NSUUID UUID] UUIDString];
    newAs.createdAt = [DateUtils setSystemTimezone:[NSDate date]];
    newAs.updatedAt = [DateUtils setSystemTimezone:[NSDate date]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
}

- (void) setTrackingLogName:(NSString *)type
{
    [Logger resetTrackingLogName:type];
}

- (void) insertLastLog
{
    [Logger writeToTrackingLog:[NSString stringWithFormat:@"%@ lastLine", [DateUtils setSystemTimezone:[NSDate date]]]];
}

@end
