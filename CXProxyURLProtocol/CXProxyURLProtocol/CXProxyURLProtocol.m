//
//  CXProxyURLProtocol.m
//  CXProxyURLProtocol
//
//  Created by Felix on 2018/7/20.
//  Copyright © 2018年 CXTretar. All rights reserved.
//

#import "CXProxyURLProtocol.h"
#import "CXProtocolCacheModel.h"
#import "NSURLRequest+CXMutableCopy.h"
#import "NSString+CXHash.h"
#import "Reachability.h"
#import <UIKit/UIDevice.h>


#define iOS10_1Later ([UIDevice currentDevice].systemVersion.floatValue >= 10.1f)

static NSString *CachingURLProtocolHandledKey = @"CachingURLProtocolHandledKey";
static NSSet *CachingSupportedSchemes = nil;
static NSObject *CachingSupportedSchemesMonitor;

@interface CXProxyURLProtocol ()<NSURLSessionDataDelegate,NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLResponse *response;

@end

@implementation CXProxyURLProtocol

- (NSURLSession *)session {
    
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    }
    return _session;
}

#pragma mark - Scheme
+ (NSSet *)supportedSchemes {
    NSSet *supportedSchemes;
    @synchronized(CachingSupportedSchemesMonitor) {
        supportedSchemes = CachingSupportedSchemes;
    }
    return supportedSchemes;
}

+ (void)setSupportedSchemes:(NSSet *)supportedSchemes {
    @synchronized(CachingSupportedSchemesMonitor) {
        CachingSupportedSchemes = supportedSchemes;
    }
}

#pragma mark - override
+ (void)initialize {
    
    if (self == [CXProxyURLProtocol class]){
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            CachingSupportedSchemesMonitor = [[NSObject alloc] init];
        });
        [self setSupportedSchemes:[NSSet setWithObjects:@"http",@"https",nil]];
    }
}

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task{
    return [self canInitWithACertainRequest:task.currentRequest];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request{
    return [self canInitWithACertainRequest:request];
}

#pragma mark - 打标记，防止无限循环
+ (BOOL)canInitWithACertainRequest:(NSURLRequest *)request{
    
    if ([[self supportedSchemes] containsObject:[request.URL scheme]] && [request valueForHTTPHeaderField:CachingURLProtocolHandledKey] == nil) {
        //标记是否已经处理过了，防止无限循环
        return YES;
    }
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    
    return request;
}

- (void)startLoading {
    
    if ([self needCache]) {
        
        CXProtocolCacheModel *cacheModel = [NSKeyedUnarchiver unarchiveObjectWithFile:[self cachePathForRequest:self.request]];
        if (cacheModel) {
            if (cacheModel.redirectRequest) {
                [[self client] URLProtocol:self wasRedirectedToRequest:cacheModel.redirectRequest redirectResponse:cacheModel.response];
            }else {
                [self.client URLProtocol:self didReceiveResponse:cacheModel.response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                [self.client URLProtocol:self didLoadData:cacheModel.data];
                [self.client URLProtocolDidFinishLoading:self];
            }
            
        }else{
        
            [self.client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil]];
        }
    }else{
        
        NSMutableURLRequest *request = [self.request cx_mutableCopy];
        request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        [request setValue:@"test" forHTTPHeaderField:CachingURLProtocolHandledKey];
        self.task = [self.session dataTaskWithRequest:request];
        [self.task resume];
    }
}

- (void)stopLoading {
    
    [self.task cancel];
    self.data = nil;
    self.task = nil;
    self.response = nil;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    // 允许处理服务器的响应，才会继续接收服务器返回的数据
    completionHandler(NSURLSessionResponseAllow);
    self.data = [NSMutableData data];
    self.response = response;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    [self.client URLProtocol:self didLoadData:data];
    [self.data appendData:data];
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    
    //处理重定向问题
    if (response != nil) {
        NSMutableURLRequest *redirectableRequest = [request cx_mutableCopy];
        CXProtocolCacheModel *cacheData = [[CXProtocolCacheModel alloc] init];
        cacheData.data = self.data;
        cacheData.response = response;
        cacheData.redirectRequest = redirectableRequest;
        [NSKeyedArchiver archiveRootObject:cacheData toFile:[self cachePathForRequest:request]];
        
        [self.client URLProtocol:self wasRedirectedToRequest:redirectableRequest redirectResponse:response];
        completionHandler(request);
        
    } else {
        
        completionHandler(request);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
        
    }else {
        //将数据的缓存归档存入到本地文件中
        NSLog(@"ok url = %@",task.currentRequest.URL.absoluteString);
        CXProtocolCacheModel *cacheData = [[CXProtocolCacheModel alloc] init];
        cacheData.data = [self.data copy];
        cacheData.response = self.response;
        [NSKeyedArchiver archiveRootObject:cacheData toFile:[self cachePathForRequest:self.request]];
        [self.client URLProtocolDidFinishLoading:self];
    }
}

#pragma mark- private
- (BOOL)needCache { // 在无网络状态下使用缓存
    return [[Reachability reachabilityWithHostname:self.request.URL.host] currentReachabilityStatus] == NotReachable;
}

- (void)resetCurrentCache {
    [_task cancel];
    _task = nil;
    _data = nil;
    _response = nil;
}

- (NSString *)cachePathForRequest:(NSURLRequest *)request {
    
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fileName = [[[request URL] absoluteString] sha1String];
    
    return [cachePath stringByAppendingPathComponent:fileName];
}


@end
