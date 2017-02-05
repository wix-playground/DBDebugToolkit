//
//  UIView+DBUserInterfaceToolkit.m
//  Pods
//
//  Created by Dariusz Bukowski on 05.02.2017.
//
//

#import "UIView+DBUserInterfaceToolkit.h"
#import "NSObject+DBDebugToolkit.h"
#import "DBUserInterfaceToolkit.h"
#import "UIColor+DBUserInterfaceToolkit.h"
#import <objc/runtime.h>

static const CGFloat UIViewDebugBorderWidth = 1.0;

static NSString *const UIViewShowsDebugBorderKey = @"DBDebugToolkit_showsDebugBorder";
static NSString *const UIViewPreviousBorderColorKey = @"DBDebugToolkit_previousBorderColor";
static NSString *const UIViewPreviousBorderWidthKey = @"DBDebugToolkit_previousBorderWidth";
static NSString *const UIViewDebugBorderColorKey = @"DBDebugToolkit_debugBorderColor";

@interface UIView (DBUserInterfaceToolkitPrivate)

@property (nonatomic) BOOL showsDebugBorder;
@property (nonatomic) CGColorRef previousBorderColor;
@property (nonatomic) CGFloat previousBorderWidth;
@property (nonatomic) CGColorRef debugBorderColor;

@end

@implementation UIView (DBUserInterfaceToolkitPrivate)

#pragma mark - ShowsDebugBorder property

- (void)setShowsDebugBorder:(BOOL)showsDebugBorder {
    objc_setAssociatedObject(self, (__bridge const void*)UIViewShowsDebugBorderKey, @(showsDebugBorder), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)showsDebugBorder {
    NSNumber *showsDebugBorder = objc_getAssociatedObject(self, (__bridge const void*)UIViewShowsDebugBorderKey);
    return showsDebugBorder.boolValue;
}

#pragma mark - PreviousBorderColor property

- (void)setPreviousBorderColor:(CGColorRef)previousBorderColor {
    UIColor *color = [UIColor colorWithCGColor:previousBorderColor];
    objc_setAssociatedObject(self, (__bridge const void*)UIViewPreviousBorderColorKey, color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGColorRef)previousBorderColor {
    UIColor *previousBorderColor = objc_getAssociatedObject(self, (__bridge const void*)UIViewPreviousBorderColorKey);
    return previousBorderColor.CGColor;
}

#pragma mark - PreviousBorderWidth property

- (void)setPreviousBorderWidth:(CGFloat)previousBorderWidth {
    objc_setAssociatedObject(self, (__bridge const void*)UIViewPreviousBorderWidthKey, @(previousBorderWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)previousBorderWidth {
    NSNumber *previousBorderWidth = objc_getAssociatedObject(self, (__bridge const void*)UIViewPreviousBorderWidthKey);
    return previousBorderWidth.doubleValue;
}

#pragma mark - DebugBorderColor property

- (void)setDebugBorderColor:(CGColorRef)debugBorderColor {
    UIColor *color = [UIColor colorWithCGColor:debugBorderColor];
    objc_setAssociatedObject(self, (__bridge const void*)UIViewDebugBorderColorKey, color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGColorRef)debugBorderColor {
    UIColor *debugBorderColor = objc_getAssociatedObject(self, (__bridge const void*)UIViewDebugBorderColorKey);
    if (!debugBorderColor) {
        debugBorderColor = [UIColor randomColor];
        [self setDebugBorderColor:debugBorderColor.CGColor];
    }
    return debugBorderColor.CGColor;
}

@end

@implementation UIView (DBUserInterfaceToolkit)

#pragma mark - Method swizzling

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __block IMP originalInitWithCoderIMP = [self replaceMethodWithSelector:@selector(initWithCoder:)
                                                                         block:^UIView * (UIView *blockSelf, NSCoder *aDecoder) {
                                                                            UIView *res = ((UIView * (*)(id, SEL, NSCoder *))originalInitWithCoderIMP)(blockSelf, @selector(initWithCoder:), aDecoder);
                                                                            [res db_refreshDebugBorders];
                                                                            [res db_registerForNotifications];
                                                                            return res;
                                                                         }];
        __block IMP originalInitWithFrameIMP = [self replaceMethodWithSelector:@selector(initWithFrame:)
                                                                         block:^UIView * (UIView *blockSelf, CGRect frame) {
                                                                             UIView *res = ((UIView * (*)(id, SEL, CGRect))originalInitWithFrameIMP)(blockSelf, @selector(initWithCoder:), frame);
                                                                             [res db_refreshDebugBorders];
                                                                             [res db_registerForNotifications];
                                                                             return res;
                                                                         }];
        __block IMP originalDeallocIMP = [self replaceMethodWithSelector:NSSelectorFromString(@"dealloc")
                                                                   block:^(__unsafe_unretained UIView *blockSelf) {
                                                                       [[NSNotificationCenter defaultCenter] removeObserver:blockSelf];
                                                                       ((void (*)(id, SEL))originalDeallocIMP)(blockSelf, NSSelectorFromString(@"dealloc"));
                                                                   }];
    });
}

#pragma mark - Colorized debug borders notifications

- (void)db_registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(db_handleColorizedDebugBordersChangedNotification:)
                                                 name:DBUserInterfaceToolkitColorizedViewBordersChangedNotification
                                               object:nil];
}

- (void)db_handleColorizedDebugBordersChangedNotification:(NSNotification *)notification {
    [self db_refreshDebugBorders];
}

#pragma mark - Handling debug borders

- (void)db_refreshDebugBorders {
    if ([DBUserInterfaceToolkit sharedInstance].colorizedViewBordersEnabled) {
        [self db_showDebugBorders];
    } else {
        [self db_hideDebugBorders];
    }
}

- (void)db_showDebugBorders {
    if (self.showsDebugBorder) {
        return;
    }
    
    self.showsDebugBorder = YES;
    
    self.previousBorderWidth = self.layer.borderWidth;
    self.previousBorderColor = self.layer.borderColor;
    
    self.layer.borderColor = self.debugBorderColor;
    self.layer.borderWidth = UIViewDebugBorderWidth;
}

- (void)db_hideDebugBorders {
    if (!self.showsDebugBorder) {
        return;
    }
    
    self.showsDebugBorder = NO;
    
    self.layer.borderWidth = self.previousBorderWidth;
    self.layer.borderColor = self.previousBorderColor;
}

@end
