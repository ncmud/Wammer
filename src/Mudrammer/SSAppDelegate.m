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


@interface SSAppDelegate ()
+ (void) setupCoreData;
@end

@implementation SSAppDelegate

#pragma mark - setup and scaffolding

+ (void)setupCoreData {
#ifdef DEBUG
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelAll];
#else
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelOff];
#endif
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:kStoreName];
}

#pragma mark - URL tapped

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {

    if (!url || ![url host]) {
        return NO;
    }

    if ([[url scheme] isEqualToString:@"telnet"]) {

        // Is this world already saved?
        World *existing = [World MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"hostname == %@ AND isHidden == NO",
                                                            [[url host] lowercaseString]]
                                                  sortedBy:[World defaultSortField]
                                                 ascending:[World defaultSortAscending]
                                                 inContext:[NSManagedObjectContext MR_defaultContext]];

        if (!existing) {
            World *w = [World worldFromURL:url];
            w.isHidden = @NO;
            [w saveObjectWithCompletion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWorldChanged
                                                                    object:[w objectID]];
            }
                                   fail:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWorldChanged
                                                                object:[existing objectID]];
        }

        return YES;
    }

    return NO;
}
#pragma clang diagnostic pop

#pragma mark - SSApplication

- (void) ss_willFinishLaunchingWithOptions:(NSDictionary *)options {
    [self.class setupCoreData];

    [World createDefaultWorldsIfNecessary];

    [SSThemes sharedThemer]; // UIAppearance™ Inside®

    self.idleTimerDisabled = YES;
    self.applicationSupportsShakeToEdit = NO;

    // disallow webview cache
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];

    _notificationObserver = [SPLNotificationManager new];
}

- (void) ss_willLaunchBackgroundSetup {

}

- (UIViewController *) ss_appRootViewController {
    return [SSClientContainer new];
}

- (NSDictionary *) ss_defaultUserDefaults {
    return @{
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
}

- (void) ss_receivedApplicationEvent:(SSApplicationEvent)eventType {

    switch (eventType) {
        case SSApplicationEventDidBecomeActive:

            [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];

            [SSRadialControl validateRadialPositions];

            break;

        case SSApplicationEventWillEnterForeground:
        case SSApplicationEventDidEnterBackground:
        case SSApplicationEventWillResignActive:

            break;

        case SSApplicationEventWillTerminate:

            [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];

            [MagicalRecord cleanUp];

            break;

        default:
            break;
    }
}


@end
