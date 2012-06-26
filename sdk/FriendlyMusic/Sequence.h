
@interface NSArray (Sequence)

- (NSArray *)map:(id(^)(id))map;
- (id)reduce:(id(^)(id, id))reduce seed:(id)seed;
- (NSArray *)filter:(BOOL(^)(id))filter;
- (BOOL)any:(BOOL(^)(id))predicate;
- (BOOL)all:(BOOL(^)(id))predicate;
- (void)each:(void(^)(id))each;

@end