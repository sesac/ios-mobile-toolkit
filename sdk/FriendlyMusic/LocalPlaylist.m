#import "LocalPlaylist.h"
#import "Sequence.h"

static NSString *playlistFilePath;
static LocalPlaylist *shared;

@interface LocalPlaylist ()

@property (nonatomic, strong) NSArray *contents;

@end

@implementation LocalPlaylist

@synthesize contents;

+ (void)initialize {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    playlistFilePath = [documentsDirectory stringByAppendingPathComponent:@"playlist.plist"];
}

+ (LocalPlaylist *)sharedPlaylist {
    if (!shared)
        shared = [LocalPlaylist new];
    return shared;
}

- (NSUInteger)count {
    return contents.count;
}

- (NSMutableArray *)readPlaylist {
    return [[[NSMutableDictionary dictionaryWithContentsOfFile:playlistFilePath] objectForKey:@"media"] mutableCopy];
}

- (void)flushPlaylist {
    [[NSDictionary dictionaryWithObject:contents forKey:@"media"] writeToFile:playlistFilePath atomically:YES];
}

- (id)init {
    if (self = [super init]) {
        self.contents = [self readPlaylist];
        
        if (!self.contents)
            self.contents = [NSArray array];
    }
    return self;
}

- (void)addToPlaylist:(Media *)media {
    self.contents = [self.contents arrayByAddingObject:[NSNumber numberWithInt:media.ID]];
    [self flushPlaylist];
}

- (void)removeFromPlaylist:(Media *)media {
    self.contents = [contents filter:^ BOOL (id i) { return [((NSNumber *)i) intValue] != media.ID; }];
    [self flushPlaylist];
}

- (BOOL)existsInPlaylist:(Media *)media {
    return [contents any:^ BOOL (id i) { return [((NSNumber *)i) intValue] == media.ID; }];
}

@end
