//
//  BulletinBoardViewController.m
//  STPopupExample
//
//  Created by Kevin Lin on 18/05/2019.
//  Copyright © 2019 Sth4Me. All rights reserved.
//

#import "BulletinBoardViewController.h"

#import <STPopup/STPopup.h>

@interface BulletinBoardViewController ()

@end

@implementation BulletinBoardViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    CGFloat margin = 20;
    self.contentSizeInPopup = CGSizeMake([UIScreen mainScreen].bounds.size.width - margin * 2, 480);
    self.view.layer.cornerRadius = 20;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.popupController.navigationBarHidden = YES;
}

- (IBAction)allowButtonDidTap
{
    [self.popupController dismiss];
}

- (IBAction)closeButtonDidTap
{
    [self.popupController dismiss];
}

@end
