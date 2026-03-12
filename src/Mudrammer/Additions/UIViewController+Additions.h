//
//  UIViewController+Additions.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/22/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;
@import Foundation;

@interface UIViewController (Additions)

- (BOOL) isViewVisible;

// Wraps with a SSDismissableNavigationController
- (UINavigationController *) wrappedNavigationController;

@end

@interface SSDismissableNavigationController : UINavigationController
@end
