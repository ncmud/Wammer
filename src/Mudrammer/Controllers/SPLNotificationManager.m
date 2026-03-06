//
//  SPLNotificationManager.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLNotificationManager.h"

@implementation SPLNotificationManager

- (instancetype)init {
    if ((self = [super init])) {
        _askedForLocalNotifications = NO;
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    }

    return self;
}

- (void)registerForLocalNotifications {
    if (self.askedForLocalNotifications) {
        DLog(@"*** Already asked for perms");
        return;
    }

    [[UNUserNotificationCenter currentNotificationCenter]
     requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
     completionHandler:^(BOOL granted, NSError *error) {
        DLog(@"Notification auth granted: %d error: %@", granted, error);
    }];

    _askedForLocalNotifications = YES;
}

- (void)scheduleTimeoutNotification {
    if (!self.askedForLocalNotifications) {
        [self registerForLocalNotifications];
    }

    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.body = NSLocalizedString(@"SESSION_TIMEOUT", @"Your session will timeout in two minutes.");
    content.sound = [UNNotificationSound defaultSound];

    UNTimeIntervalNotificationTrigger *trigger =
        [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:(8 * 60) repeats:NO];

    UNNotificationRequest *request =
        [UNNotificationRequest requestWithIdentifier:@"sessionTimeout"
                                             content:content
                                             trigger:trigger];

    [[UNUserNotificationCenter currentNotificationCenter]
     addNotificationRequest:request
     withCompletionHandler:^(NSError *error) {
        if (error) {
            DLog(@"Failed to schedule notification: %@", error);
        }
    }];
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler {
    completionHandler();
}

@end
