//
//  ViewController.m
//  STPopupExample
//
//  Created by Kevin Lin on 11/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "ViewController.h"
#import "PopupViewController1.h"
#import <STPopup/STPopup.h>

@interface ViewController () <STPopupControllerTransitioning>

@end

@implementation ViewController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0: {
            STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[PopupViewController1 new]];
            popupController.containerView.layer.cornerRadius = 4;
            [popupController presentInViewController:self];
        }
            break;
        case 1: {
            STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[PopupViewController1 new]];
            popupController.containerView.layer.cornerRadius = 4;
            popupController.transitionStyle = STPopupTransitionStyleFade;
            [popupController presentInViewController:self];
        }
            break;
        case 2: {
            STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"PopupViewController2"]];
            popupController.containerView.layer.cornerRadius = 4;
            [popupController presentInViewController:self];
        }
            break;
        case 3: {
            [STPopupNavigationBar appearance].barTintColor = [UIColor colorWithRed:0.20 green:0.60 blue:0.86 alpha:1.0];
            [STPopupNavigationBar appearance].tintColor = [UIColor whiteColor];
            [STPopupNavigationBar appearance].barStyle = UIBarStyleDefault;
            [STPopupNavigationBar appearance].titleTextAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"Cochin" size:18],
                                                                       NSForegroundColorAttributeName: [UIColor whiteColor] };
            
            [[UIBarButtonItem appearanceWhenContainedIn:[STPopupNavigationBar class], nil] setTitleTextAttributes:@{ NSFontAttributeName:[UIFont fontWithName:@"Cochin" size:17] } forState:UIControlStateNormal];
            
            STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[PopupViewController1 new]];
            popupController.containerView.layer.cornerRadius = 4;
            [popupController presentInViewController:self];
        }
            break;
        case 4: {
            STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[PopupViewController1 new]];
            popupController.containerView.layer.cornerRadius = 4;
            if (NSClassFromString(@"UIBlurEffect")) {
                UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
                popupController.backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
                popupController.backgroundView.alpha = 0.8; // This is not necessary
            }
            [popupController presentInViewController:self];
        }
            break;
        case 5: {
            STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BottomSheetDemoViewController"]];
            popupController.style = STPopupStyleBottomSheet;
            [popupController presentInViewController:self];
        }
            break;
        case 6: {
            STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[PopupViewController1 new]];
            popupController.transitionStyle = STPopupTransitionStyleCustom;
            popupController.transitioning = self;
            popupController.containerView.layer.cornerRadius = 4;
            [popupController presentInViewController:self];
        }
            break;
        default:
            break;
    }
}

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

@end
