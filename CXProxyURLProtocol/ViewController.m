//
//  ViewController.m
//  CXProxyURLProtocol
//
//  Created by Felix on 2018/7/20.
//  Copyright © 2018年 CXTretar. All rights reserved.
//

#import "ViewController.h"
#import "WebViewController.h"
#import "CXProxyProtocolManager.h"
#import "GTMBase64.h"
#import "NSURLRequest+CXMutableCopy.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /* 注册代理协议实现 webview 内容缓存 */
    [CXProxyProtocolManager registerProxyURLProtocol];
    
    /* 以下注释内容为连接代理服务器科学上网的配置 */
//    [CXProxyProtocolManager setHTTPProxyHost:@"39.106.18.134" andHTTPProxyPort:@21886];
//
//    CXProxyProtocolManager *proxyManager = [CXProxyProtocolManager sharedManager];
//
//    proxyManager.requestSetBlock = ^NSMutableURLRequest *(NSURLRequest *request) {
//
//        NSMutableURLRequest *redirectRequest = [request cx_mutableCopy];
//        NSString *authorizationToken = @"proxy:aa0e859ab239a4f125cdacf4865e209c";
//        NSData *data = [authorizationToken dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
//        data = [GTMBase64 encodeData:data];
//        NSString *base64String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        authorizationToken = [NSString stringWithFormat:@"Basic %@", base64String];
//        [redirectRequest addValue:authorizationToken forHTTPHeaderField:@"Proxy-Authorization"];
//        return redirectRequest;
//    };

}

- (IBAction)openBaidu:(id)sender {
    WebViewController *webView = [[WebViewController alloc]init];
    webView.url = @"http://m.baidu.com/";
    
    [self.navigationController pushViewController:webView animated:YES];
}

- (IBAction)openGoogle:(id)sender {
    
    // 要实现项目内部科学上网,必须满足 1.代理服务器可以科学上网 2. 使用 CXProxyProtocolManager 来连接代理服务器
    
    WebViewController *webView = [[WebViewController alloc]init];
    webView.url = @"http://www.google.com";
    
    [self.navigationController pushViewController:webView animated:YES];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
