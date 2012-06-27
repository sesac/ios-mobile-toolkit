#import "LocalPlaylist.h"
#import "Sequence.h"
#import "RFAPI.h"

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

- (NSArray *)readPlaylist {
    return [[[NSMutableDictionary dictionaryWithContentsOfFile:playlistFilePath] objectForKey:@"media"] map:^ id (id m) {
        return [[Media alloc] initWithDictionary:m];
    }];
}

- (void)flushPlaylist {
    [[NSDictionary dictionaryWithObject:[contents map:^ id (id m) { return [((Media *)m) dictionaryRepresentation]; }] forKey:@"media"] writeToFile:playlistFilePath atomically:YES];
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
    self.contents = [self.contents arrayByAddingObject:media];
    [self flushPlaylist];
}

- (void)removeAtIndex:(NSUInteger)index {
    NSMutableArray *mutableCopy = [self.contents mutableCopy];
    [mutableCopy removeObjectAtIndex:index];
    self.contents = [mutableCopy copy];
}

- (void)removeFromPlaylist:(Media *)media {
    self.contents = [contents filter:^ BOOL (id m) { return ![((Media *)m) isEqual:media]; }];
    [self flushPlaylist];
}

- (BOOL)existsInPlaylist:(Media *)media {
    return [contents any:^ BOOL (id m) { return [((Media *)m) isEqual:media]; }];
}

- (Media *)mediaAtIndex:(NSUInteger)index {
    return (Media *)[self.contents objectAtIndex:index];
}

- (void)clear {
    self.contents = [NSArray array];
    [self flushPlaylist];
}

@end
