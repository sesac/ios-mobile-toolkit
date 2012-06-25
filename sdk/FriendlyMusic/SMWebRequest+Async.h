#import "SMWebRequest.h"
#import "Async.h"

typedef id (^DataParser)(NSData *);

@interface SMWebRequest (Async)

// parser is invoked on background thread
+ (Producer)producerWithURLRequest:(NSURLRequest *)request dataParser:(DataParser)parser;

@end
