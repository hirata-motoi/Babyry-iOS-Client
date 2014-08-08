//
//  ImagePageViewController.m
//  babyry
//
//  Created by hirata.motoi on 2014/07/26.
//  Copyright (c) 2014年 jp.co.meaning. All rights reserved.
//

#import "ImagePageViewController.h"
#import "UploadViewController.h"
#import "ImageCache.h"

@interface ImagePageViewController ()

@end

@implementation ImagePageViewController

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
    self.dataSource = self;
    self.delegate = self;
   
    [self setupDataSource];
    [self showInitialImage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupDataSource
{
    _imageList = [[NSMutableArray alloc]init];
    NSInteger sectionIndex = 0;
    for (NSDictionary *sectionInfo in _childImages) {
        if (sectionIndex  == _currentSection) {
            _currentIndex = _imageList.count + _currentRow;
        }
       
        //NSLog(@"sectionInfo : %@", sectionInfo);
        NSArray *images = [sectionInfo objectForKey:@"images"];
        [_imageList addObjectsFromArray:images];
        sectionIndex += 1;
    }
}

- (UploadViewController *)viewControllerAtIndex:(NSInteger)index
{
    PFObject *imageInfo = [_imageList objectAtIndex:index];
    
    UploadViewController *uploadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UploadViewController"];
    uploadViewController.childObjectId = _childObjectId;
    uploadViewController.name = _name;
   
    NSString *ymd   = [imageInfo[@"date"] substringWithRange:NSMakeRange(1, 8)];
    NSString *year  = [ymd substringWithRange:NSMakeRange(0, 4)];
    NSString *month = [ymd substringWithRange:NSMakeRange(4, 2)];
    
    uploadViewController.month = [NSString stringWithFormat:@"%@%@", year, month];
    uploadViewController.date = ymd;
    uploadViewController.tagAlbumPageIndex = index;
    uploadViewController.holdedBy = @"TagAlbumPageViewController";
    
    // Cacheからはりつけ
    NSString *imageCachePath = [NSString stringWithFormat:@"%@%@thumb", _childObjectId, ymd];
    NSData *imageCacheData = [ImageCache getCache:imageCachePath];
    if(imageCacheData) {
        uploadViewController.uploadedImage = [UIImage imageWithData:imageCacheData];
    } else {
        uploadViewController.uploadedImage = [UIImage imageNamed:@"NoImage"];
    }
    uploadViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  
    uploadViewController.promptText = [NSString stringWithFormat:@"%ld/%ld", index + 1, _childImages.count];
    
    return uploadViewController;
}

- (void)showInitialImage
{
    UploadViewController *uploadViewController  = [self viewControllerAtIndex:_currentIndex];
    NSArray *viewControllers = @[uploadViewController];
    [self setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [uploadViewController didMoveToParentViewController:self];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    UploadViewController *uploadViewController = (UploadViewController *)viewController;
    
    NSInteger index = uploadViewController.tagAlbumPageIndex;
    
    if (index == NSNotFound || index == 0) {
        return nil;
    }
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    UploadViewController *uploadViewController = (UploadViewController *)viewController;
    
    NSInteger index = uploadViewController.tagAlbumPageIndex;
    if (index == NSNotFound || index == self.imageList.count - 1) {
        return nil;
    }
    index++;
    return [self viewControllerAtIndex:index];
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
