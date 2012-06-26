#import "Async.h"

@interface UIViewController (Async)

- (void)associateProducer:(Producer)producer callback:(ResultCallback)callback;

@end
