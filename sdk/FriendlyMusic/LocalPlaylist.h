#import "RFAPI.h"

@interface LocalPlaylist : NSObject {
    NSArray *contents;
}

+ (LocalPlaylist *)sharedPlaylist;

@property (nonatomic, readonly) NSUInteger count;

- (void)addToPlaylist:(Media *)media;
- (void)removeFromPlaylist:(Media *)media;
- (void)removeAtIndex:(NSUInteger)index;
- (Media *)mediaAtIndex:(NSUInteger)index;
- (BOOL)existsInPlaylist:(Media *)media;
- (void)clear;

@end
