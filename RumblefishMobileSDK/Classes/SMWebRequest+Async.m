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
