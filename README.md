简书地址：https://www.jianshu.com/p/297fbff8c954

### 前言

开发中遇到需要获取SDK中的数据，由于无法看到代码，所以只能通过监听所有的网络请求数据，截取相应的返回数据，可以通过NSURLProtocol实现，还可用于与H5的交互

### 一、NSURLProtocol拦截请求

##### 1、NSURLProtoco简介

[NSURLProtocol](https://developer.apple.com/reference/foundation/nsurlprotocol) 的官方定义

```
An NSURLProtocol object handles the loading of protocol-specific URL data.
The NSURLProtocol class itself is an abstract class that provides the infrastructure
for processing URLs with a specific URL scheme.
You create subclasses for any custom protocols or URL schemes that your app supports. 
```

iOS的Foundation框架提供了 URL Loading System 这个库(后面简写为ULS)，所有基于URL（例如http://，https:// ,ftp://这些应用层的传输协议)的协议都可以通过ULS提供的基础类和协议来实现，你甚至可以自定义自己的私有应用层通讯协议。

而ULS库里提供了一个强有力的武器 NSURLProtocol。  继承NSURLProtocol 的子类都可以实现截取行为，具体的方式就是：如果注册了某个NSURLProtocol子类，ULS管理的流量都会先交由这个子类处理，这相当于实现了一个拦截器。由于现在处于统治地位的的http client库 AFNetworking和 Alamofire 都是基于 URL Loading System实现的，所以他们俩和使用基础URL Loading System API产生的流量理论上都可以被截取到。

注意一点，NSURLProtocol是一个抽象类，而不是一个协议（protocol）。

其实NSURLProtocol这个东西的作用就是让我们在app的内部拦截一切url请求（注意，不只是webView内的请求，而是整个app内的所有请求），如果筛选出来自己感兴趣的东西去处理，不感兴趣的就放过去就是了。既然能拦截，那么我们至少能做两件事，第一是拦截现有的url请求，比如常用的http://。第二就是我们可以自定义url协议了，比如boris:// 

举几个例子：
*  我们的APP内的所有请求都需要增加公共的头，像这种我们就可以直接通过NSURLProtocol来实现，当然实现的方式有很多种
*  再比如我们需要将APP某个API进行一些访问的统计
*  再比如我们需要统计APP内的网络请求失败率

##### 2、拦截数据请求

在NSURLProtocol中，我们需要告诉它哪些网络请求是需要我们拦截的，这个是通过方法canInitWithRequest:来实现的，比如我们现在需要拦截全部的HTTP和HTTPS请求，那么这个逻辑我们就可以在canInitWithRequest:中来定义.

重点说一下标签`kProtocolHandledKey`：每当需要加载一个URL资源时，URL Loading System会询问ZJHURLProtocol是否处理，如果返回YES，URL Loading System会创建一个ZJHURLProtocol实例，实例做完拦截工作后，会重新调用原有的方法，如session GET，URL Loading System会再一次被调用，如果在+canInitWithRequest:中总是返回YES，这样URL Loading System又会创建一个ZJHURLProtocol实例。。。。这样就导致了无限循环。为了避免这种问题，我们可以利用+setProperty:forKey:inRequest:来给被处理过的请求打标签，然后在+canInitWithRequest:中查询该request是否已经处理过了，如果是则返回NO。 上文中的`kProtocolHandledKey`就是打的一个标签，标签是一个字符串，可以任意取名。而这个打标签的方法，通常会在

```
/**
 需要控制的请求
 
 @param request 此次请求
 @return 是否需要监控
 */
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // 如果是已经拦截过的就放行，避免出现死循环
    if ([NSURLProtocol propertyForKey:kProtocolHandledKey inRequest:request] ) {
        return NO;
    }
    
    // 不是网络请求，不处理
    if (![request.URL.scheme isEqualToString:@"http"] &&
        ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    
    // 拦截所有
    return YES;
}
```

在方法canonicalRequestForRequest:中，我们可以自定义当前的请求request，当然如果不需要自定义，直接返回就行

```
/**
 设置我们自己的自定义请求
 可以在这里统一加上头之类的
 
 @param request 应用的此次请求
 @return 我们自定义的请求
 */
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    // 设置已处理标志
    [NSURLProtocol setProperty:@(YES)
                        forKey:kProtocolHandledKey
                     inRequest:mutableReqeust];
    return [mutableReqeust copy];
}
```

接下来，就是需要将这个request发送出去了，因为如果我们不处理这个request请求，系统会自动发出这个网络请求，但是当我们处理了这个请求，就需要我们手动来进行发送了。

我们要手动发送这个网络请求，需要重写startLoading方法

```
// 重新父类的开始加载方法
- (void)startLoading {
    NSLog(@"***ZJH 监听接口：%@", self.request.URL.absoluteString);
    
    NSURLSessionConfiguration *configuration =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    
    self.sessionDelegateQueue = [[NSOperationQueue alloc] init];
    self.sessionDelegateQueue.maxConcurrentOperationCount = 1;
    self.sessionDelegateQueue.name = @"com.hujiang.wedjat.session.queue";
    
    NSURLSession *session =
    [NSURLSession sessionWithConfiguration:configuration
                                  delegate:self
                             delegateQueue:self.sessionDelegateQueue];
    
    self.dataTask = [session dataTaskWithRequest:self.request];
    [self.dataTask resume];
}
```

当然，有start就有stop，stop就很简单了

```
// 结束加载
- (void)stopLoading {
    [self.dataTask cancel];
}
```

##### 3、拦截数据返回

通过上述代码，我们成功的获取请求体的一些信息，但是如何获取返回信息呢？由于ULS是异步框架，所以，响应会推给回调函数，我们必须在回调函数里进行截取。为了实现这一功能，我们需要实现 NSURLSessionDataDelegate 这个委托协议。

```
#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!error) {
        [self.client URLProtocolDidFinishLoading:self];
    } else if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
    } else {
        [self.client URLProtocol:self didFailWithError:error];
    }
    self.dataTask = nil;
}

#pragma mark - NSURLSessionDataDelegate

// 当服务端返回信息时，这个回调函数会被ULS调用，在这里实现http返回信息的截
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    // 返回给URL Loading System接收到的数据，这个很重要，不然光截取不返回，就瞎了。
    [self.client URLProtocol:self didLoadData:data];
    
    // 打印返回数据
    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (dataStr) {
        NSLog(@"***ZJH 截取数据 : %@", dataStr);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    completionHandler(NSURLSessionResponseAllow);
    self.response = response;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    if (response != nil){
        self.response = response;
        [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
}
```

其实从上面的代码，我们可以看出，我们就是在我们自己自定义的protocol中进行了一个传递过程，其他的也没有做操作

这样，基本的protocol就已经实现完成，那么怎样来拦截网络。我们需要将我们自定义的ZJHURLProtocol通过NSURLProtocol注册到我们的网络加载系统中，告诉系统我们的网络请求处理类不再是默认的NSURLProtocol，而是我们自定义的ZJHURLProtocol

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [NSURLProtocol registerClass:[ZJHURLProtocol class]];
    return YES;
}
```

###二、监听AFNETWorking网络请求

目前为止，我们上面的代码已经能够监控到绝大部分的网络请求。但是呢，如果你使用AFNETworking，你会发现，你的代码根本没有被调用。实际上 ULS允许加载多个NSURLProtocol，它们被存在一个数组里，默认情况下，AFNETWorking只会使用数组里的第一个protocol。

对于NSURLSession发起的网络请求，我们发现通过shared得到的session发起的网络请求都能够监听到，但是通过方法sessionWithConfiguration:delegate:delegateQueue:得到的session，我们是不能监听到的，原因就出在NSURLSessionConfiguration上，我们进到NSURLSessionConfiguration里面看一下，他有一个属性

```
@property(nullable, copy) NSArray<Class> *protocolClasses;
```

我们能够看出，这是一个NSURLProtocol数组，上面我们提到了，我们监控网络是通过注册NSURLProtocol来进行网络监控的，但是通过sessionWithConfiguration:delegate:delegateQueue:得到的session，他的configuration中已经有一个NSURLProtocol，所以他不会走我们的protocol来，怎么解决这个问题呢？ 其实很简单，我们将NSURLSessionConfiguration的属性protocolClasses的get方法hook掉，通过返回我们自己的protocol，这样，我们就能够监控到通过sessionWithConfiguration:delegate:delegateQueue:得到的session的网络请求

```
@implementation ZJHSessionConfiguration

+ (ZJHSessionConfiguration *)defaultConfiguration {
    static ZJHSessionConfiguration *staticConfiguration;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticConfiguration=[[ZJHSessionConfiguration alloc] init];
    });
    return staticConfiguration;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isSwizzle = NO;
    }
    return self;
}

- (void)load {
    self.isSwizzle=YES;
    Class cls = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: NSClassFromString(@"NSURLSessionConfiguration");
    [self swizzleSelector:@selector(protocolClasses) fromClass:cls toClass:[self class]];
    
}

- (void)unload {
    self.isSwizzle=NO;
    Class cls = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: NSClassFromString(@"NSURLSessionConfiguration");
    [self swizzleSelector:@selector(protocolClasses) fromClass:cls toClass:[self class]];
}

- (void)swizzleSelector:(SEL)selector fromClass:(Class)original toClass:(Class)stub {
    Method originalMethod = class_getInstanceMethod(original, selector);
    Method stubMethod = class_getInstanceMethod(stub, selector);
    if (!originalMethod || !stubMethod) {
        [NSException raise:NSInternalInconsistencyException format:@"Couldn't load NEURLSessionConfiguration."];
    }
    method_exchangeImplementations(originalMethod, stubMethod);
}

- (NSArray *)protocolClasses {
    // 如果还有其他的监控protocol，也可以在这里加进去
    return @[[ZJHURLProtocol class]];
}

@end
```

然后是开始监听与取消监听

```
/// 开始监听
+ (void)startMonitor {
    ZJHSessionConfiguration *sessionConfiguration = [ZJHSessionConfiguration defaultConfiguration];
    [NSURLProtocol registerClass:[ZJHURLProtocol class]];
    if (![sessionConfiguration isSwizzle]) {
        [sessionConfiguration load];
    }
}

/// 停止监听
+ (void)stopMonitor {
    ZJHSessionConfiguration *sessionConfiguration = [ZJHSessionConfiguration defaultConfiguration];
    [NSURLProtocol unregisterClass:[ZJHURLProtocol class]];
    if ([sessionConfiguration isSwizzle]) {
        [sessionConfiguration unload];
    }
}
```

最后，在程序启动的时候加入这么一句：

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [ZJHURLProtocol startMonitor];
    return YES;
}
```

这样，一个简单的监控功能就实现了。实际上，想让它能够变得实用起来还有无数的坑要填，代码量大概再增加20倍吧，这些坑包括：https的证书校验，NSURLConnection和NSURLSession兼容，重定向，超时处理，返回值内容解析，各种异常处理（不能因为你崩了让程序跟着崩了），开关，截获的信息本地存储策略，回传服务端策略等

<br>

参考链接：
[使用 NSURLProtocol 拦截 APP 内的网络请求](https://juejin.im/entry/58ed8c6344d904005772e8c7)
[iOS 开发中使用 NSURLProtocol 拦截 HTTP 请求](https://draveness.me/intercept)
[iOS 测试 在 iOS 设备内截取 HTTP/HTTPS 信息](https://testerhome.com/topics/8139)
[iOS 性能监控方案 Wedjat（下篇）](https://www.jianshu.com/p/f244fb25d870)
[NSURLProtocol 的使用和封装](http://borissun.iteye.com/blog/2375043)
