//
//  HDJProgressView.h
//  仿微信相机
//
//  Created by 洪冬介 on 2018/2/3.
//  Copyright © 2018年 洪冬介. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HDJConfig.h"

@class HDJProgressView;
@protocol HDJProgressViewDelegate<NSObject>

- (void)finishWithProgressView:(HDJProgressView*)progressView;

@end

@interface HDJProgressView : UIView

@property (assign, nonatomic) NSTimeInterval timeMax;
@property (nonatomic, weak) id<HDJProgressViewDelegate> delegate;

- (void)clearProgress;

@end
