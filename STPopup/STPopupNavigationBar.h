//
//  STPopupNavigationBar.h
//  STPopup
//
//  Created by Kevin Lin on 13/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPopupNavigationBar : UINavigationBar

/**
 Indicates if the navigation bar is draggable to dissmiss the popup.
 Default to YES.
 */
@property (nonatomic, assign) BOOL draggable;

@end

NS_ASSUME_NONNULL_END
