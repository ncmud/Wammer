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


#if TARGET_OS_MACCATALYST
#pragma mark - Mac Menu Bar

- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder {
    [super buildMenuWithBuilder:builder];

    if (builder.system != UIMenuSystem.mainSystem) {
        return;
    }

    // Remove menus that don't apply
    [builder removeMenuForIdentifier:UIMenuFormat];

    // New Window command in File menu
    UIKeyCommand *newWindowCommand = [UIKeyCommand commandWithTitle:NSLocalizedString(@"NEW_WINDOW", @"New Window")
                                                              image:nil
                                                             action:@selector(menuNewWindow:)
                                                              input:@"n"
                                                      modifierFlags:UIKeyModifierCommand
                                                       propertyList:nil];

    UIMenu *newWindowMenu = [UIMenu menuWithTitle:@""
                                            image:nil
                                       identifier:nil
                                          options:UIMenuOptionsDisplayInline
                                         children:@[newWindowCommand]];

    [builder insertChildMenu:newWindowMenu atStartOfMenuForIdentifier:UIMenuFile];

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

    [builder insertChildMenu:worldListMenu atEndOfMenuForIdentifier:UIMenuFile];
}

- (void)menuNewWindow:(id)sender {
    [UIApplication.sharedApplication requestSceneSessionActivation:nil
                                                      userActivity:nil
                                                           options:nil
                                                      errorHandler:nil];
}
#endif

#pragma mark - App lifecycle events

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
    [SSRadialControl validateRadialPositions];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
}

@end
