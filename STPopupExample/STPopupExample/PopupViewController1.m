//
//  PopupViewController1.m
//  STPopupExample
//
//  Created by Kevin Lin on 11/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "PopupViewController1.h"
#import "PopupViewController2.h"
#import <STPopup/STPopup.h>

@implementation PopupViewController1
{
    UILabel *_label;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.title = @"Apple";
        self.contentSizeInPopup = CGSizeMake(300, 400);
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
    _label.text = @"Apple Inc. (commonly known as Apple) is an American multinational technology company headquartered in Cupertino, California, that designs, develops, and sells consumer electronics, computer software, and online services. Its best-known hardware products are the Mac personal computers, the iPod portable media player, the iPhone smartphone, the iPad tablet computer, and the Apple Watch smartwatch. Apple's consumer software includes the OS X and iOS operating systems, the iTunes media player, the Safari web browser, and the iLife and iWork creativity and productivity suites. Its online services include the iTunes Store, the iOS App Store and Mac App Store, and iCloud.";
    [self.view addSubview:_label];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _label.frame = CGRectMake(20, 10, self.view.frame.size.width - 40, self.view.frame.size.height - 20);
}

- (void)nextBtnDidTap
{
    [self.popupController pushViewController:[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"PopupViewController2"] animated:YES];
}

@end
