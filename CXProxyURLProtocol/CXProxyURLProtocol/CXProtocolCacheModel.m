//
//  CXProtocolCacheModel.m
//  CXProxyURLProtocol
//
//  Created by Felix on 2018/7/23.
//  Copyright © 2018年 CXTretar. All rights reserved.
//

#import "CXProtocolCacheModel.h"

@implementation CXProtocolCacheModel

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.data forKey:@"data"];
    [aCoder encodeObject:self.response forKey:@"response"];
    [aCoder encodeObject:self.redirectRequest forKey:@"redirectRequest"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super init]) {
        [self setData:[aDecoder decodeObjectForKey:@"data"]];
        [self setResponse:[aDecoder decodeObjectForKey:@"response"]];
        [self setRedirectRequest:[aDecoder decodeObjectForKey:@"redirectRequest"]];
    }
    
    return self;
}


@end
