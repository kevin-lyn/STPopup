//
//  STPopupNavigationBar.m
//  STPopup
//
//  Created by Kevin Lin on 13/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "STPopupNavigationBar.h"

@protocol STPopupNavigationTouchEventDelegate <NSObject>

- (void)popupNavigationBar:(STPopupNavigationBar *)navigationBar touchDidMoveWithOffset:(CGFloat)offset;
- (void)popupNavigationBar:(STPopupNavigationBar *)navigationBar touchDidEndWithOffset:(CGFloat)offset;

@end

@interface STPopupNavigationBar ()

@property (nonatomic, weak) id<STPopupNavigationTouchEventDelegate> touchEventDelegate;

@end

@implementation STPopupNavigationBar
{
    BOOL _moving;
    CGFloat _movingStartY;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.draggable = YES;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    if ((touch.view == self || touch.view.superview == self) && !_moving) {
        _moving = YES;
        _movingStartY = [touch locationInView:self.window].y;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    if (_moving) {
        UITouch *touch = [touches anyObject];
        float offset = [touch locationInView:self.window].y - _movingStartY;
        if ([self.touchEventDelegate respondsToSelector:@selector(popupNavigationBar:touchDidMoveWithOffset:)]) {
            [self.touchEventDelegate popupNavigationBar:self touchDidMoveWithOffset:offset];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_moving) {
        UITouch *touch = [touches anyObject];
        float offset = [touch locationInView:self.window].y - _movingStartY;
        [self movingDidEndWithOffset:offset];
    }
    
    [super touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_moving) {
        UITouch *touch = [touches anyObject];
        float offset = [touch locationInView:self.window].y - _movingStartY;
        [self movingDidEndWithOffset:offset];
    }
    
    [super touchesEnded:touches withEvent:event];
}

- (void)movingDidEndWithOffset:(float)offset
{
    _moving = NO;
    if ([self.touchEventDelegate respondsToSelector:@selector(popupNavigationBar:touchDidEndWithOffset:)]) {
        [self.touchEventDelegate popupNavigationBar:self touchDidEndWithOffset:offset];
    }
}

@end
