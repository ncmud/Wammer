//
//  SPLTestAppDelegate.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/20/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "SPLTestAppDelegate.h"

@implementation SPLTestAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [UIViewController new];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
