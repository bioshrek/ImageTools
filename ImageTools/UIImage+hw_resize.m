//
//  UIImage+hw_resize.m
//  ImageTools
//
//  Created by 王欢 on 8/19/16.
//  Copyright © 2016 HuanWang. All rights reserved.
//

#import "UIImage+hw_resize.h"

#pragma mark - Orientation Encoding

NSInteger mod(NSInteger x, NSInteger y)
{
    NSInteger result = x % y;
    return result >= 0 ? result : (result + y);
}

/**
 *  将up, left, down, right四个方向编码，方便计算他们之间的差异
 *
 *    - up -> right -> down -> left -
 *   |                               |
 *    ----- < --------- < -----------
 */

typedef NS_ENUM(NSInteger, UIImageOrientationCode) {
    UIImageOrientationCodeUp = 0,
    UIImageOrientationCodeRight = 1,
    UIImageOrientationCodeDown = 2,
    UIImageOrientationCodeLeft = 3,
    UIImageOrientationCodeAll = 4,
};

/**
 *  编码orientation之间的差异，旋转90度
 *
 *    - up -> right -> down -> left -
 *   |                               |
 *    ----- < --------- < -----------
 */

typedef NS_ENUM(NSInteger, UIImageOrientationRotation) {
    UIImageOrientationRotationNone = 0,
    UIImageOrientationRotation_PI_2 = 1,  // 1/2 PI
};

/**
 *  将UIImageOrientation重新编码，由2个分量控制：code + mirroed
 */

@interface UIImageOrientationEncoding : NSObject

/**
 *  是否是镜像
 */

@property (nonatomic, assign) BOOL mirrored;

/**
 *  up, left, down, right四个方向
 */

@property (nonatomic, assign) UIImageOrientationCode code;

- (instancetype)initWithCode:(UIImageOrientationCode)code
                     mirrored:(BOOL)mirrored;

+ (instancetype)encodingWithCode:(UIImageOrientationCode)code
                         mirrored:(BOOL)mirrored;

@end

@implementation UIImageOrientationEncoding

- (instancetype)initWithCode:(UIImageOrientationCode)code
                     mirrored:(BOOL)mirrored
{
    if (self = [super init]) {
        
        _code = code;
        _mirrored = mirrored;
        
    }
    return self;
}

+ (instancetype)encodingWithCode:(UIImageOrientationCode)code
                         mirrored:(BOOL)mirrored
{
    return [[self alloc] initWithCode:code mirrored:mirrored];
}

@end

@implementation UIImage (hw_resize)

#pragma mark - resize

- (UIImage *)hw_resizedImageToSize:(CGSize)targetSize
                    scaleIfSmaller:(BOOL)scale
{
	const CGSize normalizedSize = [[self class] normalizeSize:targetSize imageOrientation:self.imageOrientation];
	const CGSize boundingSize = CGSizeMake(normalizedSize.width * self.scale,
										  normalizedSize.height * self.scale);
	
    CGImageRef imgRef = self.CGImage;
    // the below values are regardless of orientation : for UIImages from Camera, width>height (landscape)
    CGSize  srcSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef)); // not equivalent to self.size (which is dependant on the imageOrientation)!
    
    if (0 == srcSize.width
        ||
        0 == srcSize.height) {
        return self;
    }
    
    /* Don't resize if we already meet the required destination size. */
    if ((srcSize.width == boundingSize.width && srcSize.height == boundingSize.height)
        ||
        (srcSize.height == boundingSize.width && srcSize.width == boundingSize.height)) {
        return self;
    }
    
    // aspect to fit
    CGSize scaledSize = [self scaledSizeForSize:srcSize
                               withBoundingSize:boundingSize
                                 scaleIfSmaller:scale];
    CGImageRef resizedCGImage = [self resizeCGImage:imgRef
                                           withSize:scaledSize];
    if (NULL == resizedCGImage) {
        return nil;
    }
    UIImage* resizedImage = [UIImage imageWithCGImage:resizedCGImage
                                                scale:self.scale
                                          orientation:self.imageOrientation];
    CFRelease(resizedCGImage);
    
    return resizedImage;
}

+ (CGSize)normalizeSize:(CGSize)size imageOrientation:(UIImageOrientation)imageOrientation
{
	CGAffineTransform transform = [self transformFromSourceOrientation:UIImageOrientationUp
															 toDestOrientation:imageOrientation
																		  size:size];
	return CGSizeApplyAffineTransform(size, transform);
}

- (CGSize)scaledSizeForSize:(CGSize)srcSize
           withBoundingSize:(CGSize)boundingSize
{
    if (0 == srcSize.width
        ||
        0 == srcSize.height) {
        return CGSizeZero;
    }
    
    // aspect to fit
    CGFloat scaleRatio = 1;
    CGSize destSize = srcSize;
    if (srcSize.width > srcSize.height) {
        // bounding width, height
        CGFloat boundingWidth = boundingSize.width;
        CGFloat boundingHeight = boundingSize.height;
        if (boundingWidth < boundingHeight) {
            boundingWidth = boundingSize.height;
            boundingHeight = boundingSize.width;
        }
        
        scaleRatio = boundingWidth / srcSize.width;
        destSize = CGSizeMake(boundingWidth, srcSize.height * scaleRatio);
    } else {
        // bounding width, height
        CGFloat boundingWidth = boundingSize.width;
        CGFloat boundingHeight = boundingSize.height;
        if (boundingWidth > boundingHeight) {
            boundingWidth = boundingSize.height;
            boundingHeight = boundingSize.width;
        }
        
        scaleRatio = boundingHeight / srcSize.height;
        destSize = CGSizeMake(srcSize.width * scaleRatio, boundingHeight);
    }
    return destSize;
}

- (CGSize)scaledSizeForSize:(CGSize)srcSize
           withBoundingSize:(CGSize)boundingSize
             scaleIfSmaller:(BOOL)scale
{
    CGRect srcRect = CGRectMake(0, 0, srcSize.width, srcSize.height);
    CGRect boundingRect = CGRectMake(0, 0, boundingSize.width, boundingSize.height);
    if (CGRectContainsRect(boundingRect, srcRect) && !scale) {
        return srcSize;
    }
    
    return [self scaledSizeForSize:srcSize withBoundingSize:boundingSize];
}

- (CGImageRef)resizeCGImage:(CGImageRef)image
                   withSize:(CGSize)size
{
    // !!! important
    // use CGFloat value will cause CGPostError when calling CGBitmapContextCreate
    size_t width = ceil(size.width);
    size_t height = ceil(size.height);
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
    size_t numberOfComponents = CGColorSpaceGetNumberOfComponents(colorSpace) + 1;  // alpha channel
    size_t bitsPerComponent = CGImageGetBitsPerComponent(image);
    size_t bytesPerRow = width * numberOfComponents * bitsPerComponent / 8;
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(image);
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 bitmapInfo);
    
    if (!context) {
        return NULL;
    }
    
    // we use srcSize (and not dstSize) as the size to specify is in user space (and we use the CTM to apply a scaleRatio)
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), image);
    CGImageRef resizedCGImage = CGBitmapContextCreateImage(context);
    
    CFRelease(context);
    return resizedCGImage;
}

#pragma mark - orientation

- (UIImage *)hw_transformImageToOrientation:(UIImageOrientation)orientation
{
    CGImageRef transformedCGImage = [self hw_CGImageForOrientation:orientation];
    if (NULL == transformedCGImage) {
        return nil;
    }
    
    UIImage *transformedImage =
    [UIImage imageWithCGImage:transformedCGImage
                        scale:self.scale
                  orientation:orientation];
    CFRelease(transformedCGImage);
    
    return transformedImage;
}

// you should release imageRef when you finish using it.
- (CGImageRef)hw_CGImageForOrientation:(UIImageOrientation)orientation
{
    CGImageRef CGImage = self.CGImage;
    CGSize srcSize = CGSizeMake(CGImageGetWidth(CGImage),
                                CGImageGetHeight(CGImage));
    if (0 == srcSize.width
        ||
        0 == srcSize.height) {
        return CGImage;
    }
    
    return
    [[self class] transformCGImage:CGImage
                   fromOrientation:self.imageOrientation
                     toOrientation:orientation
                         imageSize:srcSize];
}

+ (CGImageRef)transformCGImage:(CGImageRef)image
               fromOrientation:(UIImageOrientation)srcOrientation
                 toOrientation:(UIImageOrientation)destOrientation
                     imageSize:(CGSize)size
{
    CGAffineTransform transform =
    [self transformFromSourceOrientation:srcOrientation
                       toDestOrientation:destOrientation
                                    size:size];
    
    CGSize drawSize = CGSizeApplyAffineTransform(size, transform);
    
    // !!! important
    // use CGFloat value will cause CGPostError when calling CGBitmapContextCreate
    size_t width = ceil(drawSize.width);
    size_t height = ceil(drawSize.height);
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
    size_t numberOfComponents = CGColorSpaceGetNumberOfComponents(colorSpace) + 1;  // alpha channel
    size_t bitsPerComponent = CGImageGetBitsPerComponent(image);
    size_t bytesPerRow = width * numberOfComponents * bitsPerComponent / 8;
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(image);
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 bitmapInfo);
    
    if (!context) {
        return NULL;
    }
    
    CGContextConcatCTM(context, transform);
    
    // we use srcSize (and not dstSize) as the size to specify is in user space (and we use the CTM to apply a scaleRatio)
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), image);
    CGImageRef resizedCGImage = CGBitmapContextCreateImage(context);
    
    CFRelease(context);
    return resizedCGImage;
}

+ (CGAffineTransform)transformFromSourceOrientation:(UIImageOrientation)src
                                  toDestOrientation:(UIImageOrientation)dest
                                               size:(CGSize)size
{
    if (src == dest) {
        return CGAffineTransformIdentity;
    }
    
    UIImageOrientationEncoding *srcEncoding = [self encodingForOrientation:src];
    UIImageOrientationEncoding *destEncoding = [self encodingForOrientation:dest];
    
    // rotation
    
    NSInteger rotation = mod((destEncoding.code - srcEncoding.code),
                             UIImageOrientationCodeAll);
    CGAffineTransform rotationTransform =
    [self transformWithRotation:rotation
                           size:size
                       mirrored:srcEncoding.mirrored];
    
    // flip
    
    BOOL sizeFlipped = (rotation % 2);
    CGFloat flippingWidth = sizeFlipped ? size.height : size.width;
    BOOL flipped = (destEncoding.mirrored != srcEncoding.mirrored);
    CGAffineTransform flipTransform = flipped ?
    [self transformForFlippingWithWidth:flippingWidth] : CGAffineTransformIdentity;
    
    return CGAffineTransformConcat(rotationTransform, flipTransform);
}

+ (CGAffineTransform)transformWithRotation:(NSInteger)rotation
                                      size:(CGSize)size
                                  mirrored:(BOOL)mirrored
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    if (!mirrored) {
        switch (rotation) {
            case UIImageOrientationRotationNone: {
            } break;
            case UIImageOrientationRotation_PI_2: {
                transform = CGAffineTransformTranslate(transform, size.height, 0);
                transform = CGAffineTransformRotate(transform, M_PI_2);
            } break;
            case UIImageOrientationRotation_PI_2 * 2: {
                transform = CGAffineTransformTranslate(transform, size.width, size.height);
                transform = CGAffineTransformRotate(transform, M_PI);
            } break;
            case UIImageOrientationRotation_PI_2 * 3: {
                transform = CGAffineTransformTranslate(transform, 0, size.width);
                transform = CGAffineTransformRotate(transform, M_PI_2 + M_PI);
            } break;
            default: break;
        }
    } else {
        switch (rotation) {
            case UIImageOrientationRotationNone: {
            } break;
            case UIImageOrientationRotation_PI_2 * 3: {
                transform = CGAffineTransformTranslate(transform, size.height, 0);
                transform = CGAffineTransformRotate(transform, M_PI_2);
            } break;
            case UIImageOrientationRotation_PI_2 * 2: {
                transform = CGAffineTransformTranslate(transform, size.width, size.height);
                transform = CGAffineTransformRotate(transform, M_PI);
            } break;
            case UIImageOrientationRotation_PI_2: {
                transform = CGAffineTransformTranslate(transform, 0, size.width);
                transform = CGAffineTransformRotate(transform, M_PI_2 + M_PI);
            } break;
            default: break;
        }
    }
    return transform;
}

+ (CGAffineTransform)transformForFlippingWithWidth:(CGFloat)width
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, width, 0);
    transform = CGAffineTransformScale(transform, -1, 1);
    return transform;
}

+ (UIImageOrientationEncoding *)encodingForOrientation:(UIImageOrientation)orientation
{
    static NSDictionary *encodingsWithOrientationKeys;
    if (nil == encodingsWithOrientationKeys) {
        encodingsWithOrientationKeys =
        @{
          @(UIImageOrientationUp) : [UIImageOrientationEncoding encodingWithCode:UIImageOrientationCodeUp mirrored:NO],
          @(UIImageOrientationRight) : [UIImageOrientationEncoding encodingWithCode:UIImageOrientationCodeRight mirrored:NO],
          @(UIImageOrientationDown) : [UIImageOrientationEncoding encodingWithCode:UIImageOrientationCodeDown mirrored:NO],
          @(UIImageOrientationLeft) : [UIImageOrientationEncoding encodingWithCode:UIImageOrientationCodeLeft mirrored:NO],
          @(UIImageOrientationUpMirrored) : [UIImageOrientationEncoding encodingWithCode:UIImageOrientationCodeUp mirrored:YES],
          @(UIImageOrientationRightMirrored) : [UIImageOrientationEncoding encodingWithCode:UIImageOrientationCodeRight mirrored:YES],
          @(UIImageOrientationDownMirrored) : [UIImageOrientationEncoding encodingWithCode:UIImageOrientationCodeDown mirrored:YES],
          @(UIImageOrientationLeftMirrored) : [UIImageOrientationEncoding encodingWithCode:UIImageOrientationCodeLeft mirrored:YES]
          };
    }
    return encodingsWithOrientationKeys[@(orientation)];
}

@end
