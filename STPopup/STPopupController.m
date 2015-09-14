//
//  STPopupController.m
//  Sth4Me
//
//  Created by Kevin Lin on 11/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "STPopupController.h"
#import "STPopupLeftBarItem.h"
#import "STPopupNavigationBar.h"
#import "UIViewController+STPopup.h"
#import "UIResponder+STPopup.h"

static NSMutableSet *_retainedPopupControllers;
CGFloat const STPopupTitleHeight = 44;

@interface STPopupContainerViewController : UIViewController

@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;

@end

@implementation STPopupContainerViewController

- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle
{
    _statusBarStyle = statusBarStyle;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.statusBarStyle;
}

@end

@interface STPopupController () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, STPopupNavigationTouchEventDelegate>

@end

@implementation STPopupController
{
    STPopupContainerViewController *_containerViewController;
    NSMutableArray *_viewControllers; // <UIViewController>
    UIView *_bgView;
    UIView *_containerView;
    UILabel *_defaultTitleLabel;
    STPopupLeftBarItem *_defaultLeftBarItem;
    UIInterfaceOrientation _orientation;
    BOOL _presented;
    NSDictionary *_keyboardInfo;
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _retainedPopupControllers = [NSMutableSet new];
    });
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
        
        // Observe navigation bar
        [_navigationBar addObserver:self forKeyPath:NSStringFromSelector(@selector(tintColor)) options:NSKeyValueObservingOptionNew context:nil];
        [_navigationBar addObserver:self forKeyPath:NSStringFromSelector(@selector(titleTextAttributes)) options:NSKeyValueObservingOptionNew context:nil];
        
        // Observe orientation change
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        
        // Observe keyboard
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
        // Observe responder change
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firstResponderDidChange:) name:STPopupFirstResponderDidChangeNotification object:nil];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    if (self = [self init]) {
        [self pushViewController:rootViewController animated:NO];
    }
    return self;
}

- (void)dealloc
{
    [_navigationBar removeObserver:self forKeyPath:NSStringFromSelector(@selector(tintColor))];
    [_navigationBar removeObserver:self forKeyPath:NSStringFromSelector(@selector(titleTextAttributes))];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    for (UIViewController *viewController in _viewControllers) { // Avoid crash when try to access unsafe unretained property
        [viewController setValue:nil forKey:@"popupController"];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _navigationBar) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(tintColor))]) {
            _defaultLeftBarItem.tintColor = change[@"new"];
        }
        else if ([keyPath isEqualToString:NSStringFromSelector(@selector(titleTextAttributes))]) {
            _defaultTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:_defaultTitleLabel.text ? : @""
                                                                                attributes:change[@"new"]];
        }
    }
}

#pragma mark - STPopupController present & dismiss & push & pop

- (void)presentInViewController:(UIViewController *)viewController
{
    if (_presented) {
        return;
    }
    
    [_retainedPopupControllers addObject:self];
    
    _bgView.alpha = 0;
    _containerView.alpha = 0; // Hide _containerView before _containerViewController is ready
    
    [viewController presentViewController:_containerViewController animated:YES completion:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self transitFromViewController:nil toViewController:[self topViewController] animated:NO];
            
            switch (self.transitionStyle) {
                case STPopupTransitionStyleFade: {
                    _containerView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                }
                    break;
                case STPopupTransitionStyleSlideVertical:
                default: {
                    _containerView.alpha = 1;
                    _containerView.transform = CGAffineTransformMakeTranslation(0, _containerViewController.view.bounds.size.height + _containerView.frame.size.height);
                }
                    break;
            }
            
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                _bgView.alpha = 1;
                _containerView.alpha = 1;
                _containerView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                _presented = YES;
            }];
        });
    }];
}

- (void)dismissWithCompletion:(void (^)(void))completion
{
    [self dismissWithTransitionStyle:self.transitionStyle withCompletion:completion];
}

- (void)dismissWithTransitionStyle:(STPopupTransitionStyle)transitionStyle withCompletion:(void (^)(void))completion
{
    if (!_presented) {
        return;
    }
    
    [_containerView endEditing:YES];
    _containerView.userInteractionEnabled = NO;
    
    NSTimeInterval duration = self.transitionStyle == STPopupTransitionStyleFade ? 0.4 : 0.7;    
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _bgView.alpha = 0;
        switch (transitionStyle) {
            case STPopupTransitionStyleFade: {
                _containerView.alpha = 0;
                _containerView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            }
                break;
            case STPopupTransitionStyleSlideVertical:
            default: {
                _containerView.transform = CGAffineTransformMakeTranslation(0, _containerViewController.view.bounds.size.height + _containerView.frame.size.height);
            }
                break;
        }
    } completion:^(BOOL finished) {
        _containerView.alpha = 0;
        _containerView.transform = CGAffineTransformIdentity;
        _containerView.userInteractionEnabled = YES;
        [_retainedPopupControllers removeObject:self];
        [_containerViewController dismissViewControllerAnimated:NO completion:^{
            _presented = NO;
            if (completion) {
                completion();
            }
        }];
    }];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (!_viewControllers) {
        _viewControllers = [NSMutableArray new];
    }
    
    UIViewController *topViewController = [self topViewController];
    [viewController setValue:self forKey:@"popupController"];
    [_viewControllers addObject:viewController];
    
    if (_presented) {
        [self transitFromViewController:topViewController toViewController:viewController animated:animated];
    }
}

- (void)popViewControllerAnimated:(BOOL)animated
{
    if (_viewControllers.count <= 1) {
        [self dismissWithCompletion:nil];
        return;
    }
    
    UIViewController *topViewController = [self topViewController];
    [topViewController setValue:nil forKey:@"popupController"];
    [_viewControllers removeObject:topViewController];
    
    if (_presented) {
        [self transitFromViewController:topViewController toViewController:[self topViewController] animated:animated];
    }
}

- (void)transitFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController animated:(BOOL)animated
{
    _containerViewController.statusBarStyle = toViewController.preferredStatusBarStyle;
    
    [self layoutTopView];
    [_containerView insertSubview:toViewController.view atIndex:0];
    
    if (animated) {
        _containerView.userInteractionEnabled = NO;
        toViewController.view.alpha = 0;
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self layoutContainerView];
            fromViewController.view.alpha = 0;
            toViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [fromViewController.view removeFromSuperview];
            fromViewController.view.alpha = 1;
            _containerView.userInteractionEnabled = YES;
        }];
        [self updateNavigationBarAniamted:animated];
    }
    else {
        [self layoutContainerView];
        [self updateNavigationBarAniamted:animated];
        [fromViewController.view removeFromSuperview];
    }
}

- (void)updateNavigationBarAniamted:(BOOL)animated
{
    UIViewController *topViewController = [self topViewController];
    UIView *lastTitleView = _navigationBar.topItem.titleView;
    _navigationBar.items = @[ [UINavigationItem new] ];
    _navigationBar.topItem.leftBarButtonItems = topViewController.navigationItem.leftBarButtonItems ? : @[ _defaultLeftBarItem ];
    _navigationBar.topItem.rightBarButtonItems = topViewController.navigationItem.rightBarButtonItems;
    
    if (animated) {
        UIView *fromTitleView, *toTitleView;
        if (lastTitleView == _defaultTitleLabel)    {
            UILabel *tempLabel = [[UILabel alloc] initWithFrame:_defaultTitleLabel.frame];
            tempLabel.textColor = _defaultTitleLabel.textColor;
            tempLabel.font = _defaultTitleLabel.font;
            tempLabel.attributedText = [[NSAttributedString alloc] initWithString:_defaultTitleLabel.text ? : @""
                                                                       attributes:_navigationBar.titleTextAttributes];
            fromTitleView = tempLabel;
        }
        else {
            fromTitleView = lastTitleView;
        }
        
        if (topViewController.navigationItem.titleView) {
            toTitleView = topViewController.navigationItem.titleView;
        }
        else {
            _defaultTitleLabel = [UILabel new];
            _defaultTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:topViewController.title ? : @""
                                                                                attributes:_navigationBar.titleTextAttributes];
            [_defaultTitleLabel sizeToFit];
            toTitleView = _defaultTitleLabel;
        }
        
        [_navigationBar addSubview:fromTitleView];
        _navigationBar.topItem.titleView = toTitleView;
        toTitleView.alpha = 0;
        
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            fromTitleView.alpha = 0;
            toTitleView.alpha = 1;
        } completion:^(BOOL finished) {
            [fromTitleView removeFromSuperview];
        }];
    }
    else {
        if (topViewController.navigationItem.titleView) {
            _navigationBar.topItem.titleView = topViewController.navigationItem.titleView;
        }
        else {
            _defaultTitleLabel = [UILabel new];
            _defaultTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:topViewController.title ? : @""
                                                                                attributes:_navigationBar.titleTextAttributes];
            [_defaultTitleLabel sizeToFit];
            _navigationBar.topItem.titleView = _defaultTitleLabel;
        }
    }
    _defaultLeftBarItem.tintColor = _navigationBar.tintColor;
    [_defaultLeftBarItem setType:_viewControllers.count > 1 ? STPopupLeftBarItemArrow : STPopupLeftBarItemCross animated:animated];
}

- (UIViewController *)topViewController
{
    return _viewControllers.lastObject;
}

#pragma mark - UI layout

- (void)layoutTopView
{
    UIViewController *topViewController = [self topViewController];
    CGSize contentSize = [self contentSizeOfTopView];
    topViewController.view.frame = CGRectMake(0, STPopupTitleHeight, contentSize.width, contentSize.height);
}

- (void)layoutContainerView
{
    _bgView.frame = _containerViewController.view.bounds;
 
    CGSize contentSizeOfTopView = [self contentSizeOfTopView];
    CGSize containerViewSize = CGSizeMake(contentSizeOfTopView.width, contentSizeOfTopView.height + STPopupTitleHeight);
    
    _containerView.frame = CGRectMake((_containerViewController.view.bounds.size.width - containerViewSize.width) / 2,
                                      (_containerViewController.view.bounds.size.height - containerViewSize.height) / 2,
                                      containerViewSize.width, containerViewSize.height);
    _navigationBar.frame = CGRectMake(0, 0, containerViewSize.width, STPopupTitleHeight);
}

- (CGSize)contentSizeOfTopView
{
    UIViewController *topViewController = [self topViewController];
    CGSize contentSize = CGSizeZero;
    switch (_orientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight: {
            contentSize = topViewController.landscapeContentSizeInPopup;
            if (CGSizeEqualToSize(contentSize, CGSizeZero)) {
                contentSize = topViewController.contentSizeInPopup;
            }
        }
            break;
        default: {
            contentSize = topViewController.contentSizeInPopup;
        }
            break;
    }
    return contentSize;
}

#pragma mark - UI setup

- (void)setup
{
    _orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    _containerViewController = [STPopupContainerViewController new];
    _containerViewController.view.backgroundColor = [UIColor clearColor];
    _containerViewController.modalPresentationStyle = UIModalPresentationCustom;
    _containerViewController.transitioningDelegate = self;
    [self setupBackgroundView];
    [self setupContainerView];
    [self setupNavigationBar];
}

- (void)setupBackgroundView
{
    _bgView = [UIView new];
    _bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _bgView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [_bgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgViewDidTap)]];
    [_containerViewController.view addSubview:_bgView];
}

- (void)setupContainerView
{
    _containerView = [UIView new];
    _containerView.backgroundColor = [UIColor whiteColor];
    _containerView.clipsToBounds = YES;
    [_containerViewController.view addSubview:_containerView];
}

- (void)setupNavigationBar
{
    STPopupNavigationBar *navigationBar = [STPopupNavigationBar new];
    navigationBar.touchEventDelegate = self;
    
    _navigationBar = navigationBar;
    [_containerView addSubview:_navigationBar];
    
    _defaultTitleLabel = [UILabel new];
    _defaultLeftBarItem = [[STPopupLeftBarItem alloc] initWithTarget:self action:@selector(leftBarItemDidTap)];
}

- (void)leftBarItemDidTap
{
    switch (_defaultLeftBarItem.type) {
        case STPopupLeftBarItemCross:
            [self dismissWithCompletion:nil];
            break;
        case STPopupLeftBarItemArrow:
            [self popViewControllerAnimated:YES];
            break;
        default:
            break;
    }
}

- (void)bgViewDidTap
{
    [_containerView endEditing:YES];
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;
    _containerView.layer.cornerRadius = self.cornerRadius;
}

#pragma mark - UIApplicationDidChangeStatusBarOrientationNotification

- (void)orientationDidChange:(NSNotification *)notification
{
    _orientation = [UIApplication sharedApplication].statusBarOrientation;
    [_containerView endEditing:YES];
    [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _containerView.alpha = 0;
    } completion:^(BOOL finished) {
        [self layoutTopView];
        [self layoutContainerView];
        [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _containerView.alpha = 1;
        } completion:nil];
    }];
}

#pragma mark - UIKeyboardWillShowNotification & UIKeyboardWillHideNotification

- (void)keyboardWillShow:(NSNotification *)notification
{
    UIView<UIKeyInput> *currentTextInput = [self getCurrentTextInputInView:_containerView];
    if (!currentTextInput) {
        return;
    }
    
    _keyboardInfo = notification.userInfo;
    [self adjustContainerViewOrigin];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    _keyboardInfo = nil;
    
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationDuration:duration];
    
    _containerView.transform = CGAffineTransformIdentity;
    
    [UIView commitAnimations];
}

- (void)adjustContainerViewOrigin
{
    if (!_keyboardInfo) {
        return;
    }
    
    UIView<UIKeyInput> *currentTextInput = [self getCurrentTextInputInView:_containerView];
    if (!currentTextInput) {
        return;
    }
    
    CGSize containerViewSize = _containerViewController.view.bounds.size;
    CGPoint textFieldOrigin = [currentTextInput convertPoint:CGPointZero toView:_containerViewController.view];
    CGFloat minOffsetY = textFieldOrigin.y + currentTextInput.bounds.size.height + 5;
    CGFloat keyboardHeight = [_keyboardInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    if (containerViewSize.height - keyboardHeight < minOffsetY) {
        CGFloat offetY = (_containerViewController.view.bounds.size.height - keyboardHeight) - minOffsetY;
        
        NSTimeInterval duration = [_keyboardInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationCurve curve = [_keyboardInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:curve];
        [UIView setAnimationDuration:duration];
        
        _containerView.transform = CGAffineTransformMakeTranslation(0, offetY);
        
        [UIView commitAnimations];
    }
}

- (UIView<UIKeyInput> *)getCurrentTextInputInView:(UIView *)view
{
    if ([view conformsToProtocol:@protocol(UIKeyInput)] && view.isFirstResponder) {
        return (UIView<UIKeyInput> *)view;
    }
    
    for (UIView *subview in view.subviews) {
        UIView<UIKeyInput> *view = [self getCurrentTextInputInView:subview];
        if (view) {
            return view;
        }
    }
    return nil;
}

#pragma mark - STPopupFirstResponderDidChangeNotification

- (void)firstResponderDidChange:(NSNotification *)notification
{
    // "keyboardWillShow" won't be called if height of keyboard is not changed.
    // Manually adjust container view origin according to last keyboard info.
    [self adjustContainerViewOrigin];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    toViewController.view.frame = fromViewController.view.frame;
    [containerView addSubview:toViewController.view];
    [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
}

#pragma mark - STPopupNavigationTouchEventDelegate

- (void)popupNavigationBar:(STPopupNavigationBar *)navigationBar touchDidMoveWithOffset:(CGFloat)offset
{
    [_containerView endEditing:YES];
    _containerView.transform = CGAffineTransformMakeTranslation(0, offset);
}

- (void)popupNavigationBar:(STPopupNavigationBar *)navigationBar touchDidEndWithOffset:(CGFloat)offset
{
    if (offset > 150) {
        [self dismissWithTransitionStyle:STPopupTransitionStyleSlideVertical withCompletion:nil];
    }
    else {
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _containerView.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

@end
