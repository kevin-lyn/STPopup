//
//  STPopupController.h
//  STPopup
//
//  Created by Kevin Lin on 11/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPopupNavigationBar.h"

typedef NS_ENUM(NSUInteger, STPopupStyle) {
    STPopupStyleFormSheet,
    STPopupStyleBottomSheet
};

typedef NS_ENUM(NSUInteger, STPopupTransitionStyle) {
    STPopupTransitionStyleSlideVertical,
    STPopupTransitionStyleFade
};

@interface STPopupController : NSObject

@property (nonatomic, assign) STPopupStyle style;
@property (nonatomic, assign) STPopupTransitionStyle transitionStyle;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) BOOL navigationBarHidden;
@property (nonatomic, strong, readonly) STPopupNavigationBar *navigationBar;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, assign, readonly) BOOL presented;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;

- (void)presentInViewController:(UIViewController *)viewController;
- (void)presentInViewController:(UIViewController *)viewController completion:(void (^)(void))completion;
- (void)dismiss;
- (void)dismissWithCompletion:(void (^)(void))completion;

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)popViewControllerAnimated:(BOOL)animated;

- (void)setNavigationBarHidden:(BOOL)navigationBarHidden animated:(BOOL)animated;

@end