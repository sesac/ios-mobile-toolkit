#import "Sequence.h"

@implementation NSArray (Sequence)

- (NSArray *)map:(id(^)(id))map {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    
    for (id obj in self)
        [result addObject:map(obj)];
    
    return [result copy];
}

- (id)reduce:(id(^)(id, id))reduce seed:(id)seed {
    for (id obj in self)
        seed = reduce(seed, obj);
    
    return seed;
}

- (NSArray *)filter:(BOOL(^)(id))filter {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count / 2];
    
    for (id obj in self)
        if (filter(obj))
            [result addObject:obj];
    
    return [result copy];
}

- (BOOL)any:(BOOL(^)(id))predicate {
    for (id obj in self)
        if (predicate(obj))
            return YES;
    return NO;
}

- (BOOL)all:(BOOL(^)(id))predicate {
    for (id obj in self)
        if (!predicate(obj))
            return NO;
    return YES;
}

- (void)each:(void(^)(id))each {
    for (id obj in self)
        each(obj);
}

@end