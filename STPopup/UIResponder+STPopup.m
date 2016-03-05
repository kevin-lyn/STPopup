//
//  UIResponder+STPopup.m
//  STPopup
//
//  Created by Kevin Lin on 14/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "UIResponder+STPopup.h"
#import <objc/runtime.h>

NSString *const STPopupFirstResponderDidChangeNotification = @"STPopupFirstResponderDidChangeNotification";

@implementation UIResponder (STPopup)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleSelector:@selector(becomeFirstResponder) toSelector:@selector(st_becomeFirstResponder)];
    });
}

+ (void)swizzleSelector:(SEL)originalSelector toSelector:(SEL)swizzledSelector
{
    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (BOOL)st_becomeFirstResponder
{
    BOOL accepted = [self st_becomeFirstResponder];
    if (accepted) {
        [[NSNotificationCenter defaultCenter] postNotificationName:STPopupFirstResponderDidChangeNotification object:self];
    }
    return accepted;
}

@end
