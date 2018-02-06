//
//  HDJConfig.h
//  仿微信相机
//
//  Created by 洪冬介 on 2018/2/5.
//  Copyright © 2018年 洪冬介. All rights reserved.
//

#ifndef HDJConfig_h
#define HDJConfig_h

#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;


// 自适应设备宽度
#define adaptWH(w) (SCREEN_WIDTH / 375 * (w))

///当前设备是否是iPhoneX
#define isPhoneX ([UIScreen mainScreen].bounds.size.width == 375 && [UIScreen mainScreen].bounds.size.height == 812)

// 自适应设备高度 适配iphone X的刘海屏 375 x 812
#define adaptHeight(h) (isPhoneX ? (667 / 667 * (h)) : (SCREEN_HEIGHT / 667 * (h)))

// 字体大小自适应
#define adaptFont(font) ((SCREEN_WIDTH / 375 * (font) < 12.0f && font >= 12.0f) ? 12.0f : SCREEN_WIDTH / 375 * (font))

//屏幕宽度
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
//屏幕高度
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

// 颜色宏
// rgb颜色转换（16进制->10进制）
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
// 获取RGB颜色
#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define RGB(r,g,b) RGBA(r,g,b,1.0f)


#endif /* HDJConfig_h */
