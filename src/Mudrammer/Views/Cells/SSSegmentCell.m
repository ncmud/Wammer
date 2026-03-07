//
//  SSSegmentCell.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/15/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SSSegmentCell.h"
#import <FBKVOController.h>

@interface SSSegmentCell ()

@property (nonatomic, copy) SSSegmentChangeHandler changeHandler;
@property (nonatomic, strong) UISegmentedControl *segmentControl;
@property (nonatomic, strong) FBKVOController *kvoController;

- (void) segmentControlChanged:(UISegmentedControl *)sender;

@end

@implementation SSSegmentCell

- (void)configureCell {
    _segmentControl = [UISegmentedControl new];
    self.segmentControl.momentary = NO;
    [self.segmentControl addTarget:self
                            action:@selector(segmentControlChanged:)
                  forControlEvents:UIControlEventValueChanged];

    [self applySegmentTheme];

    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryView = self.segmentControl;

    _kvoController = [FBKVOController controllerWithObserver:self];

    [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                        keyPath:kThemeFontColor
                        options:NSKeyValueObservingOptionNew
                          block:^(SSSegmentCell *cell, id object, NSDictionary *change) {
                              [cell applySegmentTheme];
                          }];

    [SSThemes configureCell:self];
}

- (void)applySegmentTheme {
    UIColor *fontColor = [[SSThemes sharedThemer] valueForThemeKey:kThemeFontColor];
    UIColor *bgColor = [[SSThemes sharedThemer] valueForThemeKey:kThemeBackgroundColor];

    self.segmentControl.selectedSegmentTintColor = fontColor;

    NSDictionary *normalAttrs = @{ NSForegroundColorAttributeName : [fontColor colorWithAlphaComponent:0.7] };
    NSDictionary *selectedAttrs = @{ NSForegroundColorAttributeName : bgColor };

    [self.segmentControl setTitleTextAttributes:normalAttrs forState:UIControlStateNormal];
    [self.segmentControl setTitleTextAttributes:selectedAttrs forState:UIControlStateSelected];

    self.segmentControl.backgroundColor = [fontColor colorWithAlphaComponent:0.12];
}

- (void)dealloc {
    _changeHandler = nil;
}

- (void)configureWithLabel:(NSString *)label
                  segments:(NSArray *)segments
             selectedIndex:(NSInteger)selectedIndex
             changeHandler:(SSSegmentChangeHandler)changeHandler {

    self.textLabel.text = label;

    [self.segmentControl removeAllSegments];
    [segments enumerateObjectsUsingBlock:^(NSString *title,
                                           NSUInteger index,
                                           BOOL *stop) {
        [self.segmentControl insertSegmentWithTitle:title
                                            atIndex:index
                                           animated:NO];
    }];
    [self.segmentControl sizeToFit];
    [self.segmentControl setSelectedSegmentIndex:selectedIndex];

    _changeHandler = changeHandler;
}

- (void)segmentControlChanged:(UISegmentedControl *)sender {
    NSInteger index = sender.selectedSegmentIndex;

    if (index == UISegmentedControlNoSegment) {
        return;
    }

    if (self.changeHandler) {
        self.changeHandler(index);
    }
}

@end
