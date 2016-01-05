//
//  BottomSheetDemoViewController.m
//  STPopupExample
//
//  Created by Kevin Lin on 11/10/15.
//  Copyright © 2015 Sth4Me. All rights reserved.
//

#import "BottomSheetDemoViewController.h"
#import "MultiSelectionViewController.h"
#import <STPopup/STPopup.h>

NSString * const BottomSheetDemoFruits = @"Fruits";
NSString * const BottomSheetDemoVegetables = @"Vegetables";

@interface BottomSheetDemoSelectionCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UILabel *placeholderLabel;
@property (nonatomic, strong) NSArray *selections;

@end

@implementation BottomSheetDemoSelectionCell
{
    NSArray *_buttons;
}

- (void)setSelections:(NSArray *)selections
{
    selections = [selections sortedArrayUsingSelector:@selector(localizedCompare:)];
    _selections = selections;
    [_buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.placeholderLabel.hidden = selections.count > 0;
    
    CGFloat buttonX = 15;
    NSMutableArray *buttons = [NSMutableArray new];
    for (NSString *selection in selections) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.layer.cornerRadius = 4;
        button.backgroundColor = button.tintColor;
        button.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10);
        [button setTitle:selection forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button sizeToFit];
        button.frame = CGRectMake(buttonX, (self.scrollView.frame.size.height - button.frame.size.height) / 2, button.frame.size.width, button.frame.size.height);
        
        [buttons addObject:button];
        [self.scrollView addSubview:button];
        
        buttonX += button.frame.size.width + 10;
    }
    self.scrollView.contentSize = CGSizeMake(buttonX, self.scrollView.frame.size.height);
    
    _buttons = [NSArray arrayWithArray:buttons];
}

@end

@interface BottomSheetDemoViewController () <MultiSelectionViewControllerDelegate>

@end

@implementation BottomSheetDemoViewController
{
    NSArray *_fruitsSelections;
    NSArray *_vegetablesSelections;
}

- (void)multiSelectionViewController:(MultiSelectionViewController *)vc didFinishWithSelections:(NSArray *)selections
{
    if ([vc.title isEqualToString:BottomSheetDemoFruits]) {
        _fruitsSelections = selections;
    }
    else if ([vc.title isEqualToString:BottomSheetDemoVegetables]) {
        _vegetablesSelections = selections;
    }
    [self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[BottomSheetDemoSelectionCell class]]) {
        BottomSheetDemoSelectionCell *selectionCell = (BottomSheetDemoSelectionCell *)cell;
        selectionCell.selections = [[NSArray arrayWithArray:_fruitsSelections] arrayByAddingObjectsFromArray:_vegetablesSelections];
    }
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    MultiSelectionViewController *destinationViewController = (MultiSelectionViewController *)segue.destinationViewController;
    destinationViewController.delegate = self;
    if ([segue.identifier isEqualToString:@"FruitsSegue"]) {
        destinationViewController.title = BottomSheetDemoFruits;
        destinationViewController.items = @[ @"Apples", @"Oranges", @"Grapes", @"Strawberries", @"Bananas", @"Lemons" ];
        destinationViewController.defaultSelections = _fruitsSelections;
    }
    else if ([segue.identifier isEqualToString:@"VegetablesSegue"]) {
        destinationViewController.title = BottomSheetDemoVegetables;
        destinationViewController.items = @[ @"Cabbage", @"Turnip", @"Radish", @"Carrot", @"Lettuce", @"Potato", @"Tomato" ];
        destinationViewController.defaultSelections = _vegetablesSelections;
    }
}

@end
