#import "AppDelegate.h"

/******shark sdk *********/
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKConnector/ShareSDKConnector.h>
//腾讯开放平台（对应QQ和QQ空间）SDK头文件
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>
//微信SDK头文件

//极光推送
#import "JPUSHService.h"
#import <JMessage/JMessage.h>
#import "JCHATFileManager.h"

/******shark sdk  end*********/
//腾讯bug监控
#import <Bugly/Bugly.h>
#import <WXApi.h>
#import "RookieTabBarController.h"
//#import <FBSDKMessengerShareKit/FBSDKMessengerSharer.h>
#import <Twitter/Twitter.h>
#import "CustomPagerController.h"
#import "SPUncaughtExceptionHandler.h"
#import "EBBannerView.h"
//支付宝
#import <AlipaySDK/AlipaySDK.h>

#import <QMapKit/QMapKit.h>
#import <QMapSearchKit/QMapSearchKit.h>

@import CoreLocation;

@interface AppDelegate ()<CLLocationManagerDelegate,WXApiDelegate,JMessageDelegate>
{
    CLLocationManager   *_lbsManager;
    NSNotification * sendEmccBack;

}
@property(nonatomic,strong)NSArray *scrollarrays;//轮播
@end
@implementation AppDelegate



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    InstallUncaughtExceptionHandler();

    [QMapServices sharedServices].apiKey = TencentKey;
    [[QMSSearchServices sharedServices] setApiKey:TencentKey];
    [[SDWebImageManager sharedManager].imageDownloader setValue: nil forHTTPHeaderField:@"Accept"];
    
    [[NSUserDefaults standardUserDefaults] setObject:ZH_CN forKey:CurrentLanguage];
    [[RookieTools shareInstance] resetLanguage:[[NSUserDefaults standardUserDefaults] objectForKey:CurrentLanguage] withFrom:@"appdelegate"];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    self.window = [[UIWindow alloc]initWithFrame:CGRectMake(0,0,_window_width, _window_height)];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[RookieTabBarController alloc] init]];
    [self.window makeKeyAndVisible];
    //启动图版本号、版权信息
    [self setVersionInfo];
    //反复测试延迟1s对版权、版本号展示效果最优
    sleep(1);
    
    [self bgTimer];
    
    [IQKeyboardManager sharedManager].enable = YES;
    [IQKeyboardManager sharedManager].shouldResignOnTouchOutside = YES;
    [IQKeyboardManager sharedManager].enableAutoToolbar = NO;
    
    [Bugly startWithAppId:BuglyId];
    
    [self sysLocation];
    [self sendLocation];
    [self thirdPlant];
    
    //推送-IM
    [self setJPush:launchOptions];

    if (![Config getOwnID]) {
        [Config saveUnified:[PublicObj visitorDic]];
    }
//    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
//    self.window = [[UIWindow alloc]initWithFrame:CGRectMake(0,0,_window_width, _window_height)];
//    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[RookieTabBarController alloc] init]];
//    [self.window makeKeyAndVisible];
    
    //获取后台配置信息
    [BGSetting getBgSettingUpdate:YES maintain:YES eventBack:nil];
    
    [common saveIsStart:@"1"];
    return YES;
}


#pragma mark - 杀进程
- (void)applicationWillTerminate:(UIApplication *)application{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"shajincheng" object:nil];
}
#pragma mark - App进入后台
- (void)applicationDidEnterBackground:(UIApplication *)application {
    application.applicationIconBadgeNumber = 0;
    [application cancelAllLocalNotifications];
    [JMessage resetBadge];
    [JPUSHService setBadge:0];
}
#pragma mark - App将要从后台返回
- (void)applicationWillEnterForeground:(UIApplication *)application {
    [application setApplicationIconBadgeNumber:0];
    [application cancelAllLocalNotifications];
    [JMessage resetBadge];
    [JPUSHService setBadge:0];
}
- (void)applicationDidBecomeActive:(UIApplication *)application{
    [JMessage resetBadge];
}

#pragma mark - 推送-IM
-(void)setJPush:(NSDictionary *)launchOptions{
    
    if([Config getOwnID]!=nil && ![[Config getOwnID] isEqual:@"-9999"] && ![[Config getOwnID] isEqual:@"-1"])     {
        NSString *aliasStr = [NSString stringWithFormat:@"%@PUSH",[Config getOwnID]];
        //[JPUSHService setAlias:aliasStr callbackSelector:nil object:nil];
        [JPUSHService setupWithOption:launchOptions appKey:JpushAppKey
                              channel:Jchannel
                     apsForProduction:isProduction
                advertisingIdentifier:nil];
        [JMSGUser loginWithUsername:[NSString stringWithFormat:@"%@%@",JmessageName,[Config getOwnID]] password:aliasStr completionHandler:^(id resultObject, NSError *error) {
            if (!error) {
                NSLog(@"appdelegate-极光IM登录成功");
            } else {
                NSLog(@"appdelegate-极光IM登录失败");
            }
        }];
    }
    //IM
    [JMessage addDelegate:self withConversation:nil];
    [JMessage setupJMessage:launchOptions appKey:JpushAppKey channel:Jchannel apsForProduction:isProduction category:nil messageRoaming:YES];
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        //可以添加自定义categories
        [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                          UIUserNotificationTypeSound |
                                                          UIUserNotificationTypeAlert)
                                              categories:nil];
    } else {
        //categories 必须为nil
        [JPUSHService registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                          UIRemoteNotificationTypeSound |
                                                          UIRemoteNotificationTypeAlert)
                                              categories:nil];
    }
    // Required - 启动 JMessage SDK
    // Required - 注册 APNs 通知
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        //可以添加自定义categories
        [JMessage registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                      UIUserNotificationTypeSound |
                                                      UIUserNotificationTypeAlert)
                                          categories:nil];
    } else {
        //categories 必须为nil
        [JMessage registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                      UIRemoteNotificationTypeSound |
                                                      UIRemoteNotificationTypeAlert)
                                          categories:nil];
    }
    [JCHATFileManager initWithFilePath];
    [JMessage resetBadge];
}

//极光数据库升级通知
- (void)onDBMigrateStart {
    NSLog(@"onDBmigrateStart in appdelegate");
    _isDBMigrating = YES;
}
//极光数据库升级完成通知
- (void)onDBMigrateFinishedWithError:(NSError *)error {
    NSLog(@"onDBmigrateFinish in appdelegate");
    _isDBMigrating = NO;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"==============%@", [NSString stringWithFormat:@"Device Token: %@", deviceToken]);
    [JMessage registerDeviceToken:deviceToken];
    [JPUSHService registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
     [JPUSHService handleRemoteNotification:userInfo];
     
     if(application.applicationState == UIApplicationStateInactive)
     {
         if([[userInfo valueForKey:@"userinfo"] valueForKey:@"uid"] != nil)
         {
//             moviePlay *mp = [[moviePlay alloc] init];
//             mp.isJpush = @"1";
//             mp.playDoc = [userInfo valueForKey:@"userinfo"];
//             [self.window.rootViewController presentViewController:mp animated:YES completion:nil];
         }
     
         [JPUSHService handleRemoteNotification:userInfo];
     }
}
#pragma mark ================ 点击通知进入app调用此方法 ===============
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"userInfo === %@",userInfo);
    [EBBannerView showWithContent:minstr([[userInfo valueForKey:@"aps"] valueForKey:@"alert"])];
    
     [JPUSHService handleRemoteNotification:userInfo];
     if(application.applicationState == UIApplicationStateInactive)
     {
         if([[userInfo valueForKey:@"userinfo"] valueForKey:@"uid"] != nil)
         {
//             moviePlay *mp = [[moviePlay alloc] init];
//             mp.isJpush = @"1";
//             mp.playDoc = [userInfo valueForKey:@"userinfo"];
//             [self.window.rootViewController presentViewController:mp animated:YES completion:nil];
         }
         [JPUSHService handleRemoteNotification:userInfo];
     }
     completionHandler(UIBackgroundFetchResultNewData);
}
#pragma mark - 发送位置
-(void)sendLocation {
}

#pragma mark - 定位
-(void)sysLocation{
    if (!_lbsManager) {
        _lbsManager = [[CLLocationManager alloc] init];
        [_lbsManager setDesiredAccuracy:kCLLocationAccuracyBest];
        _lbsManager.delegate = self;
        // 兼容iOS8定位
        SEL requestSelector = NSSelectorFromString(@"requestWhenInUseAuthorization");
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined && [_lbsManager respondsToSelector:requestSelector]) {
            [_lbsManager requestWhenInUseAuthorization];  //调用了这句,就会弹出允许框了.
        } else {
            [_lbsManager startUpdatingLocation];
        }
    }
}

- (void)stopLbs {
    [_lbsManager stopUpdatingHeading];
    _lbsManager.delegate = nil;
    _lbsManager = nil;
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        [self stopLbs];
    } else {
        [_lbsManager startUpdatingLocation];
    }
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self stopLbs];
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *newLocatioin = locations[0];
    
    NSString* locationLat = [NSString stringWithFormat:@"%f",newLocatioin.coordinate.latitude];
    NSString* locationLng = [NSString stringWithFormat:@"%f",newLocatioin.coordinate.longitude];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:newLocatioin completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            CLPlacemark *placeMark =  placemarks[0];
            NSString *city = placeMark.locality;
           
            [cityDefault saveLocationLat:locationLat];
            [cityDefault saveLocationLng:locationLng];
            [cityDefault saveLocationCity:city];
        }
    }];
    [self stopLbs];
}

#pragma mark - 分享
-(void)thirdPlant{
    [ShareSDK registerActivePlatforms:@[
                                        @(SSDKPlatformTypeSinaWeibo),
                                        @(SSDKPlatformTypeMail),
                                        @(SSDKPlatformTypeSMS),
                                        @(SSDKPlatformTypeCopy),
                                        @(SSDKPlatformTypeWechat),
                                        @(SSDKPlatformTypeQQ),
                                        @(SSDKPlatformTypeRenren),
                                        @(SSDKPlatformTypeFacebook),
                                        @(SSDKPlatformTypeTwitter),
                                        @(SSDKPlatformTypeGooglePlus)
                                        ]
                             onImport:^(SSDKPlatformType platformType) {
         switch (platformType) {
             case SSDKPlatformTypeWechat:
                 [ShareSDKConnector connectWeChat:[WXApi class]];
                 break;
             case SSDKPlatformTypeQQ:
                 [ShareSDKConnector connectQQ:[QQApiInterface class] tencentOAuthClass:[TencentOAuth class]];
                 break;
             default:
                 break;
         }
     } onConfiguration:^(SSDKPlatformType platformType, NSMutableDictionary *appInfo) {
         
         switch (platformType) {
             case SSDKPlatformTypeSinaWeibo:
                 //设置新浪微博应用信息,其中authType设置为使用SSO＋Web形式授权
                 [appInfo SSDKSetupSinaWeiboByAppKey:@"568898243"
                                           appSecret:@"38a4f8204cc784f81f9f0daaf31e02e3"
                                         redirectUri:@"http://www.sharesdk.cn"
                                            authType:SSDKAuthTypeBoth];
                 break;
             case SSDKPlatformTypeWechat:
                 [appInfo SSDKSetupWeChatByAppId:WechatAppId
                                       appSecret:WechatAppSecret];
                 break;
             case SSDKPlatformTypeQQ:
                 [appInfo SSDKSetupQQByAppId:QQAppId
                                      appKey:QQAppKey
                                    authType:SSDKAuthTypeBoth];
                 break;
             case SSDKPlatformTypeRenren:
                 [appInfo        SSDKSetupRenRenByAppId:@"226427"
                                                 appKey:@"fc5b8aed373c4c27a05b712acba0f8c3"
                                              secretKey:@"f29df781abdd4f49beca5a2194676ca4"
                                               authType:SSDKAuthTypeBoth];
                 break;
             case SSDKPlatformTypeFacebook:
                 [appInfo SSDKSetupFacebookByApiKey:@"107704292745179"
                                          appSecret:@"38053202e1a5fe26c80c753071f0b573"
                                        displayName:@"shareSDK"
                                           authType:SSDKAuthTypeBoth];
                 break;
             case SSDKPlatformTypeTwitter:
                 [appInfo SSDKSetupTwitterByConsumerKey:@"LRBM0H75rWrU9gNHvlEAA2aOy"
                                         consumerSecret:@"gbeWsZvA9ELJSdoBzJ5oLKX0TU09UOwrzdGfo9Tg7DjyGuMe8G"
                                            redirectUri:@"http://mob.com"];
                 break;
             case SSDKPlatformTypeGooglePlus:
                 [appInfo SSDKSetupGooglePlusByClientID:@"232554794995.apps.googleusercontent.com"
                                           clientSecret:@"PEdFgtrMw97aCvf0joQj7EMk"
                                            redirectUri:@"http://localhost"];
                 break;
             default:
                 break;
         }
     }];
    
    
}

#pragma makr - 支付
#pragma mark - 支付宝接入
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([url.host isEqualToString:@"safepay"]) {
        // 支付跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
        }];
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {

            NSLog(@"result = %@",resultDic);
            // 解析 auth code
            NSString *result = resultDic[@"result"];
            NSString *authCode = nil;
            if (result.length>0) {
                NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                for (NSString *subResult in resultArr) {
                    if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                        authCode = [subResult substringFromIndex:10];
                        break;
                    }
                }
            }
            NSLog(@"授权结果 authCode = %@", authCode?:@"");
        
        }];
    }
    return YES;
}
// NOTE: 9.0以后使用新API接口
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options {
    if ([url.host isEqualToString:@"safepay"]) {
        // 支付跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
        }];
        // 授权跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
            // 解析 auth code
            NSString *result = resultDic[@"result"];
            NSString *authCode = nil;
            if (result.length>0) {
                NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                for (NSString *subResult in resultArr) {
                    if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                        authCode = [subResult substringFromIndex:10];
                        break;
                    }
                }
            }
            NSLog(@"授权结果 authCode = %@", authCode?:@"");
        }];
    }
    return YES;
}
#pragma mark - 后台定时器
-(void)bgTimer{
    UIApplication*   app = [UIApplication sharedApplication];
    __block    UIBackgroundTaskIdentifier bgTask;
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid) {
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid) {
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    });
}
#pragma mark - 启动图版本号、版权信息
-(void)setVersionInfo {
    UIImageView *launchImageView = [[UIImageView alloc] initWithFrame:self.window.bounds];
    launchImageView.image = [self getLaunchImage];
    [self.window addSubview:launchImageView];
    [self.window bringSubviewToFront:launchImageView];
    
    UILabel *copyright = [[UILabel alloc]init];
    copyright.text = @"Copyright©2013-2019,DouYin All rights reserved";
    copyright.font = SYS_Font(10);
    copyright.textAlignment = NSTextAlignmentCenter;
    copyright.textColor = [UIColor whiteColor];
    [launchImageView addSubview:copyright];
    [copyright mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(launchImageView.mas_width);
        make.height.mas_equalTo(20);
        make.bottom.mas_equalTo(launchImageView.mas_bottom).offset(-10-ShowDiff/2);
        make.centerX.mas_equalTo(launchImageView.mas_centerX);
    }];
    
    UILabel *vesionLabel = [[UILabel alloc] init];
    //获取当前设备中应用的版本号
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    //NSString *currentVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];//大版本
    NSString *currentVersion = [infoDic objectForKey:@"CFBundleVersion"];//小版本
    NSString *app_Name = [infoDic objectForKey:@"CFBundleDisplayName"];
    vesionLabel.text = [NSString stringWithFormat:@"%@ V %@",app_Name,currentVersion];
    vesionLabel.font = SYS_Font(10);
    vesionLabel.textColor = [UIColor whiteColor];
    vesionLabel.textAlignment = NSTextAlignmentCenter;
    [launchImageView addSubview:vesionLabel];
    [vesionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(launchImageView.mas_width);
        make.height.mas_equalTo(20);
        make.bottom.mas_equalTo(copyright.mas_bottom).offset(-20);
        make.centerX.mas_equalTo(launchImageView.mas_centerX);
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 animations:^{
            launchImageView.alpha = 0.0;
            launchImageView.transform = CGAffineTransformMakeScale(1.2, 1.2);
        } completion:^(BOOL finished) {
            [launchImageView removeFromSuperview];
        }];
    });
}

- (UIImage *)getLaunchImage {
    UIImage *lauchImage = nil;
    NSString *viewOrientation = nil;
    CGSize viewSize = [UIScreen mainScreen].bounds.size;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        viewOrientation = @"Landscape";
    } else {
        viewOrientation = @"Portrait";
    }
    NSArray *imagesDictionary = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"UILaunchImages"];
    for (NSDictionary *dict in imagesDictionary) {
        CGSize imageSize = CGSizeFromString(dict[@"UILaunchImageSize"]);
        if (CGSizeEqualToSize(imageSize, viewSize) && [viewOrientation isEqualToString:dict[@"UILaunchImageOrientation"]]) {
            lauchImage = [UIImage imageNamed:dict[@"UILaunchImageName"]];
        }
    }
    return lauchImage;
}

@end
