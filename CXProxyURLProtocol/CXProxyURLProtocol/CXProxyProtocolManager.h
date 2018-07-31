//
//  CXProxyURLManager.h
//  CXProxyURLProtocol
//
//  Created by Felix on 2018/7/31.
//  Copyright © 2018年 CXTretar. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSMutableURLRequest *(^RequestSetProxyBlock)(NSURLRequest *request);

@interface CXProxyProtocolManager : NSObject

@property (nonatomic, copy) RequestSetProxyBlock requestSetBlock; // 对每个请求的再处理,例如设置请求头
@property (nonatomic, copy) NSString *HTTPProxyHost; // 代理服务器 ip 地址
@property (nonatomic, strong) NSNumber *HTTPProxyPort; // 代理服务器 端口号

/**
 singleton

 @return 单例
 */
+ (instancetype)sharedManager;

/**
 注册CXProxyURLProtocol
 */
+ (void)registerProxyURLProtocol;

/**
 注销CXProxyURLProtocol
 */
+ (void)unregisterProxyURLProtocol;

/**
 CXProxyURLProtocol 可支持的URLSchemes

 @return URLSchemes
 */
+ (NSSet *)supportedSchemes;

/**
 设置 CXProxyURLProtocol 可支持的URLSchemes, 默认为 [http,https]

 @param supportedSchemes URLSchemes like: http https
 */
+ (void)setSupportedSchemes:(NSSet *)supportedSchemes;

/**
 设置代理服务器ip地址以及端口号 http/https 连接方式
 
 @param HTTPProxyHost ip地址
 @param HTTPProxyPort 端口号
 */
+ (void)setHTTPProxyHost:(NSString *)HTTPProxyHost andHTTPProxyPort:(NSNumber *)HTTPProxyPort;

@end
