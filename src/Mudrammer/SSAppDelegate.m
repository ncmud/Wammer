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
#import "WorldStoreBridge.h"
#import "MUDModels.h"


@implementation SSAppDelegate

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
        NSString *hostname = [[url host] lowercaseString];

        // Check if this world is already saved
        NSString *existingIdentifier = nil;
        for (MUDWorldBridge *w in [WorldStoreBridge allWorlds]) {
            if ([w.hostname isEqualToString:hostname]) {
                existingIdentifier = w.identifier;
                break;
            }
        }

        if (!existingIdentifier) {
            int16_t port = [url port] ? [[url port] shortValue] : 23;
            [WorldStoreBridge addWorldWithHostname:hostname name:@"" port:port];

            // Find the newly added world
            for (MUDWorldBridge *w in [WorldStoreBridge allWorlds]) {
                if ([w.hostname isEqualToString:hostname]) {
                    existingIdentifier = w.identifier;
                    break;
                }
            }
        }

        if (existingIdentifier) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWorldChanged
                                                                object:existingIdentifier];
        }

        return YES;
    }

    return NO;
}
#pragma clang diagnostic pop

#pragma mark - SSApplication

- (void) ss_willFinishLaunchingWithOptions:(NSDictionary *)options {
    // WorldStore.shared auto-loads on first access; trigger it now
    (void)[WorldStoreBridge allWorlds];

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

#if TARGET_OS_MACCATALYST
#pragma mark - Mac Menu Bar

- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder {
    [super buildMenuWithBuilder:builder];

    if (builder.system != UIMenuSystem.mainSystem) {
        return;
    }

    // Remove menus that don't apply
    [builder removeMenuForIdentifier:UIMenuFormat];

    // Connection menu
    UIKeyCommand *disconnectCommand = [UIKeyCommand commandWithTitle:NSLocalizedString(@"DISCONNECT", @"Disconnect")
                                                               image:nil
                                                              action:@selector(menuDisconnect:)
                                                               input:@"w"
                                                       modifierFlags:UIKeyModifierCommand
                                                        propertyList:nil];

    UIKeyCommand *cycleCommand = [UIKeyCommand commandWithTitle:NSLocalizedString(@"CYCLE_CONNECTIONS", @"Next Connection")
                                                          image:nil
                                                         action:@selector(menuCycleConnections:)
                                                          input:@"]"
                                                  modifierFlags:UIKeyModifierCommand
                                                   propertyList:nil];

    UIKeyCommand *clearCommand = [UIKeyCommand commandWithTitle:NSLocalizedString(@"CLEAR_SCREEN", @"Clear Screen")
                                                          image:nil
                                                         action:@selector(menuClearScreen:)
                                                          input:@"k"
                                                  modifierFlags:UIKeyModifierCommand
                                                   propertyList:nil];

    UIMenu *connectionMenu = [UIMenu menuWithTitle:NSLocalizedString(@"CONNECTION", @"Connection")
                                          children:@[disconnectCommand, cycleCommand, clearCommand]];

    [builder insertSiblingMenu:connectionMenu afterMenuForIdentifier:UIMenuFile];

    // World list in File menu
    UIKeyCommand *worldListCommand = [UIKeyCommand commandWithTitle:NSLocalizedString(@"WORLD_LIST", @"World List")
                                                              image:nil
                                                             action:@selector(menuShowWorldList:)
                                                              input:@"l"
                                                      modifierFlags:UIKeyModifierCommand
                                                       propertyList:nil];

    UIMenu *worldListMenu = [UIMenu menuWithTitle:@""
                                            image:nil
                                       identifier:nil
                                          options:UIMenuOptionsDisplayInline
                                         children:@[worldListCommand]];

    [builder insertChildMenu:worldListMenu atStartOfMenuForIdentifier:UIMenuFile];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(menuDisconnect:) ||
        action == @selector(menuCycleConnections:) ||
        action == @selector(menuClearScreen:) ||
        action == @selector(menuShowWorldList:)) {
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)menuDisconnect:(id)sender {
    SSClientViewController *client = [SSClientContainer worldDisplayDrawer].currentVisibleClient;
    if (client) {
        [client disconnect];
    }
}

- (void)menuCycleConnections:(id)sender {
    [[SSClientContainer worldDisplayDrawer] selectNextWorld];
}

- (void)menuClearScreen:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MRMenuClearScreen" object:nil];
}

- (void)menuShowWorldList:(id)sender {
    SSClientContainer *container = [SSClientContainer sharedClientContainer];
    [container toggleLeftPanel:sender];
}
#endif

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

            break;

        default:
            break;
    }
}


@end
