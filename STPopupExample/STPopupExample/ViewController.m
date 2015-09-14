//
//  ViewController.m
//  STPopupExample
//
//  Created by Kevin Lin on 11/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "ViewController.h"
#import "STPopupController.h"
#import "PopupViewController3.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[PopupViewController3 new]];
    popupController.cornerRadius = 4;
    [popupController presentInViewController:self];
}

@end
