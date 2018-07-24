//
//  ViewController.m
//  CXProxyURLProtocol
//
//  Created by Felix on 2018/7/20.
//  Copyright © 2018年 CXTretar. All rights reserved.
//

#import "ViewController.h"
#import "WebViewController.h"
#import "CXProxyURLProtocol.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [NSURLProtocol registerClass:[CXProxyURLProtocol class]];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)openBaidu:(id)sender {
    WebViewController *webView = [[WebViewController alloc]init];
    webView.url = @"http://m.baidu.com/";
    
    [self.navigationController pushViewController:webView animated:YES];
}

- (IBAction)openGoogle:(id)sender {
    WebViewController *webView = [[WebViewController alloc]init];
    webView.url = @"http://www.google.com";
    
    [self.navigationController pushViewController:webView animated:YES];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
