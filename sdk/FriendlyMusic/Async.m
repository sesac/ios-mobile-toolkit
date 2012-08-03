/*
 Rumblefish Mobile Toolkit for iOS
 
 Copyright 2012 Rumblefish, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may
 not use this file except in compliance with the License. You may obtain
 a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 License for the specific language governing permissions and limitations
 under the License.
 
 Use of the Rumblefish Sandbox in connection with this file is governed by
 the Sandbox Terms of Use found at https://sandbox.rumblefish.com/agreement
 
 Use of the Rumblefish API for any commercial purpose in connection with
 this file requires a written agreement with Rumblefish, Inc.
 */

 #import "Async.h"

@implementation NSArray (ParallelProducers)

- (Producer)parallelProducer {
    if ([self isKindOfClass:[NSMutableArray class]]) {
        NSLog(@"Cannot create parallel producer from mutable array.");
        assert(NO);
    }
    
    return [[^ CancelCallback (ResultCallback resultCb, ErrorCallback errorCb) {
        __block NSMutableArray *cancels = [[NSMutableArray alloc] init];
        __block NSMutableArray *results = [[NSMutableArray alloc] init];
        __block NSInteger completed = 0;
        __block BOOL cancelled = NO;
        
        NSInteger total = self.count;
        
        for (int i = 0; i < total; i++)
            [results addObject:[NSNull null]];
        
        CancelCallback cancel = ^ void () {
            if (cancelled) return;
            cancelled = YES;
            
            for (CancelCallback c in cancels)
                c();
            
            [cancels release];
            cancels = nil;
            [results release];
            results = nil;
        };
        
        // wtf compiler
        ErrorCallback onError = (ErrorCallback)^ void (id e) {
            cancel();
            errorCb(e);
        };
        
        for (int i = 0; i < total; i++) {
            Producer p = [self objectAtIndex:i];
            
            ResultCallback onResult = ^ void (id result) {
                completed++;
                [results replaceObjectAtIndex:i withObject:result];
                
                if (completed == total) {
                    NSArray *r = [results copy];
                    cancel();
                    resultCb(r);
                    [r release];
                }
            };
            
            id thing = p(onResult, onError);
            
            if (cancelled) break;
            
            [cancels addObject:thing];
        }
        
        return [[cancel copy] autorelease];
    } copy] autorelease];
}

@end

@interface MaterializedProducerHelper : NSObject {
    NSTimeInterval delay;
    id result;
    ResultCallback callback;
}

- (id)initWithResult:(id)result callback:(ResultCallback)callback delay:(NSTimeInterval)delay;

@end

@implementation MaterializedProducerHelper

- (id)initWithResult:(id)leResult callback:(ResultCallback)leCallback delay:(NSTimeInterval)leDelay {
    if ((self = [super init])) {
        result = [leResult retain];
        callback = [leCallback copy];
        delay = leDelay;
    }
    return self;
}

- (void)releaseAll {
    [result release];
    result = nil;
    [callback release];
    callback = nil;
}

- (void)dealloc {
    [self releaseAll];
    [super dealloc];
}

- (void)start {
    [self performSelector:@selector(yield) withObject:nil afterDelay:delay];
}

- (void)cancel {
    [self releaseAll];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)yield {
    id r = [result retain];
    ResultCallback cb = [callback copy];
    [self releaseAll];
    cb(r);
    [r release];
    [cb release];
}

@end

@implementation NSObject (MaterializedProducer)

- (Producer)producerWithDelay:(NSTimeInterval)delay {
    return [[^ CancelCallback (ResultCallback resultCb, ErrorCallback errorCb) {
        MaterializedProducerHelper *helper = [[[MaterializedProducerHelper alloc] initWithResult:self callback:resultCb delay:delay] autorelease];
        [helper start];
        return [[^ void() { [helper cancel]; } copy] autorelease];
    } copy] autorelease];
}

@end

@implementation NSError (ErrorProducer)

- (Producer)errorProducer {
    return [[^ CancelCallback (ResultCallback onResult, ErrorCallback onError) {
        onError(self);
        return [[^ void() { } copy] autorelease];
    } copy] autorelease];
}

@end

@implementation Async

+ (Producer)continueAfterProducer:(Producer)producer withSelector:(Producer (^)(id))selector {
    return [Async continueAfterProducer:producer withSelector:selector errorSelector:nil];
}

+ (Producer)continueAfterProducer:(Producer)producer withSelector:(Producer (^)(id))selector errorSelector:(Producer (^)(id))errorSelector {
    return [[^ CancelCallback (ResultCallback resultCb, ErrorCallback errorCb) {
        __block CancelCallback 
        antecedentCancel = nil,
        resultantCancel = nil;
        
        CancelCallback cancelAntecendent = ^ void () {
            if (antecedentCancel) {
                antecedentCancel();
                [antecedentCancel release];
                antecedentCancel = nil;
            }
        };
        
        CancelCallback cancel = ^ void () {
            cancelAntecendent();
            
            if (resultantCancel) {
                resultantCancel();
                [resultantCancel release];
                resultantCancel = nil;
            }
        };
        
        antecedentCancel = [producer(
                                     selector ? ^ void (id result) {
                                         cancelAntecendent();
                                         Producer selectedProducer = selector(result);
                                         if (selectedProducer)
                                             resultantCancel = [selectedProducer(resultCb, errorCb) copy];
                                         else
                                             resultCb(result);
                                     } : resultCb, 
                                     errorSelector ? ^ void (id error) { 
                                         cancelAntecendent();
                                         Producer selectedProducer = errorSelector(error);
                                         if (selectedProducer)
                                             resultantCancel = [selectedProducer(resultCb, errorCb) copy];
                                         else
                                             errorCb(error);
                                     } : errorCb) copy];
        
        return [[cancel copy] autorelease];
    } copy] autorelease];
}

+ (Producer)mapResultOfProducer:(Producer)producer withSelector:(id (^)(id))selector {
    return [[^ CancelCallback (ResultCallback resultCb, ErrorCallback errorCb) {
        return producer(^ void (id result) { resultCb(selector(result)); }, errorCb);
    } copy] autorelease];
}

+ (void)fireAndForgetProducer:(Producer)producer {
    CancelCallback cancelCb = nil;
    
    void (^cancel)() = ^ void () {
        if (cancelCb != nil) {
            cancelCb();
            [cancelCb release];
        }
    };
    
    cancelCb = [producer(^ void (id result) { cancel(); }, ^ void (id error) { cancel(); }) copy];
}

@end