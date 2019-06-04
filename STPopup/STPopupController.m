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
#import "STPopupControllerTransitioningSlideVertical.h"
#import "STPopupControllerTransitioningFade.h"

@implementation STPopupControllerTransitioningContext

- (instancetype)initWithContainerView:(UIView *)containerView action:(STPopupControllerTransitioningAction)action
{
    if (self = [super init]) {
        _containerView = containerView;
        _action = action;
    }
    return self;
}

@end

CGFloat const STPopupBottomSheetExtraHeight = 80;

static NSMutableSet *_retainedPopupControllers;

@protocol STPopupNavigationTouchEventDelegate <NSObject>

- (void)popupNavigationBar:(STPopupNavigationBar *)navigationBar touchDidMoveWithOffset:(CGFloat)offset;
- (void)popupNavigationBar:(STPopupNavigationBar *)navigationBar touchDidEndWithOffset:(CGFloat)offset;

@end

@interface STPopupNavigationBar (STInternal)

@property (nonatomic, weak) id<STPopupNavigationTouchEventDelegate> touchEventDelegate;

@end

@interface UIViewController (STInternal)

@property (nonatomic, weak) STPopupController *popupController;

@end

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

- (void)showViewController:(UIViewController *)vc sender:(id)sender
{
    if (!CGSizeEqualToSize(vc.contentSizeInPopup, CGSizeZero) ||
        !CGSizeEqualToSize(vc.landscapeContentSizeInPopup, CGSizeZero)) {
        UIViewController *childViewController = self.childViewControllers.lastObject;
        [childViewController.popupController pushViewController:vc animated:YES];
    }
    else {
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (void)showDetailViewController:(UIViewController *)vc sender:(id)sender
{
    if (!CGSizeEqualToSize(vc.contentSizeInPopup, CGSizeZero) ||
        !CGSizeEqualToSize(vc.landscapeContentSizeInPopup, CGSizeZero)) {
        UIViewController *childViewController = self.childViewControllers.lastObject;
        [childViewController.popupController pushViewController:vc animated:YES];
    }
    else {
        [self presentViewController:vc animated:YES completion:nil];
    }
}

@end

@interface STPopupController () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, STPopupNavigationTouchEventDelegate>

@end

@implementation STPopupController
{
    STPopupContainerViewController *_containerViewController;
    NSMutableArray *_viewControllers; // <UIViewController>
    UIView *_contentView;
    UILabel *_defaultTitleLabel;
    STPopupLeftBarItem *_defaultLeftBarItem;
    NSDictionary *_keyboardInfo;
    BOOL _didOverrideSafeAreaInsets;
    BOOL _observing;
    
    // Built-in transitioning
    STPopupControllerTransitioningSlideVertical *_transitioningSlideVertical;
    STPopupControllerTransitioningFade *_transitioningFade;
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
    for (UIViewController *viewController in _viewControllers) {
        viewController.popupController = nil; // Avoid crash when try to access unsafe unretained property
        [self destroyObserversOfViewController:viewController];
    }
}

- (UIViewController *)topViewController
{
  return _viewControllers.lastObject;
}

- (BOOL)presented
{
    return _containerViewController.presentingViewController != nil;
}

- (void)setBackgroundView:(UIView *)backgroundView
{
    [_backgroundView removeFromSuperview];
    _backgroundView = backgroundView;
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgViewDidTap)]];
    [_containerViewController.view insertSubview:_backgroundView atIndex:0];
}

- (void)setHidesCloseButton:(BOOL)hidesCloseButton
{
    _hidesCloseButton = hidesCloseButton;
    [self updateNavigationBarAnimated:NO];
}

- (void)setSafeAreaInsets:(UIEdgeInsets)safeAreaInsets
{
    _safeAreaInsets = safeAreaInsets;
    _didOverrideSafeAreaInsets = YES;
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
    [viewController addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSizeInPopup)) options:NSKeyValueObservingOptionNew context:nil];
    [viewController addObserver:self forKeyPath:NSStringFromSelector(@selector(landscapeContentSizeInPopup)) options:NSKeyValueObservingOptionNew context:nil];
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
    [viewController removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSizeInPopup))];
    [viewController removeObserver:self forKeyPath:NSStringFromSelector(@selector(landscapeContentSizeInPopup))];
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
    UIViewController *topViewController = self.topViewController;
    if (object == _navigationBar || object == topViewController.navigationItem) {
        if (topViewController.isViewLoaded && topViewController.view.superview) {
            [self updateNavigationBarAnimated:NO];
        }
    }
    else if (object == topViewController) {
        if (topViewController.isViewLoaded && topViewController.view.superview) {
            [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [self layoutContainerView];
            } completion:^(BOOL finished) {
                [self adjustContainerViewOrigin];
            }];
        }
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
    
    viewController = viewController.tabBarController ? : viewController;
    if (@available(iOS 11.0, *)) {
        if (!_didOverrideSafeAreaInsets) {
            _safeAreaInsets = viewController.view.window.safeAreaInsets;
        }
    }
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
    
    UIViewController *topViewController = self.topViewController;
    viewController.popupController = self;
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
    
    UIViewController *topViewController = self.topViewController;
    [self destroyObserversOfViewController:topViewController];
    [_viewControllers removeObject:topViewController];
    
    if (self.presented) {
        [self transitFromViewController:topViewController toViewController:self.topViewController animated:animated];
    }
    
    topViewController.popupController = nil;
}


- (void)popToRootViewControllerAnimated:(BOOL)animated
{
    if (_viewControllers.count <= 1) {
        return;
    }
    
    UIViewController *firstViewController = _viewControllers.firstObject;
    UIViewController *lastViewController = _viewControllers.lastObject;
    for (int i = 1; i < _viewControllers.count; i++) {
        [self destroyObserversOfViewController:_viewControllers[i]];
    }
    _viewControllers = [NSMutableArray arrayWithObject:firstViewController];
    
    if (self.presented) {
        [self transitFromViewController:lastViewController toViewController:firstViewController animated:animated];
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
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self layoutContainerView];
            [self->_contentView addSubview:toViewController.view];
            capturedView.alpha = 0;
            toViewController.view.alpha = 1;
            [self->_containerViewController setNeedsStatusBarAppearanceUpdate];
        } completion:^(BOOL finished) {
            [capturedView removeFromSuperview];
            [fromViewController removeFromParentViewController];
            
            self->_containerView.userInteractionEnabled = YES;
            [toViewController didMoveToParentViewController:self->_containerViewController];
            
            [fromViewController endAppearanceTransition];
            [toViewController endAppearanceTransition];
        }];
        [self updateNavigationBarAnimated:animated];
    }
    else {
        [self layoutContainerView];
        [_contentView addSubview:toViewController.view];
        [_containerViewController setNeedsStatusBarAppearanceUpdate];
        [self updateNavigationBarAnimated:animated];
        
        [fromViewController.view removeFromSuperview];
        [fromViewController removeFromParentViewController];
        
        [toViewController didMoveToParentViewController:_containerViewController];
        
        [fromViewController endAppearanceTransition];
        [toViewController endAppearanceTransition];
    }
}

- (void)updateNavigationBarAnimated:(BOOL)animated
{
    BOOL shouldAnimateDefaultLeftBarItem = animated && _navigationBar.topItem.leftBarButtonItem == _defaultLeftBarItem;
    
    UIViewController *topViewController = self.topViewController;
    UIView *lastTitleView = _navigationBar.topItem.titleView;
    _navigationBar.items = @[ [UINavigationItem new] ];
    _navigationBar.topItem.leftBarButtonItems = topViewController.navigationItem.leftBarButtonItems ? : (topViewController.navigationItem.hidesBackButton ? nil : @[ _defaultLeftBarItem ]);
    _navigationBar.topItem.rightBarButtonItems = topViewController.navigationItem.rightBarButtonItems;
    if (self.hidesCloseButton && topViewController == _viewControllers.firstObject &&
        _navigationBar.topItem.leftBarButtonItem == _defaultLeftBarItem) {
        _navigationBar.topItem.leftBarButtonItems = nil;
    }
    
    if (animated) {
        UIView *fromTitleView, *toTitleView;
        if (lastTitleView == _defaultTitleLabel)    {
            UILabel *tempLabel = [[UILabel alloc] initWithFrame:_defaultTitleLabel.frame];
            tempLabel.center = _navigationBar.center;
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
            NSString *title = (topViewController.title ? : topViewController.navigationItem.title) ? : @"";
            _defaultTitleLabel = [UILabel new];
            _defaultTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:title
                                                                                attributes:_navigationBar.titleTextAttributes];
            [_defaultTitleLabel sizeToFit];
            toTitleView = _defaultTitleLabel;
        }
        
        fromTitleView.center = _navigationBar.center;
        [_navigationBar addSubview:fromTitleView];
        _navigationBar.topItem.titleView = toTitleView;
        toTitleView.alpha = 0;
        
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
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
            NSString *title = (topViewController.title ? : topViewController.navigationItem.title) ? : @"";
            _defaultTitleLabel = [UILabel new];
            _defaultTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:title
                                                                                attributes:_navigationBar.titleTextAttributes];
            [_defaultTitleLabel sizeToFit];
            _navigationBar.topItem.titleView = _defaultTitleLabel;
        }
    }
    _defaultLeftBarItem.tintColor = _navigationBar.tintColor;
    [_defaultLeftBarItem setType:_viewControllers.count > 1 ? STPopupLeftBarItemArrow : STPopupLeftBarItemCross
                        animated:shouldAnimateDefaultLeftBarItem];
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
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self->_navigationBar.alpha = navigationBarHidden ? 0 : 1;
        [self layoutContainerView];
    } completion:^(BOOL finished) {
        self->_navigationBar.hidden = navigationBarHidden;
    }];
}

#pragma mark - UI layout

- (void)layoutContainerView
{
    CGAffineTransform lastTransform = _containerView.transform;
    _containerView.transform = CGAffineTransformIdentity;
    
    _backgroundView.frame = _containerViewController.view.bounds;
 
    CGFloat preferredNavigationBarHeight = [self preferredNavigationBarHeight];
    CGFloat navigationBarHeight = _navigationBarHidden ? 0 : preferredNavigationBarHeight;
    CGSize contentSizeOfTopView = [self contentSizeOfTopView];
    CGFloat containerViewWidth = contentSizeOfTopView.width;
    CGFloat containerViewHeight = contentSizeOfTopView.height + navigationBarHeight;
    CGFloat containerViewY = (_containerViewController.view.bounds.size.height - containerViewHeight) / 2;
    
    if (self.style == STPopupStyleBottomSheet) {
        containerViewHeight += _safeAreaInsets.bottom;
        containerViewY = _containerViewController.view.bounds.size.height - containerViewHeight;
        containerViewHeight += STPopupBottomSheetExtraHeight;
    }
    
    _containerView.frame = CGRectMake((_containerViewController.view.bounds.size.width - containerViewWidth) / 2,
                                      containerViewY, containerViewWidth, containerViewHeight);
    _navigationBar.frame = CGRectMake(0, 0, containerViewWidth, preferredNavigationBarHeight);
    _contentView.frame = CGRectMake(0, navigationBarHeight, contentSizeOfTopView.width, contentSizeOfTopView.height);
    
    UIViewController *topViewController = self.topViewController;
    topViewController.view.frame = _contentView.bounds;
    
    _containerView.transform = lastTransform;
}

- (CGSize)contentSizeOfTopView
{
    UIViewController *topViewController = self.topViewController;
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
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending) {
        _containerViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    else {
        _containerViewController.modalPresentationStyle = UIModalPresentationCustom;
    }
    _containerViewController.transitioningDelegate = self;
    [self setupBackgroundView];
    [self setupContainerView];
    [self setupNavigationBar];
    
    _transitioningSlideVertical = [STPopupControllerTransitioningSlideVertical new];
    _transitioningFade = [STPopupControllerTransitioningFade new];
}

- (void)setupBackgroundView
{
    UIView *backgroundView = [UIView new];
    backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.backgroundView = backgroundView;
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
    [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self->_containerView.alpha = 0;
    } completion:^(BOOL finished) {
        [self layoutContainerView];
        [self updateNavigationBarAnimated:NO];
        [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self->_containerView.alpha = 1;
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
    
    CGFloat offsetY = 0;
    if (self.style == STPopupStyleBottomSheet) {
        offsetY = keyboardHeight - _safeAreaInsets.bottom;
    }
    else {
        CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        if (_containerView.bounds.size.height <= _containerViewController.view.bounds.size.height - keyboardHeight - statusBarHeight) {
            offsetY = _containerView.frame.origin.y - (statusBarHeight + (_containerViewController.view.bounds.size.height - keyboardHeight - statusBarHeight - _containerView.bounds.size.height) / 2);
        }
        else {
            CGFloat spacing = 5;
            offsetY = _containerView.frame.origin.y + _containerView.bounds.size.height - (_containerViewController.view.bounds.size.height - keyboardHeight - spacing);
            if (offsetY <= 0) { // _containerView can be totally shown, so no need to translate the origin
                return;
            }
            if (_containerView.frame.origin.y - offsetY < statusBarHeight) { // _containerView will be covered by status bar if the origin is translated by "offsetY"
                offsetY = _containerView.frame.origin.y - statusBarHeight;
                // currentTextField can not be totally shown if _containerView is going to repositioned with "offsetY"
                if (textFieldBottomY - offsetY > _containerViewController.view.bounds.size.height - keyboardHeight - spacing) {
                    offsetY = textFieldBottomY - (_containerViewController.view.bounds.size.height - keyboardHeight - spacing);
                }
            }
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
        // Quick fix for web view issue
        if ([view isKindOfClass:NSClassFromString(@"UIWebBrowserView")] || [view isKindOfClass:NSClassFromString(@"WKContentView")]) {
            return nil;
        }
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

- (STPopupControllerTransitioningContext *)convertTransitioningContext:(id <UIViewControllerContextTransitioning>)transitionContext
{
    STPopupControllerTransitioningAction action = STPopupControllerTransitioningActionPresent;
    if ([transitionContext viewControllerForKey:UITransitionContextToViewControllerKey] != _containerViewController) {
        action = STPopupControllerTransitioningActionDismiss;
    }
    return [[STPopupControllerTransitioningContext alloc] initWithContainerView:_containerView action:action];
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    STPopupControllerTransitioningContext *context = [self convertTransitioningContext:transitionContext];
    switch (self.transitionStyle) {
        case STPopupTransitionStyleSlideVertical:
            return [_transitioningSlideVertical popupControllerTransitionDuration:context];
        case STPopupTransitionStyleFade:
            return [_transitioningFade popupControllerTransitionDuration:context];
        case STPopupTransitionStyleCustom:
            NSAssert(self.transitioning, @"transitioning should be provided if it's using STPopupTransitionStyleCustom");
            return [_transitioning popupControllerTransitionDuration:context];
    }
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    toViewController.view.frame = fromViewController.view.frame;
    
    UIViewController *topViewController = self.topViewController;
    
    STPopupControllerTransitioningContext *context = [self convertTransitioningContext:transitionContext];
    id<STPopupControllerTransitioning> transitioning = nil;
    switch (self.transitionStyle) {
        case STPopupTransitionStyleSlideVertical:
            transitioning = _transitioningSlideVertical;
            break;
        case STPopupTransitionStyleFade:
            transitioning = _transitioningFade;
            break;
        case STPopupTransitionStyleCustom:
            transitioning = self.transitioning;
            break;
    }
    NSAssert(transitioning, @"transitioning should be provided if it's using STPopupTransitionStyleCustom");
    
    if (context.action == STPopupControllerTransitioningActionPresent) {
        [fromViewController beginAppearanceTransition:NO animated:YES];
        
        [[transitionContext containerView] addSubview:toViewController.view];
        
        [topViewController beginAppearanceTransition:YES animated:YES];
        [toViewController addChildViewController:topViewController];
        
        [self layoutContainerView];
        [_contentView addSubview:topViewController.view];
        [toViewController setNeedsStatusBarAppearanceUpdate];
        [self updateNavigationBarAnimated:NO];
        
        CGFloat lastBackgroundViewAlpha = _backgroundView.alpha;
        _backgroundView.alpha = 0;
        _backgroundView.userInteractionEnabled = NO;
        _containerView.userInteractionEnabled = NO;
        _containerView.transform = CGAffineTransformIdentity;
        
        [UIView animateWithDuration:[transitioning popupControllerTransitionDuration:context] delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self->_backgroundView.alpha = lastBackgroundViewAlpha;
        } completion:nil];
        
        [transitioning popupControllerAnimateTransition:context completion:^{
            self->_backgroundView.userInteractionEnabled = YES;
            self->_containerView.userInteractionEnabled = YES;
            
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            [topViewController didMoveToParentViewController:toViewController];
            [fromViewController endAppearanceTransition];
        }];
    }
    else {
        [toViewController beginAppearanceTransition:YES animated:YES];
        
        [topViewController beginAppearanceTransition:NO animated:YES];
        [topViewController willMoveToParentViewController:nil];
        
        CGFloat lastBackgroundViewAlpha = _backgroundView.alpha;
        _backgroundView.userInteractionEnabled = NO;
        _containerView.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:[transitioning popupControllerTransitionDuration:context] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self->_backgroundView.alpha = 0;
        } completion:nil];
        
        [transitioning popupControllerAnimateTransition:context completion:^{
            self->_backgroundView.userInteractionEnabled = YES;
            self->_containerView.userInteractionEnabled = YES;;
            
            [fromViewController.view removeFromSuperview];
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            
            [topViewController.view removeFromSuperview];
            [topViewController removeFromParentViewController];
            
            [toViewController endAppearanceTransition];
            
            self->_backgroundView.alpha = lastBackgroundViewAlpha;
        }];
    }
}

#pragma mark - STPopupNavigationTouchEventDelegate

- (void)popupNavigationBar:(STPopupNavigationBar *)navigationBar touchDidMoveWithOffset:(CGFloat)offset
{
    [_containerView endEditing:YES];
    
    if (self.style == STPopupStyleBottomSheet && offset < -STPopupBottomSheetExtraHeight) {
        return;
    }
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
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self->_containerView.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

@end
