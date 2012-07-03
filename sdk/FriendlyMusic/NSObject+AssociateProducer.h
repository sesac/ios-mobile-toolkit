#import "Async.h"

@interface NSObject (AssociateProducer)

- (void)deassociateProducer;
- (void)associateProducer:(Producer)producer callback:(ResultCallback)callback;

@end
