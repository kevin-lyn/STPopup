//
//  MultiSelectionViewController.m
//  STPopupExample
//
//  Created by Kevin Lin on 11/10/15.
//  Copyright © 2015 Sth4Me. All rights reserved.
//

#import "MultiSelectionViewController.h"
#import <STPopup/STPopup.h>

@implementation MultiSelectionViewController
{
    NSMutableSet *_mutableSelections;
}

- (IBAction)done:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(multiSelectionViewController:didFinishWithSelections:)]) {
        [self.delegate multiSelectionViewController:self didFinishWithSelections:_mutableSelections.allObjects];
    }
    [self.popupController popViewControllerAnimated:YES];
}

- (void)setDefaultSelections:(NSArray *)defaultSelections
{
    _defaultSelections = defaultSelections;
    _mutableSelections = [NSMutableSet setWithArray:defaultSelections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = @"Multi-Selection Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    NSString *item = self.items[indexPath.row];
    
    cell.textLabel.text = item;
    cell.accessoryType = [_mutableSelections containsObject:item] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_mutableSelections) {
        _mutableSelections = [NSMutableSet new];
    }
    
    NSString *item = self.items[indexPath.row];
    if (![_mutableSelections containsObject:item]) {
        [_mutableSelections addObject:item];
    }
    else {
        [_mutableSelections removeObject:item];
    }
    [tableView reloadData];
}

@end
