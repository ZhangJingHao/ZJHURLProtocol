//
//  AppDelegate.m
//  ZJHURLProtocol
//
//  Created by ZhangJingHao2345 on 2018/8/24.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import "AppDelegate.h"
#import "ZJHURLProtocol.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
//    [NSURLProtocol registerClass:[ZJHURLProtocol class]];

    [ZJHURLProtocol startMonitor];
    
    return YES;
}



@end
