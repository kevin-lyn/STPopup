# STPopup ![CI Status](https://img.shields.io/travis/kevin0571/STPopup.svg?style=flat) ![Version](http://img.shields.io/cocoapods/v/STPopup.svg?style=flag) ![License](https://img.shields.io/cocoapods/l/STPopup.svg?style=flag)
STPopup provides STPopupController, which works just like UINavigationController in popup style, for both iPhone and iPad.

**Features:**
- Extend your view controller from UIViewController, build it in your familiar way.
- Push/Pop view controller in to/out of popup view stack, and set navigation items by using self.navigationItem.leftBarButtonItem and rightBarButtonItem, just like you are using UINavigationController.
- Support both "Form Sheet" and "Bottom Sheet" style.
- Work well with storyboard(including segue).
- Customize UI by using UIAppearance.
- Fully customizable popup transition style.
- Auto-reposition of popup view when keyboard is showing up, make sure your UITextField/UITextView won't be covered by the keyboard.
- Drag navigation bar to dismiss popup view.
- Support both portrait and landscape orientation, and both iPhone and iPad.

## Overview
**Used in Sth4Me app**  
![Sth4Me](https://cloud.githubusercontent.com/assets/1491282/9857827/8fa0125e-5b4f-11e5-9c0d-ff955c007360.gif)

## Get Started
**CocoaPods**
```ruby
platform :ios, '7.0'
pod 'STPopup'
```
**Carthage**
```ruby
github "kevin0571/STPopup"
```
**Import header file**
```objc
#import <STPopup/STPopup.h>
```

**Initialize STPopupController**
```objc
STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[ViewController new]];
[popupController presentInViewController:self];
```

**Set content size in view controller**
```objc
@implementation ViewController

- (instancetype)init
{
    if (self = [super init]) {
        self.title = @"View Controller";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextBtnDidTap)];
        self.contentSizeInPopup = CGSizeMake(300, 400);
        self.landscapeContentSizeInPopup = CGSizeMake(400, 200);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Add views here
    // self.view.frame.size == self.contentSizeInPopup in portrait
    // self.view.frame.size == self.landscapeContentSizeInPopup in landscape
}

@end
```

**Push, pop and dismiss view controllers**  
```objc
[self.popupController pushViewController:[ViewController new] animated:YES];
[self.popupController popViewControllerAnimated:YES]; // Popup will be dismissed if there is only one view controller in the popup view controller stack
[self.popupController dismiss];
```
![Push & Pop](https://cloud.githubusercontent.com/assets/1491282/9857915/0d4ab3ee-5b50-11e5-81bc-8fbae3ad8c06.gif)

**Bottom sheet style**
```objc
STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[ViewController new]];
popupController.style = STPopupStyleBottomSheet;
[popupController presentInViewController:self];
```
![Bottom Sheet](https://cloud.githubusercontent.com/assets/1491282/10417963/7649f356-7080-11e5-8f3c-0cb817b8353e.gif)

**Customize popup transition style**
```objc
#pragma mark - STPopupControllerTransitioning

- (NSTimeInterval)popupControllerTransitionDuration:(STPopupControllerTransitioningContext *)context
{
    return context.action == STPopupControllerTransitioningActionPresent ? 0.5 : 0.35;
}

- (void)popupControllerAnimateTransition:(STPopupControllerTransitioningContext *)context completion:(void (^)())completion
{
    UIView *containerView = context.containerView;
    if (context.action == STPopupControllerTransitioningActionPresent) {
        containerView.transform = CGAffineTransformMakeTranslation(containerView.superview.bounds.size.width - containerView.frame.origin.x, 0);
        
        [UIView animateWithDuration:[self popupControllerTransitionDuration:context] delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            context.containerView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            completion();
        }];
    }
    else {
        [UIView animateWithDuration:[self popupControllerTransitionDuration:context] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            containerView.transform = CGAffineTransformMakeTranslation(- 2 * (containerView.superview.bounds.size.width - containerView.frame.origin.x), 0);
        } completion:^(BOOL finished) {
            containerView.transform = CGAffineTransformIdentity;
            completion();
        }];
    }
}
```

**Blur background**
```objc
STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[PopupViewController1 new]];
if (NSClassFromString(@"UIBlurEffect")) {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    popupController.backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
}
```

**Dismiss by tapping background**
```objc
popupController = [[STPopupController alloc] initWithRootViewController:self];
[popupController.backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewDidTap)]];
```

**Customize UI**
```objc
[STPopupNavigationBar appearance].barTintColor = [UIColor colorWithRed:0.20 green:0.60 blue:0.86 alpha:1.0];
[STPopupNavigationBar appearance].tintColor = [UIColor whiteColor];
[STPopupNavigationBar appearance].barStyle = UIBarStyleDefault;
[STPopupNavigationBar appearance].titleTextAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"Cochin" size:18], NSForegroundColorAttributeName: [UIColor whiteColor] };
    
[[UIBarButtonItem appearanceWhenContainedIn:[STPopupNavigationBar class], nil] setTitleTextAttributes:@{ NSFontAttributeName:[UIFont fontWithName:@"Cochin" size:17] } forState:UIControlStateNormal];
```
![Customize UI](https://cloud.githubusercontent.com/assets/1491282/9911306/0f6db056-5cd4-11e5-9329-33b0cf02e1b0.png)

**Auto-reposition when keyboard is showing up**  
No codes needed for this feature  
![Auto-reposition](https://cloud.githubusercontent.com/assets/1491282/9858277/5b29b130-5b52-11e5-9569-7560a0853493.gif)

**Drag to dismiss**  
No codes needed for this feature  
![Drag to dismiss](https://cloud.githubusercontent.com/assets/1491282/9858334/b103fc96-5b52-11e5-9c3f-517367ed9386.gif)

**Handle orientation change**  
No codes needed for this feature  
![Orientation change](https://cloud.githubusercontent.com/assets/1491282/9858372/e6538880-5b52-11e5-8882-8705588606ba.gif)

For more details, please download the example project.
