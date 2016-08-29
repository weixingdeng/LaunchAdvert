//
//  UIViewController+LaunchAdvert.m
//  FirstLaunchDemo
//
//  Created by dengwx on 16/8/29.
//  Copyright © 2016年 wxdeng. All rights reserved.
//

#import "UIViewController+LaunchAdvert.h"
#import <objc/runtime.h>
#define  VTUserDefaults [NSUserDefaults standardUserDefaults]
#define  VTFileManager [NSFileManager defaultManager]
#define  VTScreenFrame  [[UIScreen mainScreen] bounds]
#define AdvertKey @"vtAdvertKey"

typedef void(^ClickCallback)(id callback) ;
@interface UIViewController()

@property (nonatomic,strong) UIView *advertView;
@property (nonatomic,copy) ClickCallback clickCallback;

@end

@implementation UIViewController (LaunchAdvert)

static int showtime = 4;
static const char viewKey;
static const char blockKey;
- (void)showAdvertWithUrl:(NSURL *)imageUrl clickCallback:(void (^)(id callback))callback
{
    self.clickCallback = callback;
    NSString *filePath = [self getFileParhWithFileName:[VTUserDefaults valueForKey:AdvertKey]];
    BOOL isExist = [self isFileExistWithFilePath:filePath];
    if (isExist) {
        [self showAdvert];
    }
    
    //无论文件是否存在 都向服务器请求新的,和本地对比判断是否需要更新.此处可以设置缓存间隔,例如一天之内只请求一次
    [self requestForNewFile];
}

//显示广告
- (void)showAdvert
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:[self getAdvertView]];
    [self startCountdownTime];
    
}

//初始化广告界面
- (UIView *)getAdvertView
{
    self.advertView = [[UIView alloc]initWithFrame:VTScreenFrame];
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:VTScreenFrame];
    UIImage *image = [UIImage imageWithContentsOfFile:[self getFileParhWithFileName:[VTUserDefaults valueForKey:AdvertKey]]];
    imageView.image = image;
    imageView.userInteractionEnabled = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pushToAd)];
    [imageView addGestureRecognizer:tap];
    
    [self.advertView addSubview:imageView];
    
    //添加倒计时
    UIButton *timeBtn = [[UIButton alloc]initWithFrame:CGRectMake(VTScreenFrame.size.width - 60 - 24, 30, 60, 30)];
    timeBtn.tag = 10086;
    [timeBtn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [timeBtn setTitle:[NSString stringWithFormat:@"跳过%d", showtime] forState:UIControlStateNormal];
    timeBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [timeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    timeBtn.backgroundColor = [UIColor colorWithRed:38 /255.0 green:38 /255.0 blue:38 /255.0 alpha:0.6];
    [timeBtn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    timeBtn.layer.cornerRadius = 4;
    [self.advertView addSubview:timeBtn];
    return self.advertView;
}

//点击了广告,跳转到对应页面
- (void)pushToAd
{
    if (self.clickCallback) {
        [self dismiss];
        self.clickCallback(nil);
    }
}

//开始倒计时
- (void)startCountdownTime
{
    __block UIButton *timeBtn = (UIButton *)[self.advertView viewWithTag:10086];
    __block int currentTime = showtime ;
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, quene);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        currentTime--;
        if (currentTime <=0) {
            dispatch_source_cancel(timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self dismiss];
                
            });
            
        }else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [timeBtn setTitle:[NSString stringWithFormat:@"跳过%d",currentTime] forState:UIControlStateNormal];
            });
            
        }
    });
    dispatch_resume(timer);
}

//移除广告
- (void)dismiss
{
    
    [UIView animateWithDuration:0.3f animations:^{
        
        self.advertView.alpha = 0.f;
        
    } completion:^(BOOL finished) {
        
        [self.advertView removeFromSuperview];
        
    }];
    
}
//请求新的图片
- (void)requestForNewFile
{
    /**
     *  公司的启动图接口
     eg.1 请求后服务器返回字段{flag:0,url:""} 代表没有最新的,flag=1代表有更新
     eg.2 直接返回{url:""} 自己判断有没有更新
     eg.3..可能有其他返回形式
     
     以下代码模拟返回的url为urlString这样的,用到的时候自己修改
     */
    NSArray *imageArray = @[@"http://imgsrc.baidu.com/forum/pic/item/9213b07eca80653846dc8fab97dda144ad348257.jpg", @"http://pic.paopaoche.net/up/2012-2/20122220201612322865.png", @"http://img5.pcpop.com/ArticleImages/picshow/0x0/20110801/2011080114495843125.jpg", @"http://www.mangowed.com/uploads/allimg/130410/1-130410215449417.jpg"];
    NSString *urlString = imageArray[arc4random() % imageArray.count];
    
    //    NSString *urlString = @"http://imgsrc.baidu.com/forum/pic/item/9213b07eca80653846dc8fab97dda144ad348257.jpg";
    NSString *fileName = [[urlString componentsSeparatedByString:@"/"] lastObject];
    
    //判断图片是否存在,不同公司判断方式不一样
    BOOL isExist = [self isFileExistWithFilePath:[self getFileParhWithFileName:fileName]];
    //如果文件不存在,下载新图片,并且把新图片存储起来
    if (!isExist) {
        NSLog(@"load");
        [self downloadWithUrl:[NSURL URLWithString:urlString] saveWithFileName:fileName];
    }
    
    
}

//下载图片
- (void)downloadWithUrl:(NSURL *)url saveWithFileName:(NSString *)name
{
    //子线程中下载
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:data];
        
        NSString *filePath = [self getFileParhWithFileName:name]; // 保存文件的名称
        
        if ([UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES]) {// 保存成功
            NSLog(@"保存成功");
            [self deleteFileByFilePath:[self getFileParhWithFileName:[VTUserDefaults valueForKey:AdvertKey]]];
            [VTUserDefaults setValue:name forKey:AdvertKey];
            [VTUserDefaults synchronize];
        }else{
            NSLog(@"保存失败");
        }
        
    });
    
}

//根据文件名生成文件路径
- (NSString *)getFileParhWithFileName:(NSString *)fileName
{
    if (fileName) {
        //存储路径自己选择,这儿存到缓存中
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
        return filePath;
    }
    return nil;
}

//根据文件路径判断文件是否存在
- (BOOL)isFileExistWithFilePath:(NSString *)filePath
{
    if (filePath) {
        BOOL isExist = [VTFileManager fileExistsAtPath:filePath isDirectory:nil];
        return isExist;
    }
    return NO;
}

//根据路径删除图片
- (void)deleteFileByFilePath:(NSString *)filePath
{
    if (filePath) {
        [VTFileManager removeItemAtPath:filePath error:nil];
    }
}

#pragma mark 设置adView 和 calickCallback的属性关联
- (void)setAdvertView:(UIView *)advertView
{
    objc_setAssociatedObject(self, &viewKey, advertView, OBJC_ASSOCIATION_RETAIN);
}

- (UIView *)advertView
{
    return objc_getAssociatedObject(self, &viewKey);
}


- (void)setClickCallback:(ClickCallback)clickCallback
{
    objc_setAssociatedObject(self, &blockKey, clickCallback, OBJC_ASSOCIATION_RETAIN);
}

- (ClickCallback)clickCallback
{
    return objc_getAssociatedObject(self, &blockKey);
}


@end
