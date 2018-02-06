//
//  HDJProgressView.m
//  仿微信相机
//
//  Created by 洪冬介 on 2018/2/3.
//  Copyright © 2018年 洪冬介. All rights reserved.
//

#import "HDJProgressView.h"

@interface HDJProgressView ()

/**
 *  进度值0-1.0之间
 */
@property (nonatomic,assign)CGFloat progressValue;

@property (nonatomic, assign) CGFloat currentTime;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSTimeInterval startSeconds;

@property (nonatomic, strong) CAShapeLayer *progressLayer;

@end

@implementation HDJProgressView{
}


- (void)dealloc{
    NSLog(@"HDJProgressView 销毁");
}

#define PROGRESS_LINE_WIDTH 10

- (CAShapeLayer *)progressLayer{
    if (!_progressLayer) {
        
        UIColor *startColor = UIColorFromRGB(0x00D0EA);
        UIColor *endColor = UIColorFromRGB(0x0091EA);

        _progressLayer = [CAShapeLayer layer];
        _progressLayer.frame = self.bounds;
        _progressLayer.fillColor =  [[UIColor clearColor] CGColor];
        _progressLayer.strokeColor  = [startColor CGColor];
        _progressLayer.lineWidth = PROGRESS_LINE_WIDTH;
        _progressLayer.strokeEnd = 0;

        //添加渐变色
        CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
        gradientLayer.colors = @[(__bridge id)startColor.CGColor,(__bridge id)endColor.CGColor];
        gradientLayer.startPoint = CGPointMake(1, 0);
        gradientLayer.endPoint = CGPointMake(0, 0);
        gradientLayer.frame = self.bounds;
        [gradientLayer setMask:_progressLayer]; //用progressLayer来截取渐变层
        [self.layer addSublayer:gradientLayer];

        CGPoint center = CGPointMake(self.frame.size.width/2.0, self.frame.size.width/2.0);  //设置圆心位置
        CGFloat radius = self.frame.size.width/2.0-5;  //设置半径
        CGFloat startA = - M_PI_2;  //圆起点位置
        CGFloat endA = -M_PI_2 + M_PI * 2 * 1;  //圆终点位置

        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startA endAngle:endA clockwise:YES];

        _progressLayer.path = [path CGPath]; //把path传递給layer，然后layer会处理相应的渲染，整个逻辑和CoreGraph是一致的。
    }
    return _progressLayer;
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    self.progressLayer.strokeEnd = _progressValue;
}

- (void)setTimeMax:(NSTimeInterval)timeMax {
    _timeMax = timeMax;
    self.currentTime = 0.0;
    self.progressValue = 0.0;
    [self setNeedsDisplay];
//    self.hidden = NO;
    
    if (_timer) {
        if ([_timer isValid]) {
            [_timer invalidate];
        }
        _timer = nil;
    }
    self.startSeconds = [[NSDate new] timeIntervalSince1970];
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(startProgress) userInfo:nil repeats:YES];
    [_timer fire];
    
}

- (void)clearProgress {
    if ([_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }

    _currentTime = 0.0;
    _progressValue = 0.0;
    [self setNeedsDisplay];

}

- (void)startProgress {
    _currentTime = [[NSDate new] timeIntervalSince1970] - self.startSeconds;
    if (_timeMax >= _currentTime) {
        _progressValue = _currentTime/_timeMax;
        NSLog(@"progress = %f",_progressValue);
        [self setNeedsDisplay];
    }
    
    if (_timeMax < _currentTime) {
        [self finish];
    }
}

- (void)finish{
    if ([self.delegate respondsToSelector:@selector(finishWithProgressView:)]) {
        [self.delegate finishWithProgressView:self];
    }
}

@end

