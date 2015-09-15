//
//  ViewController.m
//  STPopupExample
//
//  Created by Kevin Lin on 11/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "ViewController.h"
#import "PopupViewController1.h"
#import "STPopup.h"

@interface ViewController ()

@end

@implementation ViewController
{
    NSArray *_views;
    STPopupTransitionStyle _transitionStyle;
    UILabel *_transitionStyleLabel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *showPopupBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [showPopupBtn setTitle:@"Show Popup" forState:UIControlStateNormal];
    [showPopupBtn addTarget:self action:@selector(showPopupBtnDidTap) forControlEvents:UIControlEventTouchUpInside];
    [showPopupBtn sizeToFit];
    [self.view addSubview:showPopupBtn];
    
    UIView *transitionStyleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    [self.view addSubview:transitionStyleView];
    
    _transitionStyleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];
    _transitionStyleLabel.font = [UIFont systemFontOfSize:16];
    [transitionStyleView addSubview:_transitionStyleLabel];
    [self updateTransitionStyleLabel];
    
    UISwitch *transitionStyleSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(_transitionStyleLabel.frame.size.width,
                                                                                 0, 50, 44)];
    [transitionStyleSwitch addTarget:self action:@selector(transitionStyleSwitchDidChange:) forControlEvents:UIControlEventValueChanged];
    [transitionStyleView addSubview:transitionStyleSwitch];
    
    UIButton *appearanceBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [appearanceBtn setTitle:@"Customize Appearance" forState:UIControlStateNormal];
    [appearanceBtn addTarget:self action:@selector(appearanceBtnDidTap) forControlEvents:UIControlEventTouchUpInside];
    [appearanceBtn sizeToFit];
    [self.view addSubview:appearanceBtn];
    
    _views = @[ showPopupBtn, transitionStyleView, appearanceBtn ];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    float spacing = 40;
    float totalHeight = [[_views valueForKeyPath:@"@sum.layer.frame.size.height"] floatValue] + spacing * (_views.count - 1);
    float y = (self.view.bounds.size.height - totalHeight) / 2;
    
    for (UIView *view in _views) {
        CGRect frame = view.frame;
        frame.origin = CGPointMake((self.view.bounds.size.width - frame.size.width) / 2, y);
        view.frame = frame;
        y += frame.size.height + spacing;
    }
}

- (void)showPopup
{
    STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[PopupViewController1 new]];
    popupController.cornerRadius = 4;
    popupController.transitionStyle = _transitionStyle;
    [popupController presentInViewController:self];
}

- (void)updateTransitionStyleLabel
{
    _transitionStyleLabel.text = _transitionStyle == STPopupTransitionStyleSlideVertical ? @"Slide Vertical" : @"Fade";
}

- (void)showPopupBtnDidTap
{
    [self showPopup];
}

- (void)transitionStyleSwitchDidChange:(UISwitch *)transitionStyleSwitch
{
    _transitionStyle = transitionStyleSwitch.on ? STPopupTransitionStyleFade : STPopupTransitionStyleSlideVertical;
    [self updateTransitionStyleLabel];
}

- (void)appearanceBtnDidTap
{
    [STPopupNavigationBar appearance].barTintColor = [UIColor colorWithRed:0.20 green:0.60 blue:0.86 alpha:1.0];
    [STPopupNavigationBar appearance].tintColor = [UIColor whiteColor];
    [STPopupNavigationBar appearance].barStyle = UIBarStyleDefault;
    [STPopupNavigationBar appearance].titleTextAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"Cochin" size:18],
                                                               NSForegroundColorAttributeName: [UIColor whiteColor] };
    
    [[UIBarButtonItem appearanceWhenContainedIn:[STPopupNavigationBar class], nil] setTitleTextAttributes:@{ NSFontAttributeName:[UIFont fontWithName:@"Cochin" size:17] } forState:UIControlStateNormal];
    
    [self showPopup];
}

@end
