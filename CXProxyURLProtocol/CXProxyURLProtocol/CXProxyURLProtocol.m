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

static NSString *URLProtocolHandledKey = @"URLProtocolHandledKey";
static NSSet *SupportSchemes = nil;

@interface CXProxyURLProtocol ()<NSURLSessionDataDelegate,NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSURLRequest *redirectRequest;

- (void)appendData:(NSData *)newData;

@end

@implementation CXProxyURLProtocol

+ (void)initialize {
    
    if (self == [CXProxyURLProtocol class]){
        
        [self defaultSupportedSchemes];
    }
}

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task{
    NSLog(@"canInitWithTask -- %@ -- %@", task.currentRequest, [NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:task.currentRequest]);
    return [self canInitWithACertainRequest:task.currentRequest];
}

+(BOOL)canInitWithRequest:(NSURLRequest *)request{
    NSLog(@"canInitWithRequest -- %@ -- %@", request, [NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]);
    return [self canInitWithACertainRequest:request];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request{
    
    /** 可以在此处添加头等信息  */
    NSMutableURLRequest *mutableReqeust = [self requestSetProxy:request];
    
    return mutableReqeust;
}

- (void)startLoading{
    
    if ([self needCache]) {
        
        CXProtocolCacheModel *cacheModel = [NSKeyedUnarchiver unarchiveObjectWithFile:[self cachePathForRequest:self.request]];
        if (cacheModel) {
            
            if (cacheModel.redirectRequest) {
                NSMutableURLRequest *request = [cacheModel.redirectRequest cx_mutableCopy];
                [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:request];
                [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:cacheModel.response];
            }else {
                [self.client URLProtocol:self didReceiveResponse:cacheModel.response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                [self.client URLProtocol:self didLoadData:cacheModel.data];
                [self.client URLProtocolDidFinishLoading:self];
            }

        }else{
            
            [self.client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil]];
        }
    }else{
        
        _task = [self taskAfreshSend];
        [_task resume];
    }
}



- (void)stopLoading {
    
    [_task cancel];
    
    self.data = nil;
    self.task = nil;
    self.response = nil;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    
    _response = response;
    
    //because of using cache policy by ourselves,so prevent from default cache policy
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    NSData *newData = data;
    //    if (_isWhiteList) {
    //        newData = [self dataHideIPfields:data];
    //    }
    //
    [self.client URLProtocol:self didLoadData:newData];
    [self.data appendData:newData];
    
}

- (void)appendData:(NSData *)newData {
    if ([self data] == nil) {
        [self setData:[newData mutableCopy]];
    }
    else {
        [[self data] appendData:newData];
    }
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    
    if (response) {
        NSMutableURLRequest *redirectRequest;
       
        if (iOS10_1Later) {
            redirectRequest  = [CXProxyURLProtocol requestSetProxy:request];
        }else {
            redirectRequest = [request cx_mutableCopy];
        }
        
        [NSURLProtocol removePropertyForKey:URLProtocolHandledKey inRequest:redirectRequest];
        
        [self archiverWithRedirectRequest:redirectRequest];
        
        [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
        
        [task cancel];
        
        [self.client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
        
        completionHandler(request);
        
    } else {
        completionHandler(request);
    }}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    
    if (error) {
        //
        //        NSLog(@"%@", error);
        [self.client URLProtocol:self didFailWithError:error];
//        if (error.code == 306) {
//            // 返回主线程更新UI
//            dispatch_async(dispatch_get_main_queue(), ^{
//                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:LocalStr(@"代理服务器无法连接,即将断开VPN代理服务器!") delegate:nil cancelButtonTitle:LocalStr(@"确定") otherButtonTitles:nil];
//                [alert show];
//                [[ProxyManager sharedManager] unregisterProxy:NO];
//            });
//        }
        [self resetCurrentCache];
    }else {
        [self.client URLProtocolDidFinishLoading:self];
        [self archiver];
    }
    
    
}

#pragma mark- private

#pragma mark - 打标记，防止无限循环
+ (BOOL)canInitWithACertainRequest:(NSURLRequest *)request{
    
    if ([SupportSchemes containsObject:[request.URL scheme]]) {
        //看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]) {
            return NO;
        }
        return YES;
    }

    return NO;
}

#pragma mark - 设置代理服务器地址
+ (NSMutableURLRequest *)requestSetProxy:(NSURLRequest *)request {
    
    NSMutableURLRequest *redirectRequest = [request cx_mutableCopy];

    if (iOS10_1Later) {
        [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:redirectRequest];
    }

    return redirectRequest;
    
}

- (NSURLSessionTask *)taskAfreshSend {
    NSMutableURLRequest *request = [self.request cx_mutableCopy];

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    //add custom protocol to session config
    config.protocolClasses = [config.protocolClasses arrayByAddingObject:self.class];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:queue];
    
    return [session dataTaskWithRequest:request];
}

- (BOOL)needCache { // 在无网络状态下使用缓存
    return [[Reachability reachabilityWithHostname:self.request.URL.host] currentReachabilityStatus] == NotReachable;
}

- (void)archiver {
    [self archiverWithRedirectRequest:nil];
}

- (void)resetCurrentCache {
    [_task cancel];
    _task = nil;
    _data = nil;
    _response = nil;
}

- (void)archiverWithRedirectRequest:(NSURLRequest *)request {
    
    CXProtocolCacheModel *cacheModel = [[CXProtocolCacheModel alloc]init];
    cacheModel.data = _data;
    cacheModel.response = _response;
    cacheModel.redirectRequest = request;
    NSLog(@"_data  %@---_response  %@", _data, _response);
    NSString *cachePath = [self cachePathForRequest:self.request];
    [NSKeyedArchiver archiveRootObject:cacheModel toFile:cachePath];
    
}

- (NSString *)cachePathForRequest:(NSURLRequest *)request{
    
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fileName = [[[request URL] absoluteString] sha1String];
    
    return [cachePath stringByAppendingPathComponent:fileName];
}

#pragma mark - Scheme ref
+ (NSSet *)defaultSupportedSchemes {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SupportSchemes = [NSSet setWithObjects:@"http",@"https", nil];
    });
    
    return SupportSchemes;
}

+ (void)setSupportedSchemes:(NSSet *)supportedSchemes{
    
    SupportSchemes = supportedSchemes;
}

+ (void)addSupportedScheme:(NSString *)scheme{
    
    SupportSchemes = [SupportSchemes setByAddingObject:scheme];
}

- (void)removeSupportedScheme:(NSString *)scheme{
    
    NSMutableSet *mutableSetCopy = [SupportSchemes mutableCopy];
    [mutableSetCopy removeObject:scheme];
    SupportSchemes = mutableSetCopy;
}


@end
