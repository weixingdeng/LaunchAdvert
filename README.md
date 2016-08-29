# LaunchAdvert
适用于每次启动时候加载广告,扩展性高,当服务器有更新时,自动保存新图片用于下次展示

使用:
  采用分类的写法,使用特别简单
  只需要把UIViewController+LaunchAdvert.h导入到头文件,然后在程序启动的位置使用:
  
  //Url:需要加载广告图片的请求地址
  
   [self showAdvertWithUrl:nil clickCallback:^(id callback) {
   
        //此处是点击广告图的回调,用于跳转到对应的界面
        
    }];
