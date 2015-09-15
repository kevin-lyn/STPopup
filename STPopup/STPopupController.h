//
//  STPopupController.h
//  STPopup
//
//  Created by Kevin Lin on 11/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, STPopupTransitionStyle) {
    STPopupTransitionStyleSlideVertical,
    STPopupTransitionStyleFade
};

@interface STPopupController : NSObject

@property (nonatomic, assign) STPopupTransitionStyle transitionStyle;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, strong, readonly) UINavigationBar *navigationBar;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;

- (void)presentInViewController:(UIViewController *)viewController;
- (void)dismissWithCompletion:(void (^)(void))completion;

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)popViewControllerAnimated:(BOOL)animated;

@end