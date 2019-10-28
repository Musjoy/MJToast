//
//  MJToast.m
//  Common
//
//  Created by 黄磊 on 16/4/6.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "MJToast.h"
#import <QuartzCore/QuartzCore.h>
#if __has_include("BaseViewController.h")
#import "BaseViewController.h"
#define THEBaseViewController       BaseViewController
#elif __has_include(<MJControllerManager/MJBaseViewController.h>)
#import <MJControllerManager/MJBaseViewController.h>
#define THEBaseViewController       MJBaseViewController
#else
#define THEBaseViewController       UIViewController
#endif
#if __has_include(<MJControllerManager/MJWindowRootViewController.h>)
#import <MJControllerManager/MJWindowRootViewController.h>
#define THEWindowRootViewController       MJWindowRootViewController
#else
#define THEWindowRootViewController       THEBaseViewController
#endif

static MJToast *s_mjToast = nil;

#define DEFAULT_BOTTOM_PADDING 108    // 50
#define START_DISAPPEAR_SECOND 2.5
#define DISAPPEAR_DURATION 1.0

// toast所依附的window
UIWindow *s_toastWindows = nil;

const CGFloat MJToastTextPadding     = 5;
const CGFloat MJToastLabelWidth      = 200;
const CGFloat MJToastLabelHeight     = 200;

static float totalTimeCount = 60 * DISAPPEAR_DURATION;

@interface MJToast()

@property (nonatomic, copy) NSString *strToast;
@property (nonatomic, strong) UILabel *lblToast;

@property (nonatomic, assign) NSTimer *disappearTimer;
@property (nonatomic, assign) NSTimer *disappearingTimer;
@property (nonatomic, assign) int curToastState;        // 0:不显示;1:显示;2:正在消失
@property (nonatomic, assign) float curTimeCount;         // 当前倒计时

+ (MJToast *)sharedInstance;

- (id)initWithText:(NSString *)text;    

@end

@implementation MJToast


+ (UIWindow *)tostWindow
{
    if (s_toastWindows == nil) {
        s_toastWindows = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [s_toastWindows setBackgroundColor:[UIColor clearColor]];
        s_toastWindows.windowLevel = 10000000 + 1;
        THEWindowRootViewController *aVC = [[THEWindowRootViewController alloc] init];
        aVC.view.hidden = YES;
        [s_toastWindows setRootViewController:aVC];
        [s_toastWindows setUserInteractionEnabled:NO];
        [s_toastWindows makeKeyAndVisible];
    }
    return s_toastWindows;
}

+ (MJToast *)sharedInstance
{
    if (s_mjToast == nil) {
        s_mjToast = [[MJToast alloc] init];
        UILabel *lblPg = [[UILabel alloc]initWithFrame:CGRectZero];
        UIFont *font = [UIFont systemFontOfSize:13];
        lblPg.backgroundColor = [UIColor colorWithRed:32.0/255.0 green:33.0/255.0 blue:39.0/255.0 alpha:1.0f];
        //lblToast.backgroundColor = [UIColor lightGrayColor];
        lblPg.textColor = [UIColor whiteColor];
        //lblToast.textColor = [UIColor blackColor];
        lblPg.layer.cornerRadius = 5;
        lblPg.layer.borderWidth = 0;
        lblPg.layer.masksToBounds = YES;
        lblPg.numberOfLines = 0;
        lblPg.font = font;
        lblPg.textAlignment = NSTextAlignmentCenter;
        s_mjToast.lblToast = lblPg;

        // 添加边框
        CALayer *layer = [s_mjToast.lblToast layer];
        layer.borderColor = [[UIColor lightGrayColor] CGColor];
        layer.borderWidth = 1.0f;
        // 添加四个边阴影...(不适用于圆角view)
        //    lblToast.layer.shadowColor = [UIColor whiteColor].CGColor;
        //    lblToast.layer.shadowOffset = CGSizeMake(2, 2);
        //    lblToast.layer.shadowOpacity = 0.5;
        //    lblToast.layer.shadowRadius = 2.0;
    }
    return s_mjToast;
}


- (id)initWithText:(NSString *)text
{

    if (self = [super init])
    {
        self.strToast = text;
         
    }    
    return self;
}


+ (MJToast *)makeToast:(NSString *)text
{
    MJToast *aToast = [MJToast sharedInstance];
    aToast.strToast = text;
    return aToast;
}

- (void)show
{
    if([self.strToast isEqualToString:@""]) {
        return;
    }
    
    UIFont *font = [UIFont systemFontOfSize:13];
    CGSize textSize = [_strToast boundingRectWithSize:CGSizeMake(MJToastLabelWidth, MJToastLabelHeight)
                                              options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin)
                                           attributes:@{NSFontAttributeName:font}
                                              context:nil].size;
//    [strToast sizeWithFont:font constrainedToSize:CGSizeMake(MJToastLabelWidth, MJToastLabelHeight)];
    [_lblToast setFrame:CGRectMake(0, 0, textSize.width + 4 * MJToastTextPadding, textSize.height + 2 * MJToastTextPadding)];

    _lblToast.text = self.strToast;
    
    UIWindow *window = [MJToast tostWindow];

    if(self.lblToast.superview) {
        if (self.lblToast.superview != window) {
            [self.lblToast removeFromSuperview];
            [window addSubview:self.lblToast];
        }
    } else {
        [window addSubview:self.lblToast];
    }
    CGFloat windowCenterX = window.center.x;
    CGFloat windowHeight = window.frame.size.height;
    CGFloat centerX = windowCenterX;
    CGFloat centerY = windowHeight - DEFAULT_BOTTOM_PADDING;
    
    self.lblToast.center = CGPointMake(centerX, centerY);
    self.lblToast.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin|
                                      UIViewAutoresizingFlexibleRightMargin|
                                      UIViewAutoresizingFlexibleTopMargin);
    
    if (_curToastState == 2) {
        [_disappearingTimer invalidate];
        self.disappearingTimer = nil;
    } else if (_curToastState == 1) {
        [_disappearTimer invalidate];
        self.disappearTimer = nil;
    }
    _curToastState = 0;
    [self.lblToast setAlpha:1];
    self.disappearTimer = [NSTimer scheduledTimerWithTimeInterval:START_DISAPPEAR_SECOND target:self selector:@selector(toastDisappear:) userInfo:nil repeats:NO];
    _curToastState = 1;
}

- (void)toastDisappear:(NSTimer *)timer
{
    [self.disappearTimer invalidate];
    self.disappearTimer = nil;
    _curTimeCount = totalTimeCount;
    self.disappearingTimer = [NSTimer scheduledTimerWithTimeInterval:1/60.0 target:self selector:@selector(startDisappear:) userInfo:nil repeats:YES];
    _curToastState = 2;
}

- (void)startDisappear:(NSTimer *)timer
{
    if (_curToastState == 0) {
        [self.disappearingTimer invalidate];
        self.disappearingTimer = nil;
        return;
    }
    if (_curTimeCount >= 0) {
        [self.lblToast setAlpha:_curTimeCount/totalTimeCount];
        _curTimeCount--;
    } else {
        [self.lblToast removeFromSuperview];
        [self.disappearingTimer invalidate];
        self.disappearingTimer = nil;
        _curToastState = 0;
        s_toastWindows = nil;
    }
}

@end
