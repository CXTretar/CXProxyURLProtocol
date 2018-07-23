//
//  NSString+CXHash.m
//  CXProxyURLProtocol
//
//  Created by Felix on 2018/7/23.
//  Copyright © 2018年 CXTretar. All rights reserved.
//

#import "NSString+CXHash.h"

@implementation NSString (CXHash)

- (NSString *)sha1String {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] sha1String];
}

@end
