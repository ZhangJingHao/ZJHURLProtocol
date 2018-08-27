//
//  ZJHURLProtocol.h
//  ZJHURLProtocol
//
//  Created by ZhangJingHao2345 on 2018/8/24.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZJHURLProtocol : NSURLProtocol

/// 开始监听
+ (void)startMonitor;

/// 停止监听
+ (void)stopMonitor;

@end
