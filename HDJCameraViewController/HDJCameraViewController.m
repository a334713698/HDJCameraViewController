//
//  HDJCameraViewController.m
//  仿微信相机
//
//  Created by 洪冬介 on 2018/2/2.
//  Copyright © 2018年 洪冬介. All rights reserved.
//

#import "HDJCameraViewController.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "HDJPlayer.h"
#import "HDJProgressView.h"

NSString *const HDJCameraViewControllerVideoURL = @"HDJCameraViewControllerVideoURL";
NSString *const HDJCameraViewControllerImage = @"HDJCameraViewControllerImage";

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface HDJCameraViewController ()<AVCaptureFileOutputRecordingDelegate, HDJProgressViewDelegate>

//轻触拍照，按住摄像
@property (strong, nonatomic) UILabel *tipLabel;

//视频输出流
@property (strong,nonatomic) AVCaptureMovieFileOutput *captureMovieFileOutput;
//负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput;
//后台任务标识
@property (assign,nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (assign,nonatomic) UIBackgroundTaskIdentifier lastBackgroundTaskIdentifier;

//聚焦光标
@property (strong, nonatomic) UIImageView *focusCursor;

//负责输入和输出设备之间的数据传递
@property(nonatomic)AVCaptureSession *session;

//图像预览层，实时显示捕获的图像
@property(nonatomic)AVCaptureVideoPreviewLayer *previewLayer;

@property (strong, nonatomic) UIButton *backButton;
//重拍
@property (strong, nonatomic) UIButton *remakeButton;
//确定
@property (strong, nonatomic) UIButton *confirmButton;
//摄像头切换
@property (strong, nonatomic) UIButton *cameraButton;

@property (strong, nonatomic) UIImageView *bgImageView;

//是否在对焦
@property (assign, nonatomic) BOOL isFocus;

//视频播放
@property (strong, nonatomic) HDJPlayer *player;

@property (strong, nonatomic) HDJProgressView *progressView;
//@property (nonatomic, strong) UIImageView *progressMaskView;


//是否是摄像 YES 代表是录制  NO 表示拍照
@property (assign, nonatomic) BOOL isVideo;

@property (strong, nonatomic) UIImage *takeImage;
@property (strong, nonatomic) UIImageView *takeImageView;
@property (strong, nonatomic) UIImageView *recordImageView;

//记录需要保存视频的路径
@property (strong, nonatomic) NSURL *saveVideoUrl;

@end

//时间大于这个就是视频，否则为拍照
#define TimeMax 0.5

//各个控件的高宽
#define backButton_WH 40
#define remakeButton_WH 70
#define confirmButton_WH 70
#define cameraButton_WH 37
#define progressView_WH 80
#define recordImageView_WH 66

#define progressView_bgColor [UIColor colorWithRed:216/255.0 green:212/255.0 blue:208/255.0 alpha:1.0]

@implementation HDJCameraViewController{
    CGPoint BTN_CENTER_POINT;
}

#pragma mark - lazy load
- (UIImageView *)bgImageView{
    if (!_bgImageView) {
        _bgImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _bgImageView.userInteractionEnabled = YES;
        [self.view addSubview:_bgImageView];
    }
    return _bgImageView;
}

- (UILabel *)tipLabel{
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, BTN_CENTER_POINT.y - adaptWH(progressView_WH / 2) - 20 - 20, SCREEN_WIDTH, 20)];
        _tipLabel.font = [UIFont systemFontOfSize:15];
        _tipLabel.textColor  = [UIColor whiteColor];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.text = @"轻触拍照，按住摄像";
        [self.view addSubview:_tipLabel];
    }
    return _tipLabel;
}

- (UIImageView *)focusCursor{
    if (!_focusCursor) {
        _focusCursor = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, adaptWH(60), adaptWH(60))];
        _focusCursor.image = [UIImage imageNamed:@"icon_focusing"];
        [self.view addSubview:_focusCursor];
    }
    return _focusCursor;
}

- (UIImageView *)recordImageView{
    if (!_recordImageView) {
        _recordImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, adaptWH(recordImageView_WH), adaptWH(recordImageView_WH))];
        _recordImageView.image = [UIImage imageNamed:@"icon_circle"];
        [self.view addSubview:_recordImageView];
        _recordImageView.userInteractionEnabled = YES;
        _recordImageView.center = BTN_CENTER_POINT;
    }
    return _recordImageView;
}

- (UIButton *)remakeButton{
    if (!_remakeButton) {
        _remakeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, adaptWH(remakeButton_WH), adaptWH(remakeButton_WH))];
        [self.view addSubview:_remakeButton];
        [_remakeButton setImage:[UIImage imageNamed:@"icon_cancel"] forState:UIControlStateNormal];
        _remakeButton.center = BTN_CENTER_POINT;
        [_remakeButton addTarget:self action:@selector(onAfreshAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _remakeButton;
}

- (UIButton *)confirmButton{
    if (!_confirmButton) {
        _confirmButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, adaptWH(confirmButton_WH), adaptWH(confirmButton_WH))];
        [self.view addSubview:_confirmButton];
        [_confirmButton setImage:[UIImage imageNamed:@"icon_confirm"] forState:UIControlStateNormal];
        _confirmButton.center = BTN_CENTER_POINT;
        [_confirmButton addTarget:self action:@selector(onEnsureAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (UIButton *)backButton{
    if (!_backButton) {
        _backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, adaptWH(backButton_WH), adaptWH(backButton_WH))];
        [self.view addSubview:_backButton];
        [_backButton setImage:[UIImage imageNamed:@"icon_back"] forState:UIControlStateNormal];
        _backButton.center = CGPointMake(SCREEN_WIDTH*0.25, BTN_CENTER_POINT.y);
        [_backButton addTarget:self action:@selector(onCancelAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIButton *)cameraButton{
    if (!_cameraButton) {
        _cameraButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, adaptWH(cameraButton_WH), adaptWH(cameraButton_WH))];
        [self.view addSubview:_cameraButton];
        [_cameraButton setImage:[UIImage imageNamed:@"icon_camera"] forState:UIControlStateNormal];
        _cameraButton.center = CGPointMake(SCREEN_WIDTH*0.75, BTN_CENTER_POINT.y);
        [_cameraButton addTarget:self action:@selector(onCameraAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraButton;
}

- (HDJProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[HDJProgressView alloc] initWithFrame:CGRectMake(0, 0, adaptWH(progressView_WH), adaptWH(progressView_WH))];
        [self.view addSubview:_progressView];
        _progressView.delegate = self;
        _progressView.layer.cornerRadius = adaptWH(progressView_WH) / 2.0;
        _progressView.layer.masksToBounds = YES;
        _progressView.backgroundColor = progressView_bgColor;
        _progressView.center = BTN_CENTER_POINT;
    }
    return _progressView;
}

- (UIImageView *)takeImageView{
    if (!_takeImageView) {
        _takeImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        [self.bgImageView addSubview:_takeImageView];
    }
    return _takeImageView;
}

//- (UIImageView *)progressMaskView{
//    if (!_progressMaskView) {
//        _progressMaskView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, adaptWH(recordImageView_WH), adaptWH(recordImageView_WH))];
//        [self.view addSubview:_progressMaskView];
//        _progressMaskView.center = BTN_CENTER_POINT;
//        _progressMaskView.image = [UIImage imageNamed:@"progressMaskBGColor"];
//    }
//    return _progressMaskView;
//}

#pragma mark - view func
- (void)dealloc{
    [self removeNotification];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    BTN_CENTER_POINT = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT - adaptWH(100));
    
    if (self.timeLimit == 0) {
        self.timeLimit = 10;
    }

    [self customCamera];

    [self initializeCustomView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.session startRunning];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.session stopRunning];
}

#pragma mark - method
- (void)initializeCustomView{
    
    self.remakeButton.hidden = YES;
    self.confirmButton.hidden = YES;
//    self.progressMaskView.hidden = YES;
    
    self.progressView.hidden = NO;
    self.recordImageView.hidden = NO;
    self.cameraButton.hidden = NO;
    self.backButton.hidden = NO;
    [self showTipsLabel];
    [self performSelector:@selector(hiddenTipsLabel) withObject:nil afterDelay:2];

}

- (void)customCamera {
    
    //初始化会话，用来结合输入输出
    self.session = [[AVCaptureSession alloc] init];
    //设置分辨率 (设备支持的最高分辨率)
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
    }
    //取得后置摄像头
    AVCaptureDevice *captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    //添加一个音频输入设备
    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    
    //初始化输入设备
    NSError *error = nil;
    self.captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    
    //添加音频
    error = nil;
    AVCaptureDeviceInput *audioCaptureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    
    //输出对象
    self.captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];//视频输出
    
    //将输入设备添加到会话
    if ([self.session canAddInput:self.captureDeviceInput]) {
        [self.session addInput:self.captureDeviceInput];
        [self.session addInput:audioCaptureDeviceInput];
        //设置视频防抖
        AVCaptureConnection *connection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([connection isVideoStabilizationSupported]) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        }
    }
    
    //将输出设备添加到会话 (刚开始 是照片为输出对象)
    if ([self.session canAddOutput:self.captureMovieFileOutput]) {
        [self.session addOutput:self.captureMovieFileOutput];
    }
    
    //创建视频预览层，用于实时展示摄像头状态
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = self.view.bounds;//CGRectMake(0, 0, self.view.width, self.view.height);
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
    [self.bgImageView.layer addSublayer:self.previewLayer];
    
    [self addNotificationToCaptureDevice:captureDevice];
    [self addGenstureRecognizer];
}

- (void)endRecord {
    [self.captureMovieFileOutput stopRecording];//停止录制
}

- (void)showTipsLabel {
    WS(weakSelf)
    self.tipLabel.alpha = 0.01;
    [UIView animateWithDuration:0.25 animations:^{
        weakSelf.tipLabel.alpha = 1;
    }];
}

- (void)hiddenTipsLabel {
    WS(weakSelf)
    [UIView animateWithDuration:0.25 animations:^{
        weakSelf.tipLabel.alpha = 0.01;
    } completion:^(BOOL finished) {
        if (finished && _tipLabel) {
            [_tipLabel removeFromSuperview];
            _tipLabel = nil;
        }
    }];
}

- (void)didFinish{
    HDJMediaType type;
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    if (self.saveVideoUrl) {
        type = HDJMediaTypeVideo;
        [info setValue:self.takeImage forKey:HDJCameraViewControllerImage];
        [info setValue:self.saveVideoUrl forKey:HDJCameraViewControllerVideoURL];
    }else{
        type = HDJMediaTypeImage;
        [info setValue:self.takeImage forKey:HDJCameraViewControllerImage];
    }
    if ([self.delegate respondsToSelector:@selector(cameraViewController:didFinishMediaWithType:withInfo:)]) {
        [self.delegate cameraViewController:self didFinishMediaWithType:type withInfo:[info copy]];
    }
}

#pragma mark - touch method
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([[touches anyObject] view] == self.recordImageView) {
        NSLog(@"开始录制");
        self.backButton.hidden = YES;
        self.cameraButton.hidden = YES;

        //根据设备输出获得连接
        AVCaptureConnection *connection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeAudio];
        //根据连接取得设备输出的数据
        if (![self.captureMovieFileOutput isRecording]) {
            //如果支持多任务则开始多任务
            if ([[UIDevice currentDevice] isMultitaskingSupported]) {
                self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
            }
//            if (self.saveVideoUrl) {
//                [[NSFileManager defaultManager] removeItemAtURL:self.saveVideoUrl error:nil];
//            }
            //预览图层和视频方向保持一致
            connection.videoOrientation = [self.previewLayer connection].videoOrientation;
            NSDateFormatter* format = [NSDateFormatter new];
            format.dateFormat = @"yyyyMMddHHmmss";
            NSString* dateStr = [format stringFromDate:[NSDate new]];
            NSString *outputFielPath=[NSTemporaryDirectory() stringByAppendingFormat:@"hdjMovie_%@.mov",dateStr];
            NSLog(@"save path is :%@",outputFielPath);
            NSURL *fileUrl=[NSURL fileURLWithPath:outputFielPath];
            NSLog(@"fileUrl:%@",fileUrl);
            [self.captureMovieFileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
        } else {
            [self.captureMovieFileOutput stopRecording];
        }
    }
}


- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([[touches anyObject] view] == self.recordImageView) {
        NSLog(@"结束触摸");
        if (!self.isVideo) {
            [self performSelector:@selector(endRecord) withObject:nil afterDelay:0.3];
        } else {
            self.recordImageView.hidden = YES;
            self.progressView.hidden = YES;
            [self endRecord];
        }
    }
}

#pragma mark - SEL
- (void)onCancelAction:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onAfreshAction:(UIButton *)sender {
    NSLog(@"重新录制");
    [self recoverLayout];
}

- (void)onEnsureAction:(UIButton *)sender {
    NSLog(@"确定 这里进行保存或者发送出去");
    
    if (!self.saveMediaIntoAlbum) {
        [self didFinish];
        [self onCancelAction:nil];
        return;
    }
    
    if (self.saveVideoUrl) {
        WS(weakSelf)
        UISaveVideoAtPathToSavedPhotosAlbum([weakSelf.saveVideoUrl path], self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    } else {
        //照片
        UIImageWriteToSavedPhotosAlbum(self.takeImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}

//前后摄像头的切换
- (void)onCameraAction:(UIButton *)sender {
    NSLog(@"切换摄像头");
    AVCaptureDevice *currentDevice=[self.captureDeviceInput device];
    AVCaptureDevicePosition currentPosition=[currentDevice position];
    [self removeNotificationFromCaptureDevice:currentDevice];
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition = AVCaptureDevicePositionFront;//前
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront) {
        toChangePosition = AVCaptureDevicePositionBack;//后
    }
    toChangeDevice=[self getCameraDeviceWithPosition:toChangePosition];
    [self addNotificationToCaptureDevice:toChangeDevice];
    //获得要调整的设备输入对象
    AVCaptureDeviceInput *toChangeDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
    
    //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [self.session beginConfiguration];
    //移除原有输入对象
    [self.session removeInput:self.captureDeviceInput];
    //添加新的输入对象
    if ([self.session canAddInput:toChangeDeviceInput]) {
        [self.session addInput:toChangeDeviceInput];
        self.captureDeviceInput = toChangeDeviceInput;
    }
    //提交会话配置
    [self.session commitConfiguration];
}


/**
 *  保存图片到相册结果回调
 */
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSLog(@"%@",error);
    if (error) {
//        [MBProgressHUD showError:@"保存失败"];
        NSLog(@"保存图片到相簿过程中发生错误，错误信息：%@",error.localizedDescription);
    }else{
//        [MBProgressHUD showSuccess:@"保存成功"];
        NSLog(@"成功保存图片到相簿");
        [self didFinish];
        [self onCancelAction:nil];
    }
}

/**
 *  保存视频到相册结果回调
 */
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    NSLog(@"outputUrl:%@",self.saveVideoUrl);
//            [[NSFileManager defaultManager] removeItemAtURL:weakSelf.saveVideoUrl error:nil];
    if (self.lastBackgroundTaskIdentifier!= UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.lastBackgroundTaskIdentifier];
    }
    if (error) {
//                [MBProgressHUD showError:@"保存视频到相册发生错误"];
        NSLog(@"保存视频到相簿过程中发生错误，错误信息：%@",error.localizedDescription);
    } else {
//                [MBProgressHUD showSuccess:@"成功保存视频到相簿."];
        NSLog(@"成功保存视频到相簿");
        
        [self didFinish];
        [self onCancelAction:nil];
    }

}


#pragma mark - HProgressViewDelegate
- (void)finishWithProgressView:(HDJProgressView*)progressView{
    if ([self.captureMovieFileOutput isRecording]) {
        [self.captureMovieFileOutput stopRecording];
    }
}

#pragma mark - 视频输出代理
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制...");
    [self performSelector:@selector(judgeVideo) withObject:nil afterDelay:TimeMax];
}

- (void)judgeVideo{
    if ([self.captureMovieFileOutput isRecording]) {
        NSLog(@"开始录制");
        //        仿微信动画
        //        WS(weakSelf)
        //        self.progressMaskView.hidden = NO;
        //        [UIView animateWithDuration:0.25 animations:^{
        //            weakSelf.progressMaskView.frame = weakSelf.progressView.frame;
        //            weakSelf.recordImageView.transform = CGAffineTransformMakeScale(0.7, 0.7);
        //        } completion:^(BOOL finished) {
        //            if (finished) {
        //                weakSelf.isVideo = YES;//长按时间超过TimeMax 表示是视频录制
        //                weakSelf.progressView.timeMax = self.timeLimit;
        //            }
        //        }];

        self.isVideo = YES;//长按时间超过TimeMax 表示是视频录制
        self.progressView.timeMax = self.timeLimit;
    }
}


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    NSLog(@"视频录制完成.");
    [self changeLayout];
    if (self.isVideo) {
        self.saveVideoUrl = outputFileURL;
        if (!self.player) {
            self.player = [[HDJPlayer alloc] initWithFrame:self.bgImageView.bounds withShowInView:self.bgImageView url:outputFileURL];
        } else {
            if (outputFileURL) {
                self.player.videoUrl = outputFileURL;
                self.player.hidden = NO;
            }
        }
        [self videoHandlePhoto:outputFileURL];
    } else {
        //照片
        self.saveVideoUrl = nil;
        [self videoHandlePhoto:outputFileURL];
    }
    
}

- (void)videoHandlePhoto:(NSURL *)url {
    AVURLAsset *urlSet = [AVURLAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlSet];
    imageGenerator.appliesPreferredTrackTransform = YES;    // 截图的时候调整到正确的方向
    NSError *error = nil;
    CMTime time = CMTimeMake(0,30);//缩略图创建时间 CMTime是表示电影时间信息的结构体，第一个参数表示是视频第几秒，第二个参数表示每秒帧数.(如果要获取某一秒的第几帧可以使用CMTimeMake方法)
    CMTime actucalTime; //缩略图实际生成的时间
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:&actucalTime error:&error];
    if (error) {
        NSLog(@"截取视频图片失败:%@",error.localizedDescription);
    }
    CMTimeShow(actucalTime);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    if (image) {
        NSLog(@"视频截取成功");
    } else {
        NSLog(@"视频截取失败");
    }

    self.takeImage = image;
    
    if (!self.isVideo) {
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        self.takeImageView.hidden = NO;
        self.takeImageView.image = self.takeImage;
    }
}

#pragma mark - 通知

//注册通知
- (void)setupObservers
{
    NSNotificationCenter *notification = [NSNotificationCenter defaultCenter];
    [notification addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
}

//进入后台就退出视频录制
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self onCancelAction:nil];
}

/**
 *  给输入设备添加通知
 */
- (void)addNotificationToCaptureDevice:(AVCaptureDevice *)captureDevice{
    //注意添加区域改变捕获通知必须首先设置设备允许捕获
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled=YES;
    }];
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //捕获区域发生改变
    [notificationCenter addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}
- (void)removeNotificationFromCaptureDevice:(AVCaptureDevice *)captureDevice{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}
/**
 *  移除所有通知
 */
- (void)removeNotification{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
}

- (void)addNotificationToCaptureSession:(AVCaptureSession *)captureSession{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //会话出错
    [notificationCenter addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:captureSession];
}

/**
 *  设备连接成功
 *
 *  @param notification 通知对象
 */
- (void)deviceConnected:(NSNotification *)notification{
    NSLog(@"设备已连接...");
}
/**
 *  设备连接断开
 *
 *  @param notification 通知对象
 */
- (void)deviceDisconnected:(NSNotification *)notification{
    NSLog(@"设备已断开.");
}
/**
 *  捕获区域改变
 *
 *  @param notification 通知对象
 */
- (void)areaChange:(NSNotification *)notification{
    NSLog(@"捕获区域改变...");
}

/**
 *  会话出错
 *
 *  @param notification 通知对象
 */
- (void)sessionRuntimeError:(NSNotification *)notification{
    NSLog(@"会话发生错误.");
}



/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

/**
 *  改变设备属性的统一操作方法
 *
 *  @param propertyChange 属性改变操作
 */
- (void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        //自动白平衡
        if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        }
        //自动根据环境条件开启闪光灯
        if ([captureDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
            [captureDevice setFlashMode:AVCaptureFlashModeAuto];
        }
        
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

/**
 *  设置闪光灯模式
 *
 *  @param flashMode 闪光灯模式
 */
- (void)setFlashMode:(AVCaptureFlashMode )flashMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFlashModeSupported:flashMode]) {
            [captureDevice setFlashMode:flashMode];
        }
    }];
}
/**
 *  设置聚焦模式
 *
 *  @param focusMode 聚焦模式
 */
- (void)setFocusMode:(AVCaptureFocusMode )focusMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:focusMode];
        }
    }];
}
/**
 *  设置曝光模式
 *
 *  @param exposureMode 曝光模式
 */
- (void)setExposureMode:(AVCaptureExposureMode)exposureMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:exposureMode];
        }
    }];
}
/**
 *  设置聚焦点
 *
 *  @param point 聚焦点
 */
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        //        if ([captureDevice isFocusPointOfInterestSupported]) {
        //            [captureDevice setFocusPointOfInterest:point];
        //        }
        //        if ([captureDevice isExposurePointOfInterestSupported]) {
        //            [captureDevice setExposurePointOfInterest:point];
        //        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:exposureMode];
        }
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:focusMode];
        }
    }];
}

/**
 *  添加点按手势，点按时聚焦
 */
- (void)addGenstureRecognizer{
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    [self.bgImageView addGestureRecognizer:tapGesture];
}

- (void)tapScreen:(UITapGestureRecognizer *)tapGesture{
    if ([self.session isRunning]) {
        CGPoint point= [tapGesture locationInView:self.bgImageView];
        //将UI坐标转化为摄像头坐标
        CGPoint cameraPoint= [self.previewLayer captureDevicePointOfInterestForPoint:point];
        [self setFocusCursorWithPoint:point];
        [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposureMode:AVCaptureExposureModeContinuousAutoExposure atPoint:cameraPoint];
    }
}

/**
 *  设置聚焦光标位置
 *
 *  @param point 光标位置
 */
- (void)setFocusCursorWithPoint:(CGPoint)point{
    if (!self.isFocus) {
        self.isFocus = YES;
        self.focusCursor.center=point;
        self.focusCursor.transform = CGAffineTransformMakeScale(1.25, 1.25);
        self.focusCursor.alpha = 1.0;
        [UIView animateWithDuration:0.5 animations:^{
            self.focusCursor.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [self performSelector:@selector(onHiddenFocusCurSorAction) withObject:nil afterDelay:0.5];
        }];
    }
}

- (void)onHiddenFocusCurSorAction {
    self.focusCursor.alpha=0;
    self.isFocus = NO;
}

//拍摄完成时调用
- (void)changeLayout {
    self.recordImageView.hidden = YES;
    self.progressView.hidden = YES;
    self.cameraButton.hidden = YES;
    self.remakeButton.hidden = NO;
    self.confirmButton.hidden = NO;
    self.backButton.hidden = YES;
    if (self.isVideo) {
        [self.progressView clearProgress];
//        self.recordImageView.transform = CGAffineTransformIdentity;
//        self.progressMaskView.frame = self.recordImageView.frame;
//        self.progressMaskView.hidden = YES;
    }
    

    [UIView animateWithDuration:0.25 animations:^{
        self.remakeButton.center = CGPointMake(SCREEN_WIDTH*0.25, BTN_CENTER_POINT.y);
        self.confirmButton.center = CGPointMake(SCREEN_WIDTH*0.75, BTN_CENTER_POINT.y);
        [self.view layoutIfNeeded];
    }];
    
    self.lastBackgroundTaskIdentifier = self.backgroundTaskIdentifier;
    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    [self.session stopRunning];
}


//重新拍摄时调用
- (void)recoverLayout {
    if (self.isVideo) {
        self.isVideo = NO;
        [self.player stopPlayer];
        self.player.hidden = YES;
    }
    [self.session startRunning];
    
    if (!self.takeImageView.hidden) {
        self.takeImageView.hidden = YES;
    }

    self.remakeButton.center = BTN_CENTER_POINT;
    self.confirmButton.center = BTN_CENTER_POINT;

    self.recordImageView.hidden = NO;
    self.progressView.hidden = NO;
    self.cameraButton.hidden = NO;
    self.remakeButton.hidden = YES;
    self.confirmButton.hidden = YES;
    self.backButton.hidden = NO;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Method
- (BOOL)prefersStatusBarHidden{
    return YES;
}


@end
