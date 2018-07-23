//
//  WebViewController.m
//  CXProxyURLProtocol
//
//  Created by Felix on 2018/7/20.
//  Copyright © 2018年 CXTretar. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@property (nonatomic, weak) UIWebView *webView;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadRequest];
}

- (void)setupUI {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"reload"] style:UIBarButtonItemStylePlain target:self action:@selector(reload)];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"reload" style:UIBarButtonItemStylePlain target:self action:@selector(reload)];
    
    UIWebView *webView = [[UIWebView alloc]initWithFrame:self.view.bounds];
    self.webView = webView;
    [self.view addSubview:webView];
}

- (void)reload {
    
    [self.webView reload];
    
}

- (void)loadRequest {
    if (_url.length) {
        NSURL *url = [NSURL URLWithString:_url];
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
