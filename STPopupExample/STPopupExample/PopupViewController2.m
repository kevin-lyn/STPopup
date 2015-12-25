//
//  PopupViewController2.m
//  STPopupExample
//
//  Created by Kevin Lin on 11/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "PopupViewController2.h"
#import "PopupViewController3.h"
#import <STPopup/STPopup.h>

@implementation PopupViewController2

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.contentSizeInPopup = CGSizeMake(300, 200);
    self.landscapeContentSizeInPopup = CGSizeMake(400, 200);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextBtnDidTap)];
}

- (IBAction)nextBtnDidTap
{
    [self.popupController pushViewController:[PopupViewController3 new] animated:YES];
}

@end
