//
//  CXProtocolCacheModel.h
//  CXProxyURLProtocol
//
//  Created by Felix on 2018/7/23.
//  Copyright © 2018年 CXTretar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CXProtocolCacheModel : NSObject<NSCoding>

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSURLRequest *redirectRequest;

@end
