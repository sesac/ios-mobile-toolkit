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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum RFAPIEnv {
    RFAPIEnvSandbox = 0,
    RFAPIEnvProduction
} RFAPIEnv;

typedef enum RFAPIResource {
    RFAPIResourceArtist = 0,
    RFAPIResourceAuthenticate,
    RFAPIResourceCatalog,
    RFAPIResourceClear,
    RFAPIResourceLicense,
    RFAPIResourceMedia,
    RFAPIResourceOccasion,
    RFAPIResourcePlaylist,
    RFAPIResourcePortal,
    RFAPIResourceSearch,
    RFAPIResourceSFXCategory
} RFAPIResource;

typedef enum RFAPIVersion {
    RFAPIVersion2 = 2
} RFAPIVersion;

typedef enum RFAPIMethod {
    RFAPIMethodGET = 0,
    RFAPIMethodPOST
} RFAPIMethod;

@interface RFAPI : NSObject

@property (nonatomic) RFAPIVersion version;
@property (nonatomic) RFAPIEnv environment;
@property (nonatomic,strong) NSString *publicKey;
@property (nonatomic,strong) NSString *password;
@property (nonatomic,strong) NSString *accessToken;
@property (nonatomic,strong) NSString *ipAddress;
@property (nonatomic,strong) NSError *lastError;
@property (nonatomic,strong) NSHTTPURLResponse *lastResponse;

+(RFAPI *) initSingletonWithEnvironment:(RFAPIEnv)environment version:(RFAPIVersion)version publicKey:(NSString *)publicKey password:(NSString *)password; 
+(RFAPI *) singleton;
+(NSString *) discoverIPAddress;

// synchronous resource methods! These all return JSON NSObjects, or nil if the request failed. Please see lastResponse and lastError in the case of failure.
-(NSObject *) resource:(RFAPIResource)resource withParams:(NSDictionary *)params;
-(NSObject *) resource:(RFAPIResource)resource withID:(NSObject *)resourceId;
-(NSObject *) resource:(RFAPIResource)resource;

// delegated resource methods!
-(NSURLConnection *) resource:(RFAPIResource)resource withParams:(NSDictionary *)params delegate:(NSObject <NSURLConnectionDelegate> *)delegate;
-(NSURLConnection *) resource:(RFAPIResource)resource withID:(NSObject *)resourceId delegate:(NSObject <NSURLConnectionDelegate> *)delegate;
-(NSURLConnection *) resource:(RFAPIResource)resource delegate:(NSObject <NSURLConnectionDelegate> *)delegate;


@end
