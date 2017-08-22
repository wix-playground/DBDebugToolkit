// The MIT License
//
// Copyright (c) 2016 Dariusz Bukowski
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DBURLProtocol.h"
#import "DBAuthenticationChallengeSender.h"

static NSString *const DBURLProtocolHandledKey = @"DBURLProtocolHandled";
static NSString *const DBURLProtocolUniqueIdentifierKey = @"DBURLProtocolUniqueIdentifierKey";
static __weak id<DBURLProtocolDelegate> __protocolDelelgate;

@interface DBURLProtocol () <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;

@end

@implementation DBURLProtocol

+ (id<DBURLProtocolDelegate>)delegate
{
	return __protocolDelelgate;
}

+ (void)setDelegate:(id<DBURLProtocolDelegate>)delegate
{
	__protocolDelelgate = delegate;
}

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task
{
    NSURLRequest *request = task.currentRequest;
    return request == nil ? NO : [self canInitWithRequest:request];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([[self propertyForKey:DBURLProtocolHandledKey inRequest:request] boolValue]) {
        return NO;
    }
	
	if([request.URL.scheme isEqualToString:@"data"])
	{
		return NO;
	}
    
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
	NSString* uniqueIdentifier = [NSProcessInfo processInfo].globallyUniqueString;
    NSMutableURLRequest *request = [[DBURLProtocol canonicalRequestForRequest:self.request] mutableCopy];
	
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	[DBURLProtocol setProperty:@YES forKey:DBURLProtocolHandledKey inRequest:request];
	[DBURLProtocol setProperty:uniqueIdentifier forKey:DBURLProtocolUniqueIdentifierKey inRequest:request];
	
	[DBURLProtocol.delegate urlProtocol:self didStartRequest:request uniqueIdentifier:uniqueIdentifier];
    
    if (!self.urlSession) {
        self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                        delegate:self
                                                   delegateQueue:nil];
    }
    
    [[self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error != nil)
		{
            [self.client URLProtocol:self didFailWithError:error];
        }
        
        if (response != nil)
		{
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        }
        
        if (data != nil)
		{
            [self.client URLProtocol:self didLoadData:data];
        }
		
		[DBURLProtocol.delegate urlProtocol:self didFinishWithResponse:response data:data error:error forRequestWithUniqueIdentifier:uniqueIdentifier];
        
        [self.client URLProtocolDidFinishLoading:self];
    }] resume];
}

- (void)stopLoading {
    // Do nothing
}

#if HAS_NETWORKTOOLKIT
- (void)finishWithOutcome:(DBRequestOutcome *)requestOutcome {
    [[DBNetworkToolkit sharedInstance] saveRequestOutcome:requestOutcome forRequest:self.request];
}
#endif

#pragma mark - NSURLSessionDelegate 

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    DBAuthenticationChallengeSender *challengeSender = [DBAuthenticationChallengeSender authenticationChallengeSenderWithSessionCompletionHandler:completionHandler];
    NSURLAuthenticationChallenge *modifiedChallenge = [[NSURLAuthenticationChallenge alloc] initWithAuthenticationChallenge:challenge sender:challengeSender];
    [self.client URLProtocol:self didReceiveAuthenticationChallenge:modifiedChallenge];
}

@end
