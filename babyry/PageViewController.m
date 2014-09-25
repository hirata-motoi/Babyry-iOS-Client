//
//  PageViewController.m
//  babyry
//
//  Created by hirata.motoi on 2014/08/05.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "PageViewController.h"
#import "PageContentViewController.h"
#import "ImageEdit.h"
#import "TagAlbumOperationViewController.h"

@interface PageViewController ()

@end

@implementation PageViewController

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
    self.delegate = self;
    self.dataSource = self;
  
    PageContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *startingViewControllers = @[startingViewController];
    [self setViewControllers:startingViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// pragma mark - Page View Controller Data Source
// provides the view controller after the current view controller. In other words, we tell the app what to display for the next screen.
- (PageContentViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(PageContentViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

// provides the view controller before the current view controller. In other words, we tell the app what to display when user switches back to the previous screen.
- (PageContentViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(PageContentViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [_childProperties count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (PageContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([_childProperties count] == 0) || (index >= [_childProperties count])) {
        return nil;
    }
    
    PageContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageContentViewController"];

    pageContentViewController.pageIndex = index;
    pageContentViewController.childProperty = _childProperties[index];
    pageContentViewController.childObjectId = [[_childProperties objectAtIndex:index] objectForKey:@"objectId"];
    
    // PageContentViewから更新するために暫定 (CoreDataに入れたら消す)
    pageContentViewController.childProperties = _childProperties;
    
    _currentPageIndex = index;
    _currentDisplayedPageContentViewController = pageContentViewController;
    
    return pageContentViewController;
}

// ViewControllerから叩かれる
- (void)openTagSelectView
{
    _tagAlbumOperationView.hidden = NO;
}

- (void)setupTagAlbumOperationView
{
    // tagAlbumのviewcontrollerをinstans化
    TagAlbumOperationViewController *tagAlbumOperationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TagAlbumOperationViewController"];
    tagAlbumOperationViewController.delegate = self;
    tagAlbumOperationViewController.holdedBy = @"PageViewController";
    tagAlbumOperationViewController.view.hidden = YES;
    [self addChildViewController:tagAlbumOperationViewController];
    [self.view addSubview:tagAlbumOperationViewController.view];
    
    _tagAlbumOperationView = tagAlbumOperationViewController.view;
}

- (NSMutableDictionary *)getYearMonthMap
{
    NSMutableDictionary *yearMonthMap = [_currentDisplayedPageContentViewController getYearMonthMap];
    return yearMonthMap;
}

- (NSString *)getDisplayedChildObjectId
{
    return [[_childProperties objectAtIndex:_currentPageIndex] objectForKey:@"objectId"];
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
