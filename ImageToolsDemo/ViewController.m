//
//  ViewController.m
//  ImageTools
//
//  Created by 王欢 on 8/19/16.
//  Copyright © 2016 HuanWang. All rights reserved.
//

#import "ViewController.h"
#import <PureLayout/PureLayout.h>
#import "PureLayoutExtension.h"
#import "UIImage+hw_resize.h"

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

// views

@property (nonatomic, weak) UIView *topContainer;
@property (nonatomic, weak) UIView *bottomContainer;
@property (nonatomic, weak) UILabel *transformedLabel;
@property (nonatomic, weak) UIImageView *transformedImageView;
@property (nonatomic, weak) UILabel *bitmapLabel;
@property (nonatomic, weak) UIImageView *bitmapImageView;

// data

@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, assign) NSInteger selectedButtonIndex;

@end

@implementation ViewController

- (void)loadView
{
    self.view = [[UIView alloc] init];
    
    // views
    
    UIView *topContainer = [UIView newAutoLayoutView];
    UIView *bottomContainer = [UIView newAutoLayoutView];
    UILabel *transformedLabel = [UILabel newAutoLayoutView];
    UIImageView *transformedImageView = [UIImageView newAutoLayoutView];
    UILabel *bitmapLabel = [UILabel newAutoLayoutView];
    UIImageView *bitmapImageView = [UIImageView newAutoLayoutView];
    [self.view addSubview:topContainer];
    [self.view addSubview:bottomContainer];
    [self.view addSubview:transformedLabel];
    [self.view addSubview:transformedImageView];
    [self.view addSubview:bitmapLabel];
    [self.view addSubview:bitmapImageView];
    _topContainer = topContainer;
    _bottomContainer = bottomContainer;
    _transformedLabel = transformedLabel;
    _transformedImageView = transformedImageView;
    _bitmapLabel = bitmapLabel;
    _bitmapImageView = bitmapImageView;
    
    // buttons
    
    [self renderButtonsInContainer:self.topContainer
                      buttonAction:@selector(topButtonTapped:)
                        startIndex:0];
    [self renderButtonsInContainer:self.bottomContainer
                      buttonAction:@selector(bottomButtonTapped:)
                        startIndex:4];
    
    // layout
    
    [self.view setNeedsUpdateConstraints];
    
    [@[self.topContainer,
       self.bottomContainer,
       self.transformedLabel,
       self.transformedImageView,
       self.bitmapLabel,
       self.bitmapImageView]
     autoFillViewsAlongAxis:ALAxisVertical
     withFixedSpacings:@[ @8, @12, @8, @12, @8 ]
     edgeInsets:UIEdgeInsetsMake(20 + 12, 12, 12, 12)];
    [self.topContainer autoSetDimension:ALDimensionHeight toSize:44];
    [self.bottomContainer autoSetDimension:ALDimensionHeight toSize:44];
    [self.transformedLabel autoSetDimension:ALDimensionHeight toSize:32];
    [self.bitmapLabel autoSetDimension:ALDimensionHeight toSize:32];
    [@[self.transformedImageView,
       self.bitmapImageView]
     autoMatchViewsDimension:ALDimensionHeight];
    
    // actions
    
    self.transformedImageView.userInteractionEnabled = YES;
    [self.transformedImageView addGestureRecognizer:
     [[UITapGestureRecognizer alloc] initWithTarget:self
                                             action:@selector(changeImage)]];
}

- (void)renderButtonsInContainer:(UIView *)container
                    buttonAction:(SEL)action
                      startIndex:(const NSInteger)startIndex
{
    for (UIView *subView in container.subviews) {
        [subView removeFromSuperview];
    }
    
    for (NSInteger i = startIndex; i < startIndex + 4; i++) {
        UIImageOrientation orientation = [[self class] orientationAtIndex:i];
        UIImage *image = [[self class] imageForOrientation:orientation];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:image forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage imageNamed:@"background_blue"]
                          forState:UIControlStateSelected];
        [button addTarget:self
                   action:action
         forControlEvents:UIControlEventTouchUpInside];
        [container addSubview:button];
    }
    [container.subviews autoFillViewsAlongAxis:ALAxisHorizontal
                              withFixedSpacing:8
                                    edgeInsets:UIEdgeInsetsZero];
    [container.subviews autoMatchViewsDimension:ALDimensionWidth];
}

+ (UIImageOrientation)orientationAtIndex:(NSInteger)index
{
    static NSDictionary *orientationsWithIndexKeys;
    if (nil == orientationsWithIndexKeys) {
        orientationsWithIndexKeys =
        @{
          @(0) : @(UIImageOrientationUp),
          @(1) : @(UIImageOrientationLeft),
          @(2) : @(UIImageOrientationRight),
          @(3) : @(UIImageOrientationDown),
          @(4) : @(UIImageOrientationUpMirrored),
          @(5) : @(UIImageOrientationLeftMirrored),
          @(6) : @(UIImageOrientationRightMirrored),
          @(7) : @(UIImageOrientationDownMirrored)
          };
    }
    
    return [orientationsWithIndexKeys[@(index)] integerValue];
}

+ (NSString *)stringForOrientation:(UIImageOrientation)orientation
{
    static NSDictionary *stringsWithOrientationKeys;
    if (nil == stringsWithOrientationKeys) {
        stringsWithOrientationKeys =
        @{
          @(UIImageOrientationUp) : @"up",
          @(UIImageOrientationLeft) : @"left",
          @(UIImageOrientationRight) : @"right",
          @(UIImageOrientationDown) : @"down",
          @(UIImageOrientationUpMirrored) : @"up m",
          @(UIImageOrientationLeftMirrored) : @"left m",
          @(UIImageOrientationRightMirrored) : @"right m",
          @(UIImageOrientationDownMirrored) : @"down m"
          };
    }
    
    return stringsWithOrientationKeys[@(orientation)];
}

+ (UIImage *)imageForOrientation:(UIImageOrientation)orientation
{
    static NSDictionary *imageNamesWithOrientationKeys;
    if (nil == imageNamesWithOrientationKeys) {
        imageNamesWithOrientationKeys =
        @{
          @(UIImageOrientationUp) : @"orientation_up",
          @(UIImageOrientationLeft) : @"orientation_left",
          @(UIImageOrientationRight) : @"orientation_right",
          @(UIImageOrientationDown) : @"orientation_down",
          @(UIImageOrientationUpMirrored) : @"orientation_up_mirrored",
          @(UIImageOrientationLeftMirrored) : @"orientation_left_mirrored",
          @(UIImageOrientationRightMirrored) : @"orientation_right_mirrored",
          @(UIImageOrientationDownMirrored) : @"orientation_down_mirrored"
          };
    }
    NSString *imageName = imageNamesWithOrientationKeys[@(orientation)];
    return imageName ? [UIImage imageNamed:imageName] : nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.selectedButtonIndex = -1;
    
    self.transformedImageView.image = [UIImage imageNamed:@"picture-add"];
    self.transformedImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.bitmapImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.transformedLabel.text = @"transformed image:";
    self.bitmapLabel.text = @"bitmap:";
}

#pragma mark - Actions

- (void)topButtonTapped:(UIButton *)sender
{
    NSInteger index = [self.topContainer.subviews indexOfObject:sender];
    if (NSNotFound == index) {
        return;
    }
    [self didSelectButtonAtIndex:index];
    
    UIImageOrientation orientation = [[self class] orientationAtIndex:index];
    [self orientationTapped:orientation];
}

- (void)bottomButtonTapped:(UIButton *)sender
{
    NSInteger index = [self.bottomContainer.subviews indexOfObject:sender];
    if (NSNotFound == index) {
        return;
    }
    index += 4;
    [self didSelectButtonAtIndex:index];
    
    UIImageOrientation orientation = [[self class] orientationAtIndex:index];
    [self orientationTapped:orientation];
}

- (void)didSelectButtonAtIndex:(NSInteger)index
{
    if (index == self.selectedButtonIndex) {
        return;
    }
    
    UIButton *selectedButton = [self buttonAtIndex:self.selectedButtonIndex];
    selectedButton.selected = NO;
    
    UIButton *selectingButton = [self buttonAtIndex:index];
    selectingButton.selected = YES;
    
    self.selectedButtonIndex = index;
}

- (UIButton *)buttonAtIndex:(NSInteger)index
{
    UIView *container = nil;
    if (index >= 0 && index < 4) {
        container = self.topContainer;
    } else if (index >= 4 && index < 8) {
        container = self.bottomContainer;
        index -= 4;
    }
    if (nil == container) {
        return nil;
    }
    return container.subviews[index];
}

- (void)orientationTapped:(UIImageOrientation)orientation
{
    if (nil == self.originalImage) {
        return;
    }
    
    CGImageRef CGImage = [self.originalImage hw_CGImageForOrientation:orientation];
    UIImage *transformedImage =
    [UIImage imageWithCGImage:CGImage
                        scale:self.originalImage.scale
                  orientation:orientation];
    CFRelease(CGImage);
    self.originalImage = transformedImage;
}

- (void)changeImage
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [self dismissViewControllerAnimated:YES completion:^{
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        self.originalImage = image;
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Getters, Setters

- (void)setOriginalImage:(UIImage *)originalImage
{
    _originalImage = originalImage;
    
    self.transformedImageView.image = originalImage;
    
    // 选择了UP方向，才能看到bitmap的真正方向
    UIImageOrientation orientation =
        [[self class] orientationAtIndex:self.selectedButtonIndex];
    CGImageRef CGImage = [originalImage hw_CGImageForOrientation:orientation];
    UIImage *bitmapImage =
    [UIImage imageWithCGImage:CGImage
                        scale:originalImage.scale
                  orientation:UIImageOrientationUp];
    self.bitmapImageView.image = bitmapImage;
}

@end
