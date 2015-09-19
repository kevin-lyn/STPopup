//
//  ViewController.m
//  STPopup
//
//  Created by Kevin Lin on 11/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "ViewController.h"
#import "PopupViewController1.h"
#import "STPopup.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)showPopupWithTransitionStyle:(STPopupTransitionStyle)transitionStyle rootViewController:(UIViewController *)rootViewController
{
    STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:rootViewController];
    popupController.cornerRadius = 4;
    popupController.transitionStyle = transitionStyle;
    [popupController presentInViewController:self];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0: {
            [self showPopupWithTransitionStyle:STPopupTransitionStyleSlideVertical rootViewController:[PopupViewController1 new]];
        }
            break;
        case 1: {
            [self showPopupWithTransitionStyle:STPopupTransitionStyleFade rootViewController:[PopupViewController1 new]];
        }
            break;
        case 2: {
            [self showPopupWithTransitionStyle:STPopupTransitionStyleSlideVertical rootViewController:[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"PopupViewController2"]];
        }
            break;
        case 3: {
            [STPopupNavigationBar appearance].barTintColor = [UIColor colorWithRed:0.20 green:0.60 blue:0.86 alpha:1.0];
            [STPopupNavigationBar appearance].tintColor = [UIColor whiteColor];
            [STPopupNavigationBar appearance].barStyle = UIBarStyleDefault;
            [STPopupNavigationBar appearance].titleTextAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"Cochin" size:18],
                                                                       NSForegroundColorAttributeName: [UIColor whiteColor] };
            
            [[UIBarButtonItem appearanceWhenContainedIn:[STPopupNavigationBar class], nil] setTitleTextAttributes:@{ NSFontAttributeName:[UIFont fontWithName:@"Cochin" size:17] } forState:UIControlStateNormal];
            
            [self showPopupWithTransitionStyle:STPopupTransitionStyleSlideVertical rootViewController:[PopupViewController1 new]];
        }
            break;
        default:
            break;
    }
}

@end
