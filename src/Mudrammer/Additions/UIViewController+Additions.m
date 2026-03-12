//
//  UIViewController+Additions.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/22/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "UIViewController+Additions.h"

@implementation UIViewController (Additions)

- (BOOL)isViewVisible {
    return [self isViewLoaded] && self.view.window;
}

#pragma mark -

- (UINavigationController *) wrappedNavigationController {
    return [[SSDismissableNavigationController alloc] initWithRootViewController:self];
}

@end

@implementation SSDismissableNavigationController

- (NSArray<UIKeyCommand *> *)keyCommands {
    return @[
        [UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                            modifierFlags:0
                                   action:@selector(dismissWithEscape:)]
    ];
}

- (void)dismissWithEscape:(UIKeyCommand *)command {
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
