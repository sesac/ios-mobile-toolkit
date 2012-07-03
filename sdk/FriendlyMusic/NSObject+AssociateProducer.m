#import "NSObject+AssociateProducer.h"
#import <objc/runtime.h>

@interface CancellationWrapper : NSObject

@property (nonatomic, copy) CancelCallback cancellation;

@end

@implementation CancellationWrapper

@synthesize cancellation;

+ (CancellationWrapper *)wrapperWithCancellation:(CancelCallback)cancellation {
    assert(cancellation != nil);
    CancellationWrapper *w = [[CancellationWrapper alloc] init];
    w.cancellation = cancellation;
    return w;
}

- (void)dealloc {
    cancellation();
}

@end

@implementation NSObject (AssociateProducer)

static void *CancellationKey;

- (void)deassociateProducer {
    objc_setAssociatedObject(self, &CancellationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)associateProducer:(Producer)producer callback:(ResultCallback)callback {
    CancelCallback cancellation = producer(callback, ^ (id error) {
        // TODO display something, retry, etc
    });
    CancellationWrapper *wrapper = cancellation ? [CancellationWrapper wrapperWithCancellation:cancellation] : nil;
    objc_setAssociatedObject(self, &CancellationKey, wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
