//
//  PopupViewController2.m
//  STPopupExample
//
//  Created by Kevin Lin on 11/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "PopupViewController2.h"
#import "PopupViewController3.h"
#import "STPopup.h"

@implementation PopupViewController2
{
    UILabel *_label;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.title = @"iOS";
        self.contentSizeInPopup = CGSizeMake(300, 200);
        self.landscapeContentSizeInPopup = CGSizeMake(400, 200);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextBtnDidTap)];
    
    _label = [UILabel new];
    _label.numberOfLines = 0;
    _label.text = @"iOS (originally iPhone OS) is a mobile operating system created and developed by Apple Inc. and distributed exclusively for Apple hardware. It is the operating system that presently powers many of the company's mobile devices, including the iPhone, iPad, and iPod touch.";
    [self.view addSubview:_label];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _label.frame = CGRectMake(20, 10, self.view.frame.size.width - 40, self.view.frame.size.height - 20);
}

- (void)nextBtnDidTap
{
    [self.popupController pushViewController:[PopupViewController3 new] animated:YES];
}

@end
