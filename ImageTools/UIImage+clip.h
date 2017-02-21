//
//  UIImage+clip.h
//  TemplateDemo
//
//  Created by Huan WANG on 21/02/2017.
//  Copyright © 2017 Knowbox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (clip)

// 裁剪图片，尊重图片的scale, orientation
- (UIImage *)clipToRect:(CGRect)clippingRect;

@end
