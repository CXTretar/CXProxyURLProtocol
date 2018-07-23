//
//  NSURLRequest+CXMutableCopy.m
//  CXProxyURLProtocol
//
//  Created by Felix on 2018/7/23.
//  Copyright © 2018年 CXTretar. All rights reserved.
//

#import "NSURLRequest+CXMutableCopy.h"

@implementation NSURLRequest (CXMutableCopy)

- (id)cx_mutableCopy {
    NSMutableURLRequest *mutableCopy = [[NSMutableURLRequest alloc] initWithURL:[self URL]
                                                                    cachePolicy:[self cachePolicy]
                                                                timeoutInterval:[self timeoutInterval]];
    
    [mutableCopy setAllHTTPHeaderFields:[self allHTTPHeaderFields]];
    [mutableCopy setHTTPMethod:[self HTTPMethod]];
    
    if ([self HTTPBodyStream]) {
        
        [mutableCopy setHTTPBodyStream:[self HTTPBodyStream]];
        
    } else {
        
        [mutableCopy setHTTPBody:[self HTTPBody]];
    }
    
    return mutableCopy;
}


@end
