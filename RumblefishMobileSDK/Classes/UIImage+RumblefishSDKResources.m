#import "UIImage+RumblefishSDKResources.h"
#import "NSBundle+RumblefishMobileSDKResources.h"

@implementation UIImage (RumblefishSDKResources)

+ (UIImage *)imageInResourceBundleNamed:(NSString *)name {
    return [UIImage imageWithContentsOfFile:[[NSBundle rumblefishResourcesBundle] pathForResource:name ofType:nil]];
}

@end
