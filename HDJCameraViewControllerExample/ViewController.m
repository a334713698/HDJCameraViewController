//
//  ViewController.m
//  HDJCameraViewControllerExample
//
//  Created by 洪冬介 on 2018/2/6.
//  Copyright © 2018年 洪冬介. All rights reserved.
//

#import "ViewController.h"
#import "HDJCameraViewController.h"

@interface ViewController ()<HDJCameraViewControllerDelegate>

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.imageView];
    
    UIButton* enterButton = [[UIButton alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:enterButton];
    [enterButton setTitle:@"进入相机" forState:UIControlStateNormal];
    [enterButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [enterButton addTarget:self action:@selector(enterButtonClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)enterButtonClick:(UIButton*)sender{
    HDJCameraViewController* next = [HDJCameraViewController new];
    next.timeLimit = 10;//视频的拍摄时长限制。不填或默认为10秒
    next.delegate = self;//设置代理，用于获取媒体的回调
    next.saveMediaIntoAlbum = NO;//是否保存拍摄结果。默认：不保存
    [self presentViewController:next animated:YES completion:nil];
}

#pragma mark - HDJCameraViewControllerDelegate
-(void)cameraViewController:(HDJCameraViewController *)camera didFinishMediaWithType:(HDJMediaType)mediaType withInfo:(NSDictionary<NSString *,id> *)info{
    //mediaType:返回的媒体类型。
    //info:媒介，通过key值，获取所需要的媒体。
    UIImage* image = info[HDJCameraViewControllerImage];
    self.imageView.image = image;
    if (mediaType == HDJMediaTypeVideo) {
        NSLog(@"返回视频所在的沙盒路径：%@",info[HDJCameraViewControllerVideoURL]);
    }
}

@end


