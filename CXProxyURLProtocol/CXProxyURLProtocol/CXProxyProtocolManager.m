//
//  CXProxyURLManager.m
//  CXProxyURLProtocol
//
//  Created by Felix on 2018/7/31.
//  Copyright © 2018年 CXTretar. All rights reserved.
//

#import "CXProxyProtocolManager.h"
#import "CXProxyURLProtocol.h"

static NSSet *CachingSupportedSchemes = nil;
static NSObject *CachingSupportedSchemesMonitor;

@implementation CXProxyProtocolManager

#pragma mark - override

+ (void)initialize {
    if (self == [CXProxyProtocolManager class]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            CachingSupportedSchemesMonitor = [[NSObject alloc] init];
        });
        [self setSupportedSchemes:[NSSet setWithObjects:@"http",@"https",nil]];
    }
}

#pragma mark - singleton

+ (instancetype)sharedManager {
    static CXProxyProtocolManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CXProxyProtocolManager alloc]init];
    });
    return manager;
}

+ (void)registerProxyURLProtocol {
    // 注册代理协议
    [NSURLProtocol registerClass:[CXProxyURLProtocol class]];
}

+ (void)unregisterProxyURLProtocol {
     // 注销代理协议
    [NSURLProtocol unregisterClass:[CXProxyURLProtocol class]];
}

+ (void)setHTTPProxyHost:(NSString *)HTTPProxyHost andHTTPProxyPort:(NSNumber *)HTTPProxyPort {
    
    CXProxyProtocolManager *proxyManager = [self sharedManager];
    proxyManager.HTTPProxyHost = HTTPProxyHost;
    proxyManager.HTTPProxyPort = HTTPProxyPort;
    
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



@end
