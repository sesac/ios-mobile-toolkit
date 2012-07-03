
@interface UIImage (Undeferred)

// [UIImage imageWithData:] is O(1) because the image data is not loaded into VRAM until 
// the system goes to draw it—which happens on the main thread and runs in linear time with
// the size of the image.
// This method returns a UIImage whose surface is already in VRAM and will rendered in constant
// time on the main thread.
+ (UIImage *)imageInVideoRamWithData:(NSData *)data;

@end