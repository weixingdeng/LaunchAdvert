//
//  UIViewController+LaunchAdvert.h
//  FirstLaunchDemo
//
//  Created by dengwx on 16/8/29.
//  Copyright © 2016年 wxdeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (LaunchAdvert)
/**
 *  显示广告
 *
 *  @param imageUrl 广告的链接
 *  @param callback 点击广告后的回调
 */
- (void)showAdvertWithUrl:(NSURL *)imageUrl clickCallback:(void (^)(id callback))callback;
@end
