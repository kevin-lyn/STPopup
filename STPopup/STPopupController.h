//
//  STPopupController.h
//  STPopup
//
//  Created by Kevin Lin on 11/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <STPopup/STPopupNavigationBar.h>

typedef NS_ENUM(NSUInteger, STPopupStyle) {
    /**
     Popup will be vertically and horizontally centered.
     */
    STPopupStyleFormSheet,
    /**
     Popup will be horizontally centered and sticked to bottom.
     */
    STPopupStyleBottomSheet
};

typedef NS_ENUM(NSUInteger, STPopupTransitionStyle) {
    /**
     Slide from bottom to center.
     */
    STPopupTransitionStyleSlideVertical,
    /**
     Fade-in in center from transparent to opaque.
     */
    STPopupTransitionStyleFade
};

@interface STPopupController : NSObject

/**
 Style decides the final position of a popup.
 @see STPopupStyle
 */
@property (nonatomic, assign) STPopupStyle style;

/**
 Transition style used in presenting and dismissing the popup.
 @see STPopupTransitionStyle
 */
@property (nonatomic, assign) STPopupTransitionStyle transitionStyle;

/**
 Corner radius of the container view.
 */
@property (nonatomic, assign) CGFloat cornerRadius DEPRECATED_MSG_ATTRIBUTE("Use containerView.layer.cornerRadius instead");

/**
 Hidden status of navigation bar of popup.
 */
@property (nonatomic, assign) BOOL navigationBarHidden;

/**
 Navigation bar of popup.
 @see STPopupNavigationBar
 */
@property (nonatomic, strong, readonly) STPopupNavigationBar *navigationBar;

/**
 Background view which is between popup and the view presenting popup.
 By default it's a UIView with background color [UIColor colorWithWhite:0 alpha:0.5].
 */
@property (nonatomic, strong) UIView *backgroundView;

/**
 Container view which is containing the navigation bar and content of top most view controller.
 By default its background color is set to white and clipsToBounds is set to YES.
 */
@property (nonatomic, strong, readonly) UIView *containerView;

/**
 Indicates if the popup is current presented.
 */
@property (nonatomic, assign, readonly) BOOL presented;

/**
 Init the popup with root view controller.
 */
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;

/**
 Present the popup with transition style on a given view controller.
 @see transitionStyle
 */
- (void)presentInViewController:(UIViewController *)viewController;

/**
 Present the popup with transition style on a given view controller.
 Completion block will be called after the presenting transition is finished.
 @see transitionStyle
 */
- (void)presentInViewController:(UIViewController *)viewController completion:(void (^)(void))completion;

/**
 Dismiss the popup with transition style.
 @see transitionStyle
 */
- (void)dismiss;

/**
 Dismiss the popup with transition style.
 Completion block will be called after dismissing transition is finished.
 @see transitionStyle
 */
- (void)dismissWithCompletion:(void (^)(void))completion;

/**
 Push a view controller into view controllers stack with animated flag.
 */
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/**
 Pop the top most view controller out of view controllers stack with animated flag.
 */
- (void)popViewControllerAnimated:(BOOL)animated;

/**
 Set hidden status of navigation bar with animated flag.
 @see navigationBarHidden
 */
- (void)setNavigationBarHidden:(BOOL)navigationBarHidden animated:(BOOL)animated;

@end