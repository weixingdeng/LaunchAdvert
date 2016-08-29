//
//  ViewController.m
//  LaunchAdvertDemo
//
//  Created by dengwx on 16/8/29.
//  Copyright © 2016年 wxdeng. All rights reserved.
//

#import "ViewController.h"
#import "UIViewController+LaunchAdvert.h"
#import "AdvertViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"首页";
    __weak UIViewController *WeakSelf = self;
    [self showAdvertWithUrl:nil clickCallback:^(id callback) {
        AdvertViewController *adVC = [[AdvertViewController alloc]init];
        [WeakSelf.navigationController pushViewController:adVC animated:YES];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
