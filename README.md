# STPopup ![CI Status](https://img.shields.io/travis/kevin0571/STPopup.svg?style=flat) ![Version](http://img.shields.io/cocoapods/v/STPopup.svg?style=flag) ![License](https://img.shields.io/cocoapods/l/STPopup.svg?style=flag)
`STPopup` provides `STPopupController`, which works just like `UINavigationController` in popup style, for both iPhone and iPad. It's written in Objective-C and compatible with Swift.

**Features:**
- Push/Pop view controller into/out of `STPopupController` just like `UINavigationController`.
- Set navigation items through `self.navigationItem` just like using a `UINavigationController`.
- Support both "Form Sheet" and "Bottom Sheet" style.
- Work well with storyboard(including segue).
- Customize UI by using `UIAppearance`.
- Customizable popup transition style.
- Auto-reposition of popup view when keyboard shows up, make sure your `UITextField`/`UITextView` won't be covered by the keyboard.
- Drag navigation bar to dismiss popup view.
- Support both portrait and landscape orientation in iPhone and iPad.
- iOS 7+.
- Compatible with Swift.

## Use Cases
![Use Cases](https://user-images.githubusercontent.com/1491282/57985696-b6e01300-7a63-11e9-91a9-b5aa55262967.jpg)

## Get Started
**CocoaPods**
```ruby
pod 'STPopup'
```
**Carthage**
```ruby
github "kevin0571/STPopup"
```
  
**Import header file**  
Objective-C
```objc
#import <STPopup/STPopup.h>
```
Swift
```swift
import STPopup
```

**Initialize and present STPopupController**  
Objective-C
```objc
STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:viewController];
[popupController presentInViewController:self];
```
Swift
```swift
let popupController = let popupController = STPopupController(rootViewController: viewController)
popupController.present(in: self)
```

**Set content size in view controller**  
Objective-C
```objc
@implementation ViewController

- (instancetype)init
{
    if (self = [super init]) {
        self.title = @"View Controller";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextBtnDidTap)];
        // It's required to set content size of popup.
        self.contentSizeInPopup = CGSizeMake(300, 400);
        self.landscapeContentSizeInPopup = CGSizeMake(400, 200);
    }
    return self;
}

@end
```
Swift
```swift
class ViewController: UIViewController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        title = "View Controller"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextBtnDidTap))
        // It's required to set content size of popup.
        contentSizeInPopup = CGSize(width: 300, height: 400)
        landscapeContentSizeInPopup = CGSize(width: 400, height: 200)
    }
}
```
**Set content size of view controller which is loaded from Storyboard**  
Set content size in storyboard or in `awakeFromNib`.  
![Storyboard](https://user-images.githubusercontent.com/1491282/57982394-dca5f180-7a3c-11e9-8d63-3ca6c3837860.png)

**Push, pop and dismiss view controllers**  
Objective-C
```objc
[self.popupController pushViewController:[ViewController new] animated:YES];
[self.popupController popViewControllerAnimated:YES]; // Popup will be dismissed if there is only one view controller in the popup view controller stack
[self.popupController dismiss];
```
Swift
```swift
popupController?.push(viewController, animated: true)
popupController?.popViewController(animated: true) // Popup will be dismissed if there is only one view controller in the popup view controller stack
popupController?.dismiss()
```

![Push & Pop](https://cloud.githubusercontent.com/assets/1491282/9857915/0d4ab3ee-5b50-11e5-81bc-8fbae3ad8c06.gif)

**Bottom sheet style**  
Objective-C
```objc
STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[ViewController new]];
popupController.style = STPopupStyleBottomSheet;
[popupController presentInViewController:self];
```
Swift
```swift
let popupController = STPopupController(rootViewController: viewController)
popupController.style = .bottomSheet
popupController.present(in: self)
```
![Bottom Sheet](https://cloud.githubusercontent.com/assets/1491282/10417963/7649f356-7080-11e5-8f3c-0cb817b8353e.gif)

**Customize popup transition style**  
Objective-C
```objc
#pragma mark - STPopupControllerTransitioning

- (NSTimeInterval)popupControllerTransitionDuration:(STPopupControllerTransitioningContext *)context
{
    return context.action == STPopupControllerTransitioningActionPresent ? 0.5 : 0.35;
}

- (void)popupControllerAnimateTransition:(STPopupControllerTransitioningContext *)context completion:(void (^)())completion
{
    // Popup will be presented with an animation sliding from right to left.
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

// Use custom transitioning in popup controller
STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:viewController];
popupController.transitionStyle = STPopupTransitionStyleCustom;
popupController.transitioning = self;
[popupController presentInViewController:self];
```
Swift
```swift
// MARK: STPopupControllerTransitioning

func popupControllerTransitionDuration(_ context: STPopupControllerTransitioningContext) -> TimeInterval {
    return context.action == .present ? 0.5 : 0.35
}

func popupControllerAnimateTransition(_ context: STPopupControllerTransitioningContext, completion: @escaping () -> Void) {
    // Popup will be presented with an animation sliding from right to left.
    let containerView = context.containerView
    if context.action == .present {
        containerView.transform = CGAffineTransform(translationX: containerView.superview!.bounds.size.width - containerView.frame.origin.x, y: 0)
        UIView.animate(withDuration: popupControllerTransitionDuration(context), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            containerView.transform = .identity
        }, completion: { _ in
            completion()
        });
    } else {
        UIView.animate(withDuration: popupControllerTransitionDuration(context), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            containerView.transform = CGAffineTransform(translationX: -2 * (containerView.superview!.bounds.size.width - containerView.frame.origin.x), y: 0)
        }, completion: { _ in
            containerView.transform = .identity
            completion()
        });
    }
}

// Use custom transitioning in popup controller
let popupController = let popupController = STPopupController(rootViewController: viewController)
popupController.transitionStyle = .custom
popupController.transitioning = self
popupController.present(in: self)
```

**Blur background**  
Objective-C
```objc
STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[PopupViewController1 new]];
if (NSClassFromString(@"UIBlurEffect")) {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    popupController.backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
}
```
Swift
```swift
let popupController = let popupController = STPopupController(rootViewController: viewController)
if NSClassFromString("UIBlurEffect") != nil {
    let blurEffect = UIBlurEffect(style: .dark)
    popupController.backgroundView = UIVisualEffectView(effect: blurEffect)
}
```

**Action of tapping on area outside of popup**  
Objective-C
```objc
[popupController.backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewDidTap)]];
```
Swift
```swift
popupController.backgroundView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backgroundViewDidTap)))
```

**Customize UI**  
Objective-C
```objc
[STPopupNavigationBar appearance].barTintColor = [UIColor colorWithRed:0.20 green:0.60 blue:0.86 alpha:1.0];
[STPopupNavigationBar appearance].tintColor = [UIColor whiteColor];
[STPopupNavigationBar appearance].barStyle = UIBarStyleDefault;
[STPopupNavigationBar appearance].titleTextAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"Cochin" size:18], NSForegroundColorAttributeName: [UIColor whiteColor] };
    
[[UIBarButtonItem appearanceWhenContainedIn:[STPopupNavigationBar class], nil] setTitleTextAttributes:@{ NSFontAttributeName:[UIFont fontWithName:@"Cochin" size:17] } forState:UIControlStateNormal];
```
Swift
```swift
STPopupNavigationBar.appearance().barTintColor = UIColor(red: 0.2, green: 0.6, blue: 0.86, alpha: 1)
STPopupNavigationBar.appearance().tintColor = .white
STPopupNavigationBar.appearance().barStyle = .default
STPopupNavigationBar.appearance().titleTextAttributes = [
    .font: UIFont(name: "Cochin", size: 18) ?? .systemFont(ofSize: 18),
    .foregroundColor: UIColor.white,
]
UIBarButtonItem
    .appearance(whenContainedInInstancesOf: [STPopupNavigationBar.self])
    .setTitleTextAttributes([
        .font: UIFont(name: "Cochin", size: 18) ?? .systemFont(ofSize: 18),
        ], for: .normal)
```
![Customize UI](https://cloud.githubusercontent.com/assets/1491282/9911306/0f6db056-5cd4-11e5-9329-33b0cf02e1b0.png)

**Auto-reposition when keyboard is showing up**  
This is default behavior.  
![Auto-reposition](https://cloud.githubusercontent.com/assets/1491282/9858277/5b29b130-5b52-11e5-9569-7560a0853493.gif)

**Drag to dismiss**  
This is default behavior.  
![Drag to dismiss](https://cloud.githubusercontent.com/assets/1491282/9858334/b103fc96-5b52-11e5-9c3f-517367ed9386.gif)

**Handle orientation change**  
This is default behavior.  
![Orientation change](https://cloud.githubusercontent.com/assets/1491282/9858372/e6538880-5b52-11e5-8882-8705588606ba.gif)

Please checkout the example project for more details.
