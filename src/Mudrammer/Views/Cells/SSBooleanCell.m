//
//  SSBooleanCell.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/16/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSBooleanCell.h"
#import <FBKVOController.h>

@interface SSBooleanCell ()

@property (nonatomic, copy) SSBooleanChangeHandler changeHandler;
@property (nonatomic, strong) UISwitch *boolSwitch;
@property (nonatomic, strong) FBKVOController *kvoController;

- (void) switchDidChange:(UISwitch *)sender;

@end

@implementation SSBooleanCell

- (void)configureCell {
    _boolSwitch = [UISwitch new];
    [self applySwitchTheme];
    [self.boolSwitch addTarget:self
                        action:@selector(switchDidChange:)
              forControlEvents:UIControlEventValueChanged];
    [self.boolSwitch sizeToFit];

    self.accessoryView = _boolSwitch;
    self.textLabel.minimumScaleFactor = 0.6f;
    self.textLabel.adjustsFontSizeToFitWidth = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    _kvoController = [FBKVOController controllerWithObserver:self];

    [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                        keyPath:kThemeFontColor
                        options:NSKeyValueObservingOptionNew
                          block:^(SSBooleanCell *cell, id object, NSDictionary *change) {
                              [cell applySwitchTheme];
                          }];

    [SSThemes configureCell:self];
}

- (void)applySwitchTheme {
    UIColor *fontColor = [[SSThemes sharedThemer] valueForThemeKey:kThemeFontColor];
    BOOL isDark = [[SSThemes sharedThemer] isUsingDarkTheme];

    if (isDark) {
        self.boolSwitch.onTintColor = [UIColor systemOrangeColor];
    } else {
        self.boolSwitch.onTintColor = fontColor;
    }

}

- (void)dealloc {
    _changeHandler = nil;
    [_boolSwitch removeTarget:self action:@selector(switchDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureWithLabel:(NSString *)label
                  selected:(BOOL)selected
             changeHandler:(SSBooleanChangeHandler)changeHandler {

    self.textLabel.text = label;

    [self.boolSwitch setOn:selected
                  animated:NO];

    self.changeHandler = changeHandler;
}

#pragma mark - Selection

- (void)switchDidChange:(UISwitch *)sender {
    if (self.changeHandler) {
        self.changeHandler([sender isOn]);
    }
}

@end
