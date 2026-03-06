//
//  SPLTestAppDelegate.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/20/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "SPLTestAppDelegate.h"

@implementation SPLTestAppDelegate

#pragma mark - SSApplication

- (void)ss_willFinishLaunchingWithOptions:(NSDictionary *)options {
    // WorldStore.shared auto-loads on first access; no setup needed
}

- (UIViewController *)ss_appRootViewController {
    return [UIViewController new];
}

@end
