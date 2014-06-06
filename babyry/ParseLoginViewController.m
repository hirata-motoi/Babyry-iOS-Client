//
//  ParseLoginViewController.m
//  babyrydev
//
//  Created by kenjiszk on 2014/06/03.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ParseLoginViewController.h"

@interface ParseLoginViewController ()

@end

@implementation ParseLoginViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

///////////////////////////////////////////////////////
// PFLogInViewControllerのmethodたち
// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    // Check if both fields are completed
    if (username && password && username.length != 0 && password.length != 0) {
        return YES; // Begin login process
    }
     
    [[[UIAlertView alloc] initWithTitle:@"入力されていない項目があります"
                          message:@"全ての項目を埋めてください"
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
}
 
// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [self.navigationController popViewControllerAnimated:YES];
}


///////////////////////////////////////////////////////
// PFSignUpViewControllerのmethodたち
// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
     
    // loop through all of the submitted data
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) { // check completion
            informationComplete = NO;
            break;
        }
    }
     
    // Display an alert if a field wasn't completed
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                              message:@"Make sure you fill out all of the information!"
                              delegate:nil
                              cancelButtonTitle:@"ok"
                              otherButtonTitles:nil] show];
    }
     
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    [self dismissModalViewControllerAnimated:YES]; // Dismiss the PFSignUpViewController
}
 
// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    NSLog(@"Failed to sign up...");
}
 
// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    NSLog(@"User dismissed the signUpViewController");
}


- (void)openLoginView
{
    NSLog(@"Open LoginView");
    // Create the log in view controller
    PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
    [logInViewController setDelegate:self]; // Set ourselves as the delegate
    [logInViewController setFacebookPermissions:[NSArray arrayWithObjects:@"friends_about_me", nil]];
    [logInViewController setFields:
        PFLogInFieldsTwitter |
        PFLogInFieldsFacebook |
        PFLogInFieldsUsernameAndPassword |
        PFLogInFieldsPasswordForgotten |
        PFLogInFieldsDismissButton |
        PFLogInFieldsLogInButton |
        PFLogInFieldsSignUpButton
    ];

    //[logInViewController.logInView setBackgroundColor:[UIColor whiteColor]];
    //[logInViewController.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BabyryLogo"]]];

    // Set buttons appearance
    //[logInViewController.logInView.dismissButton setImage:[UIImage imageNamed:@"exit.png"] forState:UIControlStateNormal];
    //[logInViewController.logInView.dismissButton setImage:[UIImage imageNamed:@"exit_down.png"] forState:UIControlStateHighlighted];
     
    //[logInViewController.logInView.facebookButton setImage:nil forState:UIControlStateNormal];
    //[logInViewController.logInView.facebookButton setImage:nil forState:UIControlStateHighlighted];
    //[logInViewController.logInView.facebookButton setBackgroundImage:[UIImage imageNamed:@"facebook_down.png"] forState:UIControlStateHighlighted];
    //[logInViewController.logInView.facebookButton setBackgroundImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
    //[logInViewController.logInView.facebookButton setTitle:@"" forState:UIControlStateNormal];
    //[logInViewController.logInView.facebookButton setTitle:@"" forState:UIControlStateHighlighted];
 
    //[logInViewController.logInView.twitterButton setImage:nil forState:UIControlStateNormal];
    //[logInViewController.logInView.twitterButton setImage:nil forState:UIControlStateHighlighted];
    //[logInViewController.logInView.twitterButton setBackgroundImage:[UIImage imageNamed:@"twitter.png"] forState:UIControlStateNormal];
    //[logInViewController.logInView.twitterButton setBackgroundImage:[UIImage imageNamed:@"twitter_down.png"] forState:UIControlStateHighlighted];
    //[logInViewController.logInView.twitterButton setTitle:@"" forState:UIControlStateNormal];
    //[logInViewController.logInView.twitterButton setTitle:@"" forState:UIControlStateHighlighted];
     
    //[logInViewController.logInView.signUpButton setBackgroundImage:[UIImage imageNamed:@"signup.png"] forState:UIControlStateNormal];
    //[logInViewController.logInView.signUpButton setBackgroundImage:[UIImage imageNamed:@"signup_down.png"] forState:UIControlStateHighlighted];
    //[logInViewController.logInView.signUpButton setTitle:@"" forState:UIControlStateNormal];
    //[logInViewController.logInView.signUpButton setTitle:@"" forState:UIControlStateHighlighted];
     
    // Add login field background
    //fieldsBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    //[logInViewController.logInView insertSubview:fieldsBackground atIndex:1];
     
    // Remove text shadow
    //CALayer *layer = logInViewController.logInView.usernameField.layer;
    //layer.shadowOpacity = 0.0;
    //layer = logInViewController.logInView.passwordField.layer;
    //layer.shadowOpacity = 0.0;
     
    // Set field text color
    //[logInViewController.logInView.usernameField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];
    //[logInViewController.logInView.passwordField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];

    // Create the sign up view controller
    PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
    [signUpViewController setDelegate:self]; // Set ourselves as the delegate
         
    // Assign our sign up controller to be displayed from the login controller
    [logInViewController setSignUpController:signUpViewController];

    // Present the log in view controller
    [self presentViewController:logInViewController animated:YES completion:NULL];
}

@end
