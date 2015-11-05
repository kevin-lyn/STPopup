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

@property (nonatomic, assign) IBInspectable CGSize contentSizeInPopup;
@property (nonatomic, assign) IBInspectable CGSize landscapeContentSizeInPopup;
@property (nonatomic, weak, readonly) STPopupController *popupController;

@end
