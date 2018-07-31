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
#import "CXProxyProtocolManager.h"

#define iOS10_1Later ([UIDevice currentDevice].systemVersion.floatValue >= 10.1f)

static NSString *CachingURLProtocolHandledKey = @"CachingURLProtocolHandledKey";

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

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task{
    return [self canInitWithACertainRequest:task.currentRequest];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request{
    return [self canInitWithACertainRequest:request];
}

#pragma mark - 打标记，防止无限循环
+ (BOOL)canInitWithACertainRequest:(NSURLRequest *)request{
    
    if ([[CXProxyProtocolManager supportedSchemes] containsObject:[request.URL scheme]] && ![NSURLProtocol propertyForKey:CachingURLProtocolHandledKey inRequest:request]) {
        //标记是否已经处理过了，防止无限循环
        
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    /** 可以在此处添加头等信息  */
    NSMutableURLRequest *mutableReqeust = [self requestSetProxy:request];
    
    return mutableReqeust;
}

#pragma mark - 设置代理服务器账号密码

+ (NSMutableURLRequest *)requestSetProxy:(NSURLRequest *)request {
    
    NSMutableURLRequest *redirectRequest = [request cx_mutableCopy];
    if (iOS10_1Later) {
        [NSURLProtocol setProperty:@YES forKey:CachingURLProtocolHandledKey inRequest:redirectRequest];
    }
    
    CXProxyProtocolManager *proxyManager = [CXProxyProtocolManager sharedManager];
    if (proxyManager.requestSetBlock) {
        redirectRequest = [proxyManager.requestSetBlock(request) cx_mutableCopy] ;
    }
    
    return redirectRequest;
    
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
    }else {
        
        NSMutableURLRequest *request = [self.request cx_mutableCopy];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        //add custom protocol to session config
        config.protocolClasses = [config.protocolClasses arrayByAddingObject:self.class];
        // 设置代理服务器ip 以及 端口
        CXProxyProtocolManager *proxyManager = [CXProxyProtocolManager sharedManager];
        if (proxyManager.HTTPProxyHost.length && proxyManager.HTTPProxyPort) {
            
            NSString *proxyHost = proxyManager.HTTPProxyHost;
            NSNumber *proxyPort = proxyManager.HTTPProxyPort;
            NSDictionary *proxyDict = @{
                                        @"HTTPEnable"  : [NSNumber numberWithInt:1],
                                        (NSString *)kCFStreamPropertyHTTPProxyHost  : proxyHost,
                                        (NSString *)kCFStreamPropertyHTTPProxyPort  : proxyPort,
                                        
                                        @"HTTPSEnable" : [NSNumber numberWithInt:1],
                                        (NSString *)kCFStreamPropertyHTTPSProxyHost : proxyHost,
                                        (NSString *)kCFStreamPropertyHTTPSProxyPort : proxyPort,
                                        
                                        };
            config.connectionProxyDictionary = proxyDict;
            
        }
        
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:queue];;
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
        NSMutableURLRequest *redirectableRequest;
        
        if (iOS10_1Later) {
            redirectableRequest = [[self class] requestSetProxy:redirectableRequest];
        }else {
            redirectableRequest = [request cx_mutableCopy];
        }
        
        [NSURLProtocol removePropertyForKey:CachingURLProtocolHandledKey inRequest:redirectableRequest];
        
        CXProtocolCacheModel *cacheData = [[CXProtocolCacheModel alloc] init];
        cacheData.data = self.data;
        cacheData.response = response;
        cacheData.redirectRequest = redirectableRequest;
        
        [NSKeyedArchiver archiveRootObject:cacheData toFile:[self cachePathForRequest:request]];
        
        [[self client] URLProtocol:self wasRedirectedToRequest:redirectableRequest redirectResponse:response];
        
        [task cancel];
        
        [self.client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
        
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
