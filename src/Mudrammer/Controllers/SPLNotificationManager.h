//
//  SPLNotificationManager.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import UIKit;
@import UserNotifications;

@interface SPLNotificationManager : NSObject <UNUserNotificationCenterDelegate>

@property (nonatomic, readonly) BOOL askedForLocalNotifications;

- (void) registerForLocalNotifications;
- (void) scheduleTimeoutNotification;

@end
