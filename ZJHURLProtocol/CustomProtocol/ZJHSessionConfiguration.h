//
//  ZJHSessionConfiguration.h
//  ZJHURLProtocol
//
//  Created by ZhangJingHao2345 on 2018/8/24.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZJHSessionConfiguration : NSObject

@property (nonatomic,assign) BOOL isSwizzle;

+ (ZJHSessionConfiguration *)defaultConfiguration;

/**
 *  swizzle NSURLSessionConfiguration's protocolClasses method
 */
- (void)load;

/**
 *  make NSURLSessionConfiguration's protocolClasses method is normal
 */
- (void)unload;

@end
