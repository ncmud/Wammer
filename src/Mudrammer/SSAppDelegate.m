//
//  SSAppDelegate.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/21/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSAppDelegate.h"
#import "SSClientContainer.h"
@import UserNotifications;
#import "SSRadialControl.h"
#import "SSWorldDisplayController.h"
#import "Wammer-Swift.h"
#import "SPLNotificationManager.h"


@implementation SSAppDelegate

- (void)_setupDefaultUserDefaults {
    NSDictionary *defaultUserDefaults = @{
        kPrefInitialWorldsCreated  : @NO,
        kPrefLocalEcho             : @YES,
        kPrefAutocorrect           : @NO,
        kPrefMoveControl           : @(SSRadialControlPositionRight),
        kPrefConnectOnStartup      : @YES,
        kPrefStringEncoding        : @"ASCII",
        kPrefKeyboardStyle         : @YES,
        kPrefRadialControl         : @(SSRadialControlPositionLeft),
        kPrefRadialCommands        : @[ @"up", @"in", @"down", @"out", @"look" ],
        kPrefTopBarAlwaysVisible   : @NO,
        kPrefAutocapitalization    : @NO,
        kPrefBTKeyboard            : @NO,
        kPrefSemicolonCommands     : @YES,
        kPrefSemicolonCommandDelimiter : kPrefSemicolonDefaultDelimiter,
    };

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *prefKeys = [[defaults dictionaryRepresentation] allKeys];

    [defaultUserDefaults enumerateKeysAndObjectsUsingBlock:^(NSString *pref,
                                                             id defaultValue,
                                                             BOOL *stop) {
        if (![prefKeys containsObject:pref]) {
            [defaults setObject:defaultValue forKey:pref];
        }
    }];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self _setupDefaultUserDefaults];
    });

    // WorldStore.shared auto-loads on first access; trigger it now
    (void)[WorldStoreBridge allWorlds];

    [SSThemes sharedThemer]; // UIAppearance™ Inside®

    application.idleTimerDisabled = YES;

    // disallow webview cache
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];

    (void)[SPLNotificationManager shared];

    return YES;
}

#pragma mark - App lifecycle events

- (void)applicationWillTerminate:(UIApplication *)application {
    [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
}

@end
