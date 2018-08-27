//
//  ViewController.m
//  ZJHURLProtocol
//
//  Created by ZhangJingHao2345 on 2018/8/24.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"

@interface ViewController ()

@property (nonatomic, weak) UIWebView *webview;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CGFloat btnX = 20;
    CGFloat btnW = self.view.frame.size.width - btnX * 2;
    CGFloat btnY = 50;
    CGFloat btnH = 50;
    UIButton *btn1 = [[UIButton alloc] initWithFrame:CGRectMake(btnX, btnY, btnW, btnH)];
    btn1.backgroundColor = [UIColor blueColor];
    [btn1 setTitle:@"网络请求" forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(clickBtn1) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
    
    btnY = btnY + btnH + 30;
    UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(btnX, btnY, btnW, btnH)];
    btn2.backgroundColor = [UIColor blueColor];
    [btn2 setTitle:@"webview加载" forState:UIControlStateNormal];
    [btn2 addTarget:self action:@selector(clickBtn2) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn2];
    
    CGFloat webY = btnY + btnH + 30 ;
    CGFloat webH = self.view.frame.size.height - webY;
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, webY, self.view.frame.size.width, webH)];
    webView.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:webView];
    self.webview = webView;
}

// 网络请求
- (void)clickBtn1 {
    AFHTTPSessionManager *sessionMgr = [AFHTTPSessionManager manager];
    sessionMgr.responseSerializer = [AFHTTPResponseSerializer serializer];
    sessionMgr.requestSerializer = [AFHTTPRequestSerializer serializer];
    sessionMgr.responseSerializer.acceptableContentTypes =
    [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", nil];
    
    NSString *getstr = @"http://c.m.163.com/recommend/getChanListNews?channel=T1457068979049&size=20";
//    NSString *getstr = @"http://www.baidu.com";
    
    [sessionMgr GET:getstr parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSData class]]) {
            NSString *str = [[NSString alloc] initWithData:responseObject
                                                  encoding:NSUTF8StringEncoding];
            NSLog(@"返回数据 ： %@", str);
        } else {
            NSLog(@"返回数据 ： %@", responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"获取数据失败：%@", error);
    }];
}

// webview加载
- (void)clickBtn2 {
    NSString *urlStr = @"http:www.baidu.com";
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr]];
    [self.webview loadRequest:req];
}


@end
