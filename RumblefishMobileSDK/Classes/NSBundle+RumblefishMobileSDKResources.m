#import "NSBundle+RumblefishMobileSDKResources.h"

@implementation NSBundle (RumblefishMobileSDKResources)

+ (NSBundle *)rumblefishResourcesBundle {
    return [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"RumblefishMobileSDKResources" withExtension:@"bundle"]];
}

@end
