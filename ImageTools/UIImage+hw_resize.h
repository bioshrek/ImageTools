//
//  UIImage+hw_resize.h
//  ImageTools
//
//  Created by 王欢 on 8/19/16.
//  Copyright © 2016 HuanWang. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  一些和图片缩放，方向有关的category
 */

@interface UIImage (hw_resize)

/**
 *  伸缩图片大小
 */

- (UIImage *)hw_resizedImageToSize:(CGSize)boundingSize
                    scaleIfSmaller:(BOOL)scale;

/**
 *  根据方向，返回对应的bitmap
 *
 *  UIImage = bitmap + orientation
 *
 *  @return 返回对应方向的bitmap。用完后，调用者应该释放它
 */

- (CGImageRef)hw_CGImageForOrientation:(UIImageOrientation)orientation;

/**
 *  返回变换方向后的图片
 *
 *  此方法内部调用了@selector(hw_CGImageForOrientation:)
 */

- (UIImage *)hw_transformImageToOrientation:(UIImageOrientation)orientation;

/**
 *  从一个orientation变换到另一个orientation需要作出的transform
 */
+ (CGAffineTransform)transformFromSourceOrientation:(UIImageOrientation)src
								  toDestOrientation:(UIImageOrientation)dest
											   size:(CGSize)size;

@end
