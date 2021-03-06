# HDJCameraViewController——仿微信相机


## 使用方法


### 0.导入系统库
```objc
    AVFoundation.framework
```

### 1.创建并进入相机控制器
```objc
    HDJCameraViewController* next = [HDJCameraViewController new];
    next.timeLimit = 10;//视频的拍摄时长限制。不填或默认为10秒
    next.delegate = self;//设置代理，用于获取媒体的回调
    next.saveMediaIntoAlbum = NO;//是否保存拍摄结果。默认：不保存
    [self presentViewController:next animated:YES completion:nil];
```

### 2.遵守delegate代理协议
```objc
    <HDJCameraViewControllerDelegate>
```

### 3.实现代理方法
```objc
- (void)cameraViewController:(HDJCameraViewController *)camera didFinishMediaWithType:(HDJMediaType)mediaType withInfo:(NSDictionary<NSString *,id> *)info{
    //mediaType:返回的媒体类型。
    //info:媒介，通过key值，获取所需要的媒体。
    UIImage* image = info[HDJCameraViewControllerImage];
    self.imageView.image = image;
    if (mediaType == HDJMediaTypeVideo) {
        NSLog(@"返回视频所在的沙盒路径：%@",info[HDJCameraViewControllerVideoURL]);
    }
}
```

### 安装
Use CocoaPods
```objc
    pod 'HDJCameraViewController'
```

### 可能出现的问题及解决办法
编译报错：Cannot synthesize weak property because the current deployment target does not support weak references
* 解决办法一（推荐）：集成项目后，可能需要手动更新设置（处理系统报警告：⚠️validate project settings）
* 解决办法二：将Build Settings --> iOS Deployment Target 改为 iOS 9.0（支持的最低iOS版本）
* 解决办法三：手动导入支持文件


### 注意事项
需要在info.plist文件中设置用户隐私访问权限
* NSPhotoLibraryUsageDescription : 相册权限
* NSCameraUsageDescription         : 相机权限
* NSMicrophoneUsageDescription  : 麦克风权限
* NSPhotoLibraryAddUsageDescription : 媒体库添加权限

## 参考项目
* [KJCamera](https://github.com/hkjin/KJCamera)

