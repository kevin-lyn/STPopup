//
//  STPopupPopoverArrowView.m
//  STPopup
//
//  Created by Kevin Lin on 13/6/16.
//  Copyright © 2016 Sth4Me. All rights reserved.
//

#import "STPopupPopoverArrowView.h"

CGFloat const STPopupPopoverArrowViewWidth = 35;
CGFloat const STPopupPopoverArrowViewHeight = 15;
CGFloat const STPopupPopoverArrowViewRadius = 4;

@implementation STPopupPopoverArrowView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, 0, rect.size.height);
    CGContextAddArcToPoint(context, rect.size.width / 2, 0, rect.size.width, rect.size.height, STPopupPopoverArrowViewRadius);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    CGContextAddLineToPoint(context, 0, rect.size.height);
    
    [[UIColor whiteColor] setFill];
    CGContextFillPath(context);
}

- (void)sizeToFit
{
    CGRect frame = self.frame;
    frame.size = CGSizeMake(STPopupPopoverArrowViewWidth, STPopupPopoverArrowViewHeight);
    self.frame = frame;
}

@end
