
typedef void (^CancelCallback)();
typedef void (^ResultCallback)(id);
typedef void (^ErrorCallback)(id);
typedef CancelCallback (^Producer)(ResultCallback, ErrorCallback);

@interface NSArray (ParallelProducers)

- (Producer)parallelProducer;

@end

@interface NSObject (MaterializedProducer)

- (Producer)producerWithDelay:(NSTimeInterval)delay;

@end

@interface NSError (ErrorProducer)

- (Producer)errorProducer;

@end

@interface Async : NSObject

+ (Producer)continueAfterProducer:(Producer)producer withSelector:(Producer (^)(id))selector;
+ (Producer)continueAfterProducer:(Producer)producer withSelector:(Producer (^)(id))selector errorSelector:(Producer (^)(id))errorSelector;
+ (Producer)mapResultOfProducer:(Producer)producer withSelector:(id (^)(id))selector;
+ (void)fireAndForgetProducer:(Producer)producer;

@end