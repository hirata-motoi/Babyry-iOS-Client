//
//  UINavigationController+Block.h
//  iOS Blocks
//
//  Created by Ignacio Romero Zurbuchen on 3/33/13.
//  Copyright (c) 2011 DZN Labs.
//  Licence: MIT-Licence
//

#import <UIKit/UIKit.h>

/* Helper for casting weak objects to be used inside blocks or for assigning as delegates. */
static id weakObject(id object) {
    __block typeof(object) weakSelf = object;
    return weakSelf;
}

/*
 * Generic block constants for free usage over different classes.
 */
@protocol iOSBlocksProtocol <NSObject>

typedef void (^VoidBlock)();
//typedef void (^CompletionBlock)(BOOL completed);

typedef void (^DismissBlock)(NSInteger buttonIndex, NSString *buttonTitle);
typedef void (^PhotoPickedBlock)(UIImage *chosenImage);

typedef void (^ComposeCreatedBlock)(UIViewController *controller);
typedef void (^ComposeFinishedBlock)(UIViewController *controller, int result, NSError *error);

typedef void (^ProgressBlock)(NSInteger connectionProgress);
typedef void (^DataBlock)(NSData *data);
typedef void (^SuccessBlock)(NSHTTPURLResponse *HTTPResponse);
typedef void (^FailureBlock)(NSError *error);

typedef void (^RowPickedBlock)(NSString *title);

typedef void (^ListBlock)(NSArray *list);

typedef void (^StatusBlock)(unsigned int status);

@end


/*
 * UINavigationController Delegate block methods.
 */
@interface UINavigationController (Block) <UINavigationControllerDelegate, iOSBlocksProtocol>

/*
 * Pushes a view controller onto the receiver’s stack and updates the display.
 *
 * @param viewController The view controller that is pushed onto the stack. This object cannot be an instance of tab bar controller and it must not already be on the navigation stack.
 * @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 * @param completion A block object to be executed just after the navigation controller displayed the view controller’s view and navigation item properties.
 */
- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
              onCompletion:(VoidBlock)completion;

/*
 * Pops view controllers until the specified view controller is at the top of the navigation stack.
 *
 * @param viewController The view controller that is popped onto the stack. This object cannot be an instance of tab bar controller and it must not already be on the navigation stack.
 * @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 * @param completion A block object to be executed just after the navigation controller displayed the view controller’s view and navigation item properties.
 */
- (void)popToViewController:(UIViewController *)viewController
                   animated:(BOOL)animated
               onCompletion:(VoidBlock)completion;

/*
 * Pops the top view controller from the navigation stack and updates the display.
 *
 * @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 * @param completion A block object to be executed just after the navigation controller displayed the view controller’s view and navigation item properties.
 */
- (void)popViewControllerAnimated:(BOOL)animated
                     onCompletion:(VoidBlock)completion;

/*
 * Pops all the view controllers on the stack except the root view controller and updates the display.
 *
 * @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 * @param completion A block object to be executed just after the navigation controller displayed the view controller’s view and navigation item properties.
 */
- (void)popToRootViewControllerAnimated:(BOOL)animated
                           onCompletion:(VoidBlock)completion;

@end