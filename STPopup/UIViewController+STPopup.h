//
//  UIViewController+STPopup.h
//  STPopup
//
//  Created by Kevin Lin on 13/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPopupController;

@interface UIViewController (STPopup)

/**
 Content size of popup in portrait orientation.
 */
@property (nonatomic, assign) IBInspectable CGSize contentSizeInPopup;

/**
 Content size of popup in landscape orientation.
 */
@property (nonatomic, assign) IBInspectable CGSize landscapeContentSizeInPopup;

/**
 Popup controller which is containing the view controller.
 Will be nil if the view controller is not contained in any popup controller.
 */
@property (nonatomic, weak, readonly) STPopupController *popupController;

@end
