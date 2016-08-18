//
//  STPopupControllerTransitioningSlideVertical.m
//  STPopup
//
//  Created by Kevin Lin on 18/8/16.
//  Copyright © 2016 Sth4Me. All rights reserved.
//

#import "STPopupControllerTransitioningSlideVertical.h"

@implementation STPopupControllerTransitioningSlideVertical

- (NSTimeInterval)popupControllerTransitionDuration:(STPopupControllerTransitioningContext *)context
{
    return context.action == STPopupControllerTransitioningActionPresent ? 0.5 : 0.35;
}

- (void)popupControllerAnimateTransition:(STPopupControllerTransitioningContext *)context completion:(void (^)())completion
{
    UIView *containerView = context.containerView;
    if (context.action == STPopupControllerTransitioningActionPresent) {
        containerView.transform = CGAffineTransformMakeTranslation(0, containerView.superview.bounds.size.height - containerView.frame.origin.y);
        
        [UIView animateWithDuration:[self popupControllerTransitionDuration:context] delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            context.containerView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            completion();
        }];
    }
    else {
        CGAffineTransform lastTransform = containerView.transform;
        containerView.transform = CGAffineTransformIdentity;
        CGFloat originY = containerView.frame.origin.y;
        containerView.transform = lastTransform;

        [UIView animateWithDuration:[self popupControllerTransitionDuration:context] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            containerView.transform = CGAffineTransformMakeTranslation(0, containerView.superview.bounds.size.height - originY + containerView.frame.size.height);
        } completion:^(BOOL finished) {
            containerView.transform = CGAffineTransformIdentity;
            completion();
        }];
    }
}

@end
