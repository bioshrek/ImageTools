//
//  UIImage+clip.m
//  TemplateDemo
//
//  Created by Huan WANG on 21/02/2017.
//  Copyright © 2017 Knowbox. All rights reserved.
//

#import "UIImage+clip.h"
#import "UIImage+hw_resize.h"

@implementation UIImage (clip)

- (UIImage *)clipToRect:(CGRect)clippingRect
{
	// 尊重图片的orientation，scale
	// UIImage = bitmap(CGImage) + scale + orientation
	// 裁剪时clippingRect是指orientation为UIImageOrientationUp时的值，
	// 所以先将clippingRect转化为图片的orientation（不一定是UIImageOrientationUp）对应的rect
	// 方法如下：
	CGAffineTransform transform =
	[[self class] transformFromSourceOrientation:UIImageOrientationUp
							   toDestOrientation:self.imageOrientation
											size:self.size];
	const CGRect subRect = CGRectApplyAffineTransform(clippingRect, transform);
	
	// 然后将rect的单位从point变为pixel
	const CGRect subRectInPixels = CGRectMake(subRect.origin.x * self.scale,
											  subRect.origin.y * self.scale,
											  subRect.size.width * self.scale,
											  subRect.size.height * self.scale);
	
	// 调用库函数CGImageCreateWithImageInRect完成bitmap裁剪
	CGImageRef bitmap = CGImageCreateWithImageInRect(self.CGImage, subRectInPixels);
	
	// 最后，裁剪后的图片不改变图片的scale, orientation属性
	UIImage *img = [UIImage imageWithCGImage:bitmap scale:self.scale orientation:self.imageOrientation];
	CFRelease(bitmap);
	return img;
}

@end
