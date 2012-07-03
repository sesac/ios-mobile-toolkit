#import "UIImage+Undeferred.h"

@implementation UIImage (Undeferred)

+ (UIImage *)imageInVideoRamWithData:(NSData *)data {
	UIImage *originalImage = [[UIImage alloc] initWithData:data];
	
	if (!originalImage)
		return nil; 
	
	CGImageRef originalImageRef = [originalImage CGImage];
	
	CGContextRef surfaceContext = CGBitmapContextCreate(NULL, originalImage.size.width, originalImage.size.height,
											  CGImageGetBitsPerComponent(originalImageRef), CGImageGetBytesPerRow(originalImageRef),
											  CGImageGetColorSpace(originalImageRef), CGImageGetBitmapInfo(originalImageRef));
    
	if (!surfaceContext)
		return [originalImage autorelease];
	
	CGContextDrawImage(surfaceContext, CGRectMake(0,0, originalImage.size.width, originalImage.size.height), originalImageRef);
	CGImageRef surfaceImageRef = CGBitmapContextCreateImage(surfaceContext);
	
	CGContextRelease(surfaceContext);
	
	UIImage *surfaceImage = [UIImage imageWithCGImage:surfaceImageRef];
	
	CGImageRelease(surfaceImageRef);
    
	[originalImage release];
    
	return surfaceImage;
}

@end