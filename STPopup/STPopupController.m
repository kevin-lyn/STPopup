//
//  STPopupController.m
//  STPopup
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

@interface STPopupContainerViewController : UIViewController

@end

@implementation STPopupContainerViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.childViewControllers.count || !self.presentingViewController) {
        return [super preferredStatusBarStyle];
    }
    return [self.presentingViewController preferredStatusBarStyle];
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.childViewControllers.lastObject;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.childViewControllers.lastObject;
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
    UIView *_contentView;
    UILabel *_defaultTitleLabel;
    STPopupLeftBarItem *_defaultLeftBarItem;
    NSDictionary *_keyboardInfo;
    BOOL _observing;
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
    [self destroyObservers];
    for (UIViewController *viewController in _viewControllers) { // Avoid crash when try to access unsafe unretained property
        [viewController setValue:nil forKey:@"popupController"];
        [self destroyObserversOfViewController:viewController];
    }
}

- (BOOL)presented
{
    return _containerViewController.presentingViewController != nil;
}

#pragma mark - Observers

- (void)setupObservers
{
    if (_observing) {
        return;
    }
    _observing = YES;
    
    // Observe navigation bar
    [_navigationBar addObserver:self forKeyPath:NSStringFromSelector(@selector(tintColor)) options:NSKeyValueObservingOptionNew context:nil];
    [_navigationBar addObserver:self forKeyPath:NSStringFromSelector(@selector(titleTextAttributes)) options:NSKeyValueObservingOptionNew context:nil];
    
    // Observe orientation change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    // Observe keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // Observe responder change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firstResponderDidChange) name:STPopupFirstResponderDidChangeNotification object:nil];
}

- (void)destroyObservers
{
    if (!_observing) {
        return;
    }
    _observing = NO;
    
    [_navigationBar removeObserver:self forKeyPath:NSStringFromSelector(@selector(tintColor))];
    [_navigationBar removeObserver:self forKeyPath:NSStringFromSelector(@selector(titleTextAttributes))];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupObserversForViewController:(UIViewController *)viewController
{
    [viewController.navigationItem addObserver:self forKeyPath:NSStringFromSelector(@selector(title)) options:NSKeyValueObservingOptionNew context:nil];
    [viewController.navigationItem addObserver:self forKeyPath:NSStringFromSelector(@selector(titleView)) options:NSKeyValueObservingOptionNew context:nil];
    [viewController.navigationItem addObserver:self forKeyPath:NSStringFromSelector(@selector(leftBarButtonItem)) options:NSKeyValueObservingOptionNew context:nil];
    [viewController.navigationItem addObserver:self forKeyPath:NSStringFromSelector(@selector(leftBarButtonItems)) options:NSKeyValueObservingOptionNew context:nil];
    [viewController.navigationItem addObserver:self forKeyPath:NSStringFromSelector(@selector(rightBarButtonItem)) options:NSKeyValueObservingOptionNew context:nil];
    [viewController.navigationItem addObserver:self forKeyPath:NSStringFromSelector(@selector(rightBarButtonItems)) options:NSKeyValueObservingOptionNew context:nil];
    [viewController.navigationItem addObserver:self forKeyPath:NSStringFromSelector(@selector(hidesBackButton)) options:NSKeyValueObservingOptionNew context:nil];
}

- (void)destroyObserversOfViewController:(UIViewController *)viewController
{
    [viewController.navigationItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(title))];
    [viewController.navigationItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(titleView))];
    [viewController.navigationItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(leftBarButtonItem))];
    [viewController.navigationItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(leftBarButtonItems))];
    [viewController.navigationItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(rightBarButtonItem))];
    [viewController.navigationItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(rightBarButtonItems))];
    [viewController.navigationItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(hidesBackButton))];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _navigationBar || object == [self topViewController].navigationItem) {
        [self updateNavigationBarAniamted:NO];
    }
}

#pragma mark - STPopupController present & dismiss & push & pop

- (void)presentInViewController:(UIViewController *)viewController
{
    [self presentInViewController:viewController completion:nil];
}

- (void)presentInViewController:(UIViewController *)viewController completion:(void (^)(void))completion
{
    if (self.presented) {
        return;
    }
    
    [self setupObservers];
    
    [_retainedPopupControllers addObject:self];
    [viewController presentViewController:_containerViewController animated:YES completion:completion];
}

- (void)dismiss
{
    [self dismissWithCompletion:nil];
}

- (void)dismissWithCompletion:(void (^)(void))completion
{
    if (!self.presented) {
        return;
    }
    
    [self destroyObservers];
    
    [_containerViewController dismissViewControllerAnimated:YES completion:^{
        [_retainedPopupControllers removeObject:self];
        if (completion) {
            completion();
        }
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
    
    if (self.presented) {
        [self transitFromViewController:topViewController toViewController:viewController animated:animated];
    }
    [self setupObserversForViewController:viewController];
}

- (void)popViewControllerAnimated:(BOOL)animated
{
    if (_viewControllers.count <= 1) {
        [self dismiss];
        return;
    }
    
    UIViewController *topViewController = [self topViewController];
    [topViewController setValue:nil forKey:@"popupController"];
    [self destroyObserversOfViewController:topViewController];
    [_viewControllers removeObject:topViewController];
    
    if (self.presented) {
        [self transitFromViewController:topViewController toViewController:[self topViewController] animated:animated];
    }
}

- (void)transitFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController animated:(BOOL)animated
{
    [fromViewController beginAppearanceTransition:NO animated:animated];
    [toViewController beginAppearanceTransition:YES animated:animated];
    
    [fromViewController willMoveToParentViewController:nil];
    [_containerViewController addChildViewController:toViewController];
    
    if (animated) {
        // Capture view in "fromViewController" to avoid "viewWillAppear" and "viewDidAppear" being called.
        UIGraphicsBeginImageContextWithOptions(fromViewController.view.bounds.size, NO, [UIScreen mainScreen].scale);
        [fromViewController.view drawViewHierarchyInRect:fromViewController.view.bounds afterScreenUpdates:NO];

        UIImageView *capturedView = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
        
        UIGraphicsEndImageContext();
        
        capturedView.frame = CGRectMake(_contentView.frame.origin.x, _contentView.frame.origin.y, fromViewController.view.bounds.size.width, fromViewController.view.bounds.size.height);
        [_containerView insertSubview:capturedView atIndex:0];
        
        [fromViewController.view removeFromSuperview];
        
        _containerView.userInteractionEnabled = NO;
        toViewController.view.alpha = 0;
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self layoutContainerView];
            [_contentView addSubview:toViewController.view];
            capturedView.alpha = 0;
            toViewController.view.alpha = 1;
            [_containerViewController setNeedsStatusBarAppearanceUpdate];
        } completion:^(BOOL finished) {
            [capturedView removeFromSuperview];
            [fromViewController removeFromParentViewController];
            
            _containerView.userInteractionEnabled = YES;
            [toViewController didMoveToParentViewController:_containerViewController];
            
            [fromViewController endAppearanceTransition];
            [toViewController endAppearanceTransition];
        }];
        [self updateNavigationBarAniamted:animated];
    }
    else {
        [self layoutContainerView];
        [_contentView addSubview:toViewController.view];
        [_containerViewController setNeedsStatusBarAppearanceUpdate];
        [self updateNavigationBarAniamted:animated];
        
        [fromViewController.view removeFromSuperview];
        [fromViewController removeFromParentViewController];
        
        [toViewController didMoveToParentViewController:_containerViewController];
        
        [fromViewController endAppearanceTransition];
        [toViewController endAppearanceTransition];
    }
}

- (void)updateNavigationBarAniamted:(BOOL)animated
{
    UIViewController *topViewController = [self topViewController];
    UIView *lastTitleView = _navigationBar.topItem.titleView;
    _navigationBar.items = @[ [UINavigationItem new] ];
    _navigationBar.topItem.leftBarButtonItems = topViewController.navigationItem.leftBarButtonItems ? : (topViewController.navigationItem.hidesBackButton ? nil : @[ _defaultLeftBarItem ]);
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

- (void)setNavigationBarHidden:(BOOL)navigationBarHidden
{
    [self setNavigationBarHidden:navigationBarHidden animated:NO];
}

- (void)setNavigationBarHidden:(BOOL)navigationBarHidden animated:(BOOL)animated
{
    _navigationBarHidden = navigationBarHidden;
    _navigationBar.alpha = navigationBarHidden ? 1 : 0;
    
    if (!animated) {
        [self layoutContainerView];
        _navigationBar.hidden = navigationBarHidden;
        return;
    }
    
    if (!navigationBarHidden) {
        _navigationBar.hidden = navigationBarHidden;
    }
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _navigationBar.alpha = navigationBarHidden ? 0 : 1;
        [self layoutContainerView];
    } completion:^(BOOL finished) {
        _navigationBar.hidden = navigationBarHidden;
    }];
}

- (UIViewController *)topViewController
{
    return _viewControllers.lastObject;
}

#pragma mark - UI layout

- (void)layoutContainerView
{
    _bgView.frame = _containerViewController.view.bounds;
 
    CGFloat preferredNavigationBarHeight = [self preferredNavigationBarHeight];
    CGFloat navigationBarHeight = _navigationBarHidden ? 0 : preferredNavigationBarHeight;
    CGSize contentSizeOfTopView = [self contentSizeOfTopView];
    CGSize containerViewSize = CGSizeMake(contentSizeOfTopView.width, contentSizeOfTopView.height + navigationBarHeight);
    
    _containerView.frame = CGRectMake((_containerViewController.view.bounds.size.width - containerViewSize.width) / 2,
                                      (_containerViewController.view.bounds.size.height - containerViewSize.height) / 2,
                                      containerViewSize.width, containerViewSize.height);
    _navigationBar.frame = CGRectMake(0, 0, containerViewSize.width, preferredNavigationBarHeight);
    _contentView.frame = CGRectMake(0, navigationBarHeight, contentSizeOfTopView.width, contentSizeOfTopView.height);
    
    UIViewController *topViewController = [self topViewController];
    topViewController.view.frame = _contentView.bounds;
}

- (CGSize)contentSizeOfTopView
{
    UIViewController *topViewController = [self topViewController];
    CGSize contentSize = CGSizeZero;
    switch ([UIApplication sharedApplication].statusBarOrientation) {
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
    
    NSAssert(!CGSizeEqualToSize(contentSize, CGSizeZero), @"contentSizeInPopup should not be size zero.");
    
    return contentSize;
}

- (CGFloat)preferredNavigationBarHeight
{
    // The preferred height of navigation bar is different between iPhone (4, 5, 6) and 6 Plus.
    // Create a navigation controller to get the preferred height of navigation bar.
    UINavigationController *navigationController = [UINavigationController new];
    return navigationController.navigationBar.bounds.size.height;
}

#pragma mark - UI setup

- (void)setup
{
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
    
    _contentView = [UIView new];
    [_containerView addSubview:_contentView];
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
            [self dismiss];
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

- (void)orientationDidChange
{
    [_containerView endEditing:YES];
    [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _containerView.alpha = 0;
    } completion:^(BOOL finished) {
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
    
    CGAffineTransform lastTransform = _containerView.transform;
    _containerView.transform = CGAffineTransformIdentity; // Set transform to identity for calculating a correct "minOffsetY"
    
    CGFloat textFieldBottomY = [currentTextInput convertPoint:CGPointZero toView:_containerViewController.view].y + currentTextInput.bounds.size.height;
    CGFloat keyboardHeight = [_keyboardInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    // For iOS 7
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1 &&
        (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
        keyboardHeight = [_keyboardInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.width;
    }
    
    CGFloat spacing = 5;
    CGFloat offsetY = _containerView.frame.origin.y + _containerView.bounds.size.height - (_containerViewController.view.bounds.size.height - keyboardHeight - spacing);
    if (offsetY <= 0) { // _containerView can be totally shown, so no need to reposition
        return;
    }
    
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    
    if (_containerView.frame.origin.y - offsetY < statusBarHeight) { // _containerView will be covered by status bar if it is repositioned with "offsetY"
        offsetY = _containerView.frame.origin.y - statusBarHeight;
        // currentTextField can not be totally shown if _containerView is going to repositioned with "offsetY"
        if (textFieldBottomY - offsetY > _containerViewController.view.bounds.size.height - keyboardHeight - spacing) {
            offsetY = textFieldBottomY - (_containerViewController.view.bounds.size.height - keyboardHeight - spacing);
        }
    }
    
    NSTimeInterval duration = [_keyboardInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [_keyboardInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    _containerView.transform = lastTransform; // Restore transform
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationDuration:duration];
    
    _containerView.transform = CGAffineTransformMakeTranslation(0, -offsetY);
    
    [UIView commitAnimations];
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

- (void)firstResponderDidChange
{
    // "keyboardWillShow" won't be called if height of keyboard is not changed
    // Manually adjust container view origin according to last keyboard info
    [self adjustContainerViewOrigin];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if (toViewController == _containerViewController) {
        return 0.5;
    }
    else {
        return self.transitionStyle == STPopupTransitionStyleFade ? 0.4 : 0.7;
    }
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    toViewController.view.frame = fromViewController.view.frame;
    
    UIViewController *topViewController = [self topViewController];
    
    if (toViewController == _containerViewController) {
        [fromViewController beginAppearanceTransition:NO animated:YES];
        
        [[transitionContext containerView] addSubview:toViewController.view];
        
        [topViewController beginAppearanceTransition:YES animated:YES];
        [toViewController addChildViewController:topViewController];
        
        [self layoutContainerView];
        [_contentView addSubview:topViewController.view];
        [toViewController setNeedsStatusBarAppearanceUpdate];
        [self updateNavigationBarAniamted:NO];
        
        switch (self.transitionStyle) {
            case STPopupTransitionStyleFade: {
                _containerView.alpha = 0;
                _containerView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            }
                break;
            case STPopupTransitionStyleSlideVertical:
            default: {
                _containerView.alpha = 1;
                _containerView.transform = CGAffineTransformMakeTranslation(0, _containerViewController.view.bounds.size.height + _containerView.bounds.size.height);
            }
                break;
        }
        _bgView.alpha = 0;
        
        _containerView.userInteractionEnabled = NO;
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _bgView.alpha = 1;
            _containerView.alpha = 1;
            _containerView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            _containerView.userInteractionEnabled = YES;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            
            [topViewController didMoveToParentViewController:toViewController];
            
            [fromViewController endAppearanceTransition];
        }];
    }
    else {
        [toViewController beginAppearanceTransition:YES animated:YES];
        
        [topViewController beginAppearanceTransition:NO animated:YES];
        [topViewController willMoveToParentViewController:nil];
        
        _containerView.userInteractionEnabled = NO;
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _bgView.alpha = 0;
            switch (self.transitionStyle) {
                case STPopupTransitionStyleFade: {
                    _containerView.alpha = 0;
                    _containerView.transform = CGAffineTransformMakeScale(0.9, 0.9);
                }
                    break;
                case STPopupTransitionStyleSlideVertical:
                default: {
                    _containerView.transform = CGAffineTransformMakeTranslation(0, _containerViewController.view.bounds.size.height + _containerView.bounds.size.height);
                }
                    break;
            }
        } completion:^(BOOL finished) {
            _containerView.userInteractionEnabled = YES;
            _containerView.transform = CGAffineTransformIdentity;
            [fromViewController.view removeFromSuperview];
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            
            [topViewController.view removeFromSuperview];
            [topViewController removeFromParentViewController];
    
            [toViewController endAppearanceTransition];
        }];
    }
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
        STPopupTransitionStyle transitionStyle = self.transitionStyle;
        self.transitionStyle = STPopupTransitionStyleSlideVertical;
        [self dismissWithCompletion:^{
            self.transitionStyle = transitionStyle;
        }];
    }
    else {
        [_containerView endEditing:YES];
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _containerView.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

@end
