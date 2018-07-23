//
//  NSData+CXHash.h
//  CXProxyURLProtocol
//
//  Created by Felix on 2018/7/23.
//  Copyright © 2018年 CXTretar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (CXHash)

/**
 Returns an NSString for base64 encoded.
 */
- (nullable NSString *)base64EncodedString;

/**
 Returns an NSData from base64 encoded string.
 
 @warning This method has been implemented in iOS7.
 
 @param base64EncodedString  The encoded string.
 */
+ (nullable NSData *)dataWithBase64EncodedString:(NSString *_Nullable)base64EncodedString;

/**
 Returns a lowercase NSString for sha1 hash.
 */
- (NSString *_Nullable)sha1String;



@end
