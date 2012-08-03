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