//
//  STPopupController.m
//  Sth4Me
//
//  Created by Kevin Lin on 11/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "STPopupController.h"
#import "STPopupLeftBarItem.h"

static STPopupController *_currentPopupController;
CGFloat const STPopupTitleHeight = 44;

@interface STPopupController () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@end

@implementation STPopupController
{
    UIViewController *_containerViewController;
    NSMutableArray *_viewControllers; // <STPopupViewController>
    UIView *_bgView;
    UIView *_containerView;
    UILabel *_defaultTitleLabel;
    STPopupLeftBarItem *_defaultLeftBarItem;
    UIInterfaceOrientation _orientation;
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
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _navigationBar) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(tintColor))]) {
            _defaultLeftBarItem.tintColor = change[@"new"];
        }
        else if ([keyPath isEqualToString:NSStringFromSelector(@selector(titleTextAttributes))]) {
            _defaultTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:_defaultTitleLabel.text attributes:change[@"new"]];
        }
    }
}

- (void)presentInViewController:(UIViewController *)viewController
{
    _currentPopupController = self;
    
    _bgView.alpha = 0;
    _containerView.alpha = 0; // Hide _containerView before _containerViewController is ready
    
    [viewController presentViewController:_containerViewController animated:YES completion:^{
        [self layoutTopView];
        [self layoutContainerView];
        
        switch (self.transitionStyle) {
            case STPopupTransitionStyleFade: {
                _containerView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            }
                break;
            case STPopupTransitionStylePopVertical:
            default: {
                _containerView.alpha = 1;
                _containerView.transform = CGAffineTransformMakeTranslation(0, _containerViewController.view.bounds.size.height + _containerView.frame.size.height);
            }
                break;
        }
        
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _containerView.alpha = 1;
            _bgView.alpha = 1;
            _containerView.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}

- (void)dismiss
{
    _containerView.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _bgView.alpha = 0;
        switch (self.transitionStyle) {
            case STPopupTransitionStyleFade: {
                _containerView.alpha = 0;
                _containerView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            }
                break;
            case STPopupTransitionStylePopVertical:
            default: {
                _containerView.transform = CGAffineTransformMakeTranslation(0, _containerViewController.view.bounds.size.height + _containerView.frame.size.height);
            }
                break;
        }
    } completion:^(BOOL finished) {
        _containerView.alpha = 0;
        _containerView.transform = CGAffineTransformIdentity;
        _containerView.userInteractionEnabled = YES;
        _currentPopupController = nil;
        [_containerViewController dismissViewControllerAnimated:NO completion:nil];
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
    
    [self transitFromViewController:topViewController toViewController:viewController animated:animated];
}

- (void)popViewControllerAnimated:(BOOL)animated
{
    if (_viewControllers.count <= 1) {
        [self dismiss];
        return;
    }
    
    UIViewController *topViewController = [self topViewController];
    [topViewController setValue:nil forKey:@"popupController"];
    [_viewControllers removeObject:topViewController];
    
    [self transitFromViewController:topViewController toViewController:[self topViewController] animated:animated];
}

- (void)transitFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController animated:(BOOL)animated
{
    [fromViewController viewWillDisappear:animated];
    
    [self layoutTopView];
    [_containerView insertSubview:toViewController.view atIndex:0];
    [toViewController viewWillAppear:animated];
    
    [self updateTitleViewAnimated:animated];
    
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
            [fromViewController viewDidDisappear:animated];
            [toViewController viewDidAppear:animated];
            _containerView.userInteractionEnabled = YES;
        }];
    }
    else {
        [self layoutContainerView];
        
        [fromViewController.view removeFromSuperview];
        [fromViewController viewDidDisappear:animated];
        
        [toViewController viewDidDisappear:animated];
    }
}

- (void)updateTitleViewAnimated:(BOOL)animated
{
    UIViewController *topViewController = [self topViewController];
    UIView *lastTitleView = _navigationBar.topItem.titleView;
    _navigationBar.items = @[ [UINavigationItem new] ];
    _navigationBar.topItem.leftBarButtonItem = topViewController.navigationItem.leftBarButtonItem ? : _defaultLeftBarItem;
    _navigationBar.topItem.rightBarButtonItem = topViewController.navigationItem.rightBarButtonItem;
    
    if (animated) {
        UIView *fromTitleView, *toTitleView;
        if (lastTitleView == _defaultTitleLabel)    {
            UILabel *tempLabel = [[UILabel alloc] initWithFrame:_defaultTitleLabel.frame];
            tempLabel.textColor = _defaultTitleLabel.textColor;
            tempLabel.font = _defaultTitleLabel.font;
            tempLabel.attributedText = [[NSAttributedString alloc] initWithString:_defaultTitleLabel.text attributes:_navigationBar.titleTextAttributes];
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
            _defaultTitleLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1];
            _defaultTitleLabel.font = [UIFont systemFontOfSize:17];
            _defaultTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:topViewController.title attributes:_navigationBar.titleTextAttributes];
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
            _defaultTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:topViewController.title attributes:_navigationBar.titleTextAttributes];
            [_defaultTitleLabel sizeToFit];
            _navigationBar.topItem.titleView = _defaultTitleLabel;
        }
    }
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
        default:
            contentSize = topViewController.contentSizeInPopup;
            break;
    }
    return contentSize;
}

#pragma mark - UI setup

- (void)setup
{
    _orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    _containerViewController = [UIViewController new];
    _containerViewController.view.backgroundColor = [UIColor clearColor];
    _containerViewController.modalPresentationStyle = UIModalPresentationCustom;
    _containerViewController.transitioningDelegate = self;
    [self setupBackgroundView];
    [self setupContainerView];
    [self setupTitleView];
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

- (void)setupTitleView
{
    _navigationBar = [UINavigationBar new];
    [_containerView addSubview:_navigationBar];
    
    _defaultTitleLabel = [UILabel new];
    _defaultTitleLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1];
    _defaultTitleLabel.font = [UIFont systemFontOfSize:17];
    
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
    UIView<UITextInputTraits> *currentTextInput = [self getCurrentTextInputInView:_containerView];
    if (!currentTextInput) {
        return;
    }
    
    CGSize containerViewSize = _containerViewController.view.bounds.size;
    CGPoint textFieldOrigin = [currentTextInput convertPoint:CGPointZero toView:_containerViewController.view];
    CGSize keyboardSize = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat minOffsetY = textFieldOrigin.y + currentTextInput.bounds.size.height + 5;
    if (containerViewSize.height - keyboardSize.height < minOffsetY) {
        CGFloat offetY = (_containerViewController.view.bounds.size.height - keyboardSize.height) - minOffsetY;
        
        NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:curve];
        [UIView setAnimationDuration:duration];
        
        _containerView.transform = CGAffineTransformMakeTranslation(0, offetY);
        
        [UIView commitAnimations];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationDuration:duration];
    
    _containerView.transform = CGAffineTransformIdentity;
    
    [UIView commitAnimations];
}

- (UIView<UITextInputTraits> *)getCurrentTextInputInView:(UIView *)view
{
    if ([view conformsToProtocol:@protocol(UITextInputTraits)] && view.isFirstResponder) {
        return (UIView<UITextInputTraits> *)view;
    }
    
    for (UIView *subview in view.subviews) {
        UIView<UITextInputTraits> *view = [self getCurrentTextInputInView:subview];
        if (view) {
            return view;
        }
    }
    return nil;
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

@end
