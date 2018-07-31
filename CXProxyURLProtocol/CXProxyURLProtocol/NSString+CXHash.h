//
//  NSString+CXHash.h
//  CXProxyURLProtocol
//
//  Created by Felix on 2018/7/23.
//  Copyright © 2018年 CXTretar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSData+CXHash.h"

@interface NSString (CXHash)

/**
 Returns a lowercase NSString for sha1 hash.
 */
- (nullable NSString *)sha1String;

@end
