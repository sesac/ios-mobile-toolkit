#import "RFAPI.h"

@interface LocalPlaylist : NSObject {
    NSArray *contents;
}

+ (LocalPlaylist *)sharedPlaylist;

@property (nonatomic, readonly) NSUInteger count;

- (void)addToPlaylist:(Media *)media;
- (void)removeFromPlaylist:(Media *)media;
- (BOOL)existsInPlaylist:(Media *)media;

@end
