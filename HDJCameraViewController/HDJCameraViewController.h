//
//  HDJCameraViewController.h
//  仿微信相机
//
//  Created by 洪冬介 on 2018/2/2.
//  Copyright © 2018年 洪冬介. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    HDJMediaTypeVideo,
    HDJMediaTypeImage
} HDJMediaType;

UIKIT_EXTERN NSString *const HDJCameraViewControllerVideoURL;
UIKIT_EXTERN NSString *const HDJCameraViewControllerImage;

@class HDJCameraViewController;
@protocol HDJCameraViewControllerDelegate<NSObject>

@required
- (void)cameraViewController:(HDJCameraViewController *)camera didFinishMediaWithType:(HDJMediaType)mediaType withInfo:(NSDictionary<NSString *,id> *)info;

@end

@interface HDJCameraViewController : UIViewController

///是否需要将媒体存入相册。默认不存
@property (nonatomic, assign) BOOL saveMediaIntoAlbum;

///拍摄时限。默认10秒
@property (assign, nonatomic) NSTimeInterval timeLimit;

@property (nonatomic, weak) id<HDJCameraViewControllerDelegate> delegate;


@end
