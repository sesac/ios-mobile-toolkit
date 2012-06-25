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

#import "RFAPI.h"
#import "SBJson.h"

@implementation RFAPI

@synthesize environment = _environment;
@synthesize publicKey = _publicKey;
@synthesize password = _password;
@synthesize accessToken = _accessToken;
@synthesize version = _version;
@synthesize lastError = _lastError;
@synthesize lastResponse = _lastResponse;
@synthesize ipAddress = _ipAddress;

static RFAPI *rfAPIObject = nil; // use [RFAPI singleton]
static int RFAPI_TIMEOUT = 30.0; // request timeout

+(RFAPI *) initSingletonWithEnvironment:(RFAPIEnv)environment version:(RFAPIVersion)version publicKey:(NSString *)publicKey password:(NSString *)password {
    @synchronized(self) {
        if (!rfAPIObject) {
            rfAPIObject = [[RFAPI alloc] init];
            rfAPIObject.environment = environment;
            rfAPIObject.publicKey = publicKey;
            rfAPIObject.password = password;
            rfAPIObject.version = version;
            rfAPIObject.ipAddress = [self discoverIPAddress];
            
            NSLog(@"Initialized RFAPI singleton for host %@, publicKey %@, and ipAddress %@", [rfAPIObject host], publicKey, [rfAPIObject ipAddress]);
        }
    }
    
    return rfAPIObject;
}


+(RFAPI *) singleton {
    if (!rfAPIObject)
        @throw [NSException exceptionWithName:@"SingletonNotInitializedException" reason:@"Please use initSingletonWithEnvironment to initialize the singleton." userInfo:nil];
        
    return rfAPIObject;
}

+(NSString *) discoverIPAddress {
    // pull public address from dyndns.org
    NSData *resultData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://checkip.dyndns.org/"]];
    NSString *resultString = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    
    // in the structure of 
    // <html><head><title>Current IP Check</title></head><body>Current IP Address: 199.223.126.116</body></html>
    
    // split at the : to get the trailing IP and HTML.
    NSArray *ipSplit = [resultString componentsSeparatedByString:@": "];
    
    // split at the < to separate the IP from the HTML. 
    NSArray *resultArray = [(NSString *)[ipSplit objectAtIndex:1] componentsSeparatedByString:@"<"];
        
    // return the IP section
    return [resultArray objectAtIndex:0];
}


#pragma mark URL building methods.

-(NSString *) host {
    switch (self.environment) {
        case RFAPIEnvProduction:
            return @"api.rumblefish.com";
            break;
        case RFAPIEnvSandbox:
            return @"sandbox.rumblefish.com";
            break;
        default:
            // throw unknown environment exception.
            return @"unknown.com";
    }
}

-(NSString *) pathToResource:(RFAPIResource)resource {
    NSString *path = @"unknown";
    
    switch (resource) {
        case RFAPIResourceArtist:
            path = @"artist";
            break;
        case RFAPIResourceAuthenticate:
            path = @"authenticate";
            break;
        case RFAPIResourceCatalog:
            path = @"catalog";
            break;
        case RFAPIResourceClear:
            path = @"clear";
            break;
        case RFAPIResourceLicense:
            path = @"license";
            break;
        case RFAPIResourceMedia:
            path = @"media";
            break;
        case RFAPIResourceOccasion:
            path = @"occasion";
            break;
        case RFAPIResourcePlaylist:
            path = @"playlist";
            break;
        case RFAPIResourcePortal:
            path = @"portal";
            break;
        case RFAPIResourceSearch:
            path = @"search";
            break;
        case RFAPIResourceSFXCategory:
            path = @"sfx_category";
            break;
    }
    
    return [NSString stringWithFormat:@"/v%d/%@", self.version, path];
}

-(NSString *) queryStringFor:(NSDictionary *)parameters {
    // ensure dictionary
    if (!parameters) {
        parameters = [[NSMutableDictionary alloc] init];
    }

    // ENFORCE IP ADDRESS
    [parameters setValue:[self ipAddress] forKey:@"ip"];
    
    NSMutableString *queryString = nil;
    NSArray *keys = [parameters allKeys];
    
    if ([keys count] > 0) {
        for (id key in keys) {
            id value = [parameters objectForKey:key];
            if (nil == queryString) {
                queryString = [[NSMutableString alloc] init];
                [queryString appendFormat:@"?"];
            } else {
                [queryString appendFormat:@"&"];
            }
            
            if (nil != key && nil != value) {
                [queryString appendFormat:@"%@=%@", [self escapeString:key], [self escapeString:value]];
            } else if (nil != key) {
                [queryString appendFormat:@"%@", [self escapeString:key]];
            }
        }
    }
    
    return queryString;
}

-(NSString *) urlStringForResource:(RFAPIResource)resource withParameters:(NSDictionary *)parameters {
    
    NSString *baseURL = [NSString stringWithFormat:@"https://%@%@", [self host], [self pathToResource:resource]];
    NSString *query = [self queryStringFor:parameters];
    
    return [NSString stringWithFormat:@"%@%@", baseURL, query];    
}

-(NSString *) escapeString:(NSString *)unencodedString {
    NSString *s = (__bridge NSString *) CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                      (__bridge CFStringRef)unencodedString,
                                                                      NULL,
                                                                      (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                      kCFStringEncodingUTF8);
    return s;
}


#pragma mark Request building methods.

-(NSURLRequest *) requestWithURL:(NSURL *)url {
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:RFAPI_TIMEOUT];
    NSLog(@"RFAPI: %@", url);
    return request;
}

-(NSURLRequest *) requestResource:(RFAPIResource)resource withMethod:(RFAPIMethod)method andParameters:(NSDictionary *)parameters {
    NSURL *url = [NSURL URLWithString:[self urlStringForResource:resource withParameters:parameters]];
    
    return [self requestWithURL:url];
}



#pragma mark Request execution methods.

-(NSString *) doRequest:(NSURLRequest *)request {
    NSString *resultString;
    
    // clear lastError and lastRequest before we attempt the request.
    _lastError = nil;
    _lastResponse = nil;
    
    NSError *localError = [[NSError alloc] init];
    NSHTTPURLResponse *localResponse = nil;
    
    // Make synchronous request; lastResponse and lastError are set automatically.
    NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&localResponse error:&localError];
    
    if (localResponse && ([localResponse statusCode] == 200)) {
        resultString = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
        [self setLastResponse:localResponse];
    } else {
        [self setLastError:localError];
    }

    return resultString;
}

-(NSURLConnection *) doRequest:(NSURLRequest *)request delegate:(NSObject <NSURLConnectionDelegate> *)delegate {
    return [NSURLConnection connectionWithRequest:request delegate:delegate];
}



#pragma mark Response handling methods.

-(NSObject *) stringResponseToJson:(NSString *)stringResponse {
    SBJsonParser *jsonParser = [SBJsonParser new];
    return [jsonParser objectWithString:stringResponse error:NULL];
}



#pragma mark Synchronous resource methods!

-(NSObject *) resource:(RFAPIResource)resource withParams:(NSDictionary *)params {
    NSObject *jsonResponse;
    NSURLRequest *request;
    
    // make the request
    request = [self requestResource:resource withMethod:RFAPIMethodGET andParameters:params];
    
    // execute the request
    NSString *responseString = [self doRequest:request];
    
    if (responseString) {
        jsonResponse = [self stringResponseToJson:responseString];
    }
    
    return jsonResponse;
}

-(NSObject *) resource:(RFAPIResource)resource withID:(NSObject *)resourceId {
    // set up our parameters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *resourceIDString = [NSString stringWithFormat:@"%@", resourceId];
    [params setObject:resourceIDString forKey:@"id"];
    
    // make the request
    return [self resource:resource withParams:params];
}

-(NSObject *) resource:(RFAPIResource)resource {
    return [self resource:resource withParams:nil];
}


#pragma mark Asynchronous resource methods!

-(NSURLConnection *) resource:(RFAPIResource)resource withParams:(NSDictionary *)params delegate:(NSObject <NSURLConnectionDelegate> *)delegate {
    NSURLRequest *request;
    
    // make the request
    request = [self requestResource:resource withMethod:RFAPIMethodGET andParameters:params];
    
    // execute the request
    return [self doRequest:request delegate:delegate];
}

-(NSURLConnection *) resource:(RFAPIResource)resource withID:(NSObject *)resourceId delegate:(NSObject <NSURLConnectionDelegate> *)delegate {
    // set up our parameters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *resourceIDString = [NSString stringWithFormat:@"%@", resourceId];
    [params setObject:resourceIDString forKey:@"id"];
    
    // make the request
    return [self resource:resource withParams:params delegate:delegate];
}

-(NSURLConnection *) resource:(RFAPIResource)resource delegate:(NSObject <NSURLConnectionDelegate> *)delegate {
    return [self resource:resource withParams:nil delegate:delegate];
}

@end