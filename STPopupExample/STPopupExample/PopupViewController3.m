//
//  PopupViewController3.m
//  STPopupExample
//
//  Created by Kevin Lin on 13/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "PopupViewController3.h"
#import <STPopup/STPopup.h>

@implementation PopupViewController3
{
    UILabel *_label;
    UIView *_separatorView;
    UITextField *_textField;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.title = @"Keyboard";
        self.contentSizeInPopup = CGSizeMake(300, 400);
        self.landscapeContentSizeInPopup = CGSizeMake(400, 200);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Image" style:UIBarButtonItemStylePlain target:self action:@selector(imageBtnDidTap)];
    
    _label = [UILabel new];
    _label.numberOfLines = 0;
    _label.text = @"Popup view will be adjusted to appropriate position if keyboard is shown";
    _label.textColor = [UIColor colorWithWhite:0.8 alpha:1];
    _label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_label];
    
    _separatorView = [UIView new];
    _separatorView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    [self.view addSubview:_separatorView];
    
    _textField = [UITextField new];
    _textField.placeholder = @"Tap to input";
    _textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
    _textField.leftViewMode = UITextFieldViewModeAlways;
    [self.view addSubview:_textField];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    _textField.frame = CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44);
    _separatorView.frame = CGRectMake(0, _textField.frame.origin.y - 0.5, self.view.frame.size.width, 0.5);
    _label.frame = CGRectMake(20, 10, self.view.frame.size.width - 40, self.view.frame.size.height - 20 - _textField.frame.size.height);
}

- (void)imageBtnDidTap
{
    UIImagePickerController *imagePickerViewController = [UIImagePickerController new];
    [self presentViewController:imagePickerViewController animated:YES completion:nil];
}

@end
