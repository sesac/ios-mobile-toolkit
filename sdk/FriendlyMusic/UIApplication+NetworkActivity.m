#import "UIApplication+NetworkActivity.h"

static NSInteger count;

@implementation UIApplication (NetworkActivity)

- (void)networkActivityDidBegin {
    if (++count == 1)
        self.networkActivityIndicatorVisible = YES;
    
}
- (void)networkActivityDidEnd {
    
    if (--count == 0)
        self.networkActivityIndicatorVisible = NO;
}

@end
