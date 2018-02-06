//
//  HDJPlayer.h
//  仿微信相机
//
//  Created by 洪冬介 on 2018/2/3.
//  Copyright © 2018年 洪冬介. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HDJPlayer : UIView

- (instancetype)initWithFrame:(CGRect)frame withShowInView:(UIView *)bgView url:(NSURL *)url;

@property (copy, nonatomic) NSURL *videoUrl;

- (void)stopPlayer;

@end
