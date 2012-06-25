#import "SMWebRequest+Async.h"
#import "UIApplication+NetworkActivity.h"

@interface WebRequestBlockProducer : NSObject <SMWebRequestDelegate> {
    id (^parser)(NSData *);
    NSURLRequest *urlRequest;
    ResultCallback resultCallback;
    ErrorCallback errorCallback;
    SMWebRequest *webRequest;
}

- (id)initWithURLRequest:(NSURLRequest *)request dataParser:(id (^)(NSData *))parser;
- (Producer)producer;

@end

@implementation WebRequestBlockProducer

- (id)initWithURLRequest:(NSURLRequest *)request dataParser:(id (^)(NSData *))leParser  {
    if ((self = [super init])) {
        urlRequest = [request retain];
        parser = [leParser copy];
    }
    return self;
}

- (void)cancel {
    if (webRequest != nil) {
        [[UIApplication sharedApplication] networkActivityDidEnd];
    }
    
    [resultCallback release];
    resultCallback = nil;
    [errorCallback release];
    errorCallback = nil;
    [webRequest cancel];
    [webRequest release];
    webRequest = nil;
}

- (void)dealloc {
    [self cancel];
    [urlRequest release];
    [parser release];
    [super dealloc];
}

- (id)webRequest:(SMWebRequest *)webRequest resultObjectForData:(NSData *)data context:(id)context {
    return parser ? parser(data) : data;
}

- (void)webRequest:(SMWebRequest *)webRequest didCompleteWithResult:(id)result context:(id)context {
    ResultCallback cb = [resultCallback copy];
    [self cancel];
    cb(result);
    [cb release];
}

- (void)webRequest:(SMWebRequest *)webRequest didFailWithError:(NSError *)error context:(id)context {
    ErrorCallback cb = [errorCallback copy];
    [self cancel];
    cb(error);
    [cb release];
}

- (Producer)producer {
    return (Producer)[[^ CancelCallback (ResultCallback result, ErrorCallback error) {
        resultCallback = [result copy];
        errorCallback = [error copy];
        [[UIApplication sharedApplication] networkActivityDidBegin];
        webRequest = [[SMWebRequest alloc] initWithURLRequest:urlRequest delegate:self context:nil];
        [webRequest start];
        return [[^ void () { [self cancel]; } copy] autorelease];
    } copy] autorelease];
}

@end

@implementation SMWebRequest (Async)

+ (Producer)producerWithURLRequest:(NSURLRequest *)request dataParser:(id (^)(NSData *))parser {
    WebRequestBlockProducer *p = [[WebRequestBlockProducer alloc] initWithURLRequest:request dataParser:parser];
    Producer producer = [p producer];
    [p release];
    return producer;
}

@end
