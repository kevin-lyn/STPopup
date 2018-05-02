//
//  STPopupControllerTransitioningFade.m
//  STPopup
//
//  Created by Kevin Lin on 18/8/16.
//  Copyright © 2016 Sth4Me. All rights reserved.
//

#import "STPopupControllerTransitioningFade.h"

@implementation STPopupControllerTransitioningFade

- (NSTimeInterval)popupControllerTransitionDuration:(STPopupControllerTransitioningContext *)context
{
    return context.action == STPopupControllerTransitioningActionPresent ? 0.25 : 0.2;
}

- (void)popupControllerAnimateTransition:(STPopupControllerTransitioningContext *)context completion:(void (^)(void))completion
{
    UIView *containerView = context.containerView;
    if (context.action == STPopupControllerTransitioningActionPresent) {
        containerView.alpha = 0;
        containerView.transform = CGAffineTransformMakeScale(1.05, 1.05);
        
        [UIView animateWithDuration:[self popupControllerTransitionDuration:context] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            containerView.alpha = 1;
            containerView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            completion();
        }];
    }
    else {
        [UIView animateWithDuration:[self popupControllerTransitionDuration:context] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            containerView.alpha = 0;
        } completion:^(BOOL finished) {
            containerView.alpha = 1;
            completion();
        }];
    }
}

@end
