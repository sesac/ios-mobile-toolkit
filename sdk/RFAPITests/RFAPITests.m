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

#import "RFAPITests.h"

@implementation RFAPITests

RFAPI *api = NULL; 

- (void)setUp
{
    [super setUp];
    
    api = [RFAPI initSingletonWithEnvironment:RFAPIEnvSandbox version:RFAPIVersion2 publicKey:@"sandbox" password:@"sandbox"];
}

- (void)tearDown
{    
    [super tearDown];
}

- (void)testSingleton
{
    STAssertEqualObjects( api, [RFAPI singleton], @"RFAPI singleton method did not return the same object as init in setUp." );
}

- (void)testQueryStrings
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@"loves beer" forKey:@"jeff"];
    
    NSString *expected = @"?jeff=loves%20beer";
    
    STAssertTrue( [expected isEqualToString:[api queryStringFor:params]], @"Didn't produce correct query string." );
}

- (void)testResourceURLGeneration
{
    NSString *base = @"https://sandbox.rumblefish.com/v2/media";
    STAssertTrue( [base isEqualToString:[api urlStringForResource:RFAPIResourceMedia]], @"Didn't produce matching URLs."); 

    NSString *withQueryString = @"https://sandbox.rumblefish.com/v2/media?jeff=loves%20beer";
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@"loves beer" forKey:@"jeff"];
    
    STAssertTrue( [withQueryString isEqualToString:[api urlStringForResource:RFAPIResourceMedia withParameters:params]], @"Didn't produce matching URLs."); 

}

- (void)testNotATest
{
    NSURLRequest *request = [api requestResource:RFAPIResourceMedia withMethod:RFAPIMethodGET];
    
    NSURLResponse *response;
    NSError *error;
    
    // Make synchronous request
    NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSString *resultString = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
    NSLog( @"RECEIVED %@", resultString );
}


@end
