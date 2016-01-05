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

@interface ViewController ()

@end

@implementation ViewController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0: {
            STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[PopupViewController1 new]];
            popupController.cornerRadius = 4;
            [popupController presentInViewController:self];
        }
            break;
        case 1: {
            STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[PopupViewController1 new]];
            popupController.cornerRadius = 4;
            popupController.transitionStyle = STPopupTransitionStyleFade;
            [popupController presentInViewController:self];
        }
            break;
        case 2: {
            STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"PopupViewController2"]];
            popupController.cornerRadius = 4;
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
            popupController.cornerRadius = 4;
            [popupController presentInViewController:self];
        }
            break;
        case 4: {
            STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[PopupViewController1 new]];
            popupController.cornerRadius = 4;
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
        default:
            break;
    }
}

@end
