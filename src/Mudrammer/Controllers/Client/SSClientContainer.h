//
//  SSClientContainer.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 4/20/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import <JASidePanelController.h>

@class SSWorldDisplayController, SSClientViewController;

NS_ASSUME_NONNULL_BEGIN

/*
 * Container for multiple active clients.
 */

@interface SSClientContainer : JASidePanelController

/**
 * Close pane drawer if open.
 */
- (void)closeDrawerAnimated:(BOOL)animated;

/**
 * Access the world display drawer for this container.
 */
@property (nonatomic, readonly, nullable) SSWorldDisplayController *worldDisplay;

#if TARGET_OS_MACCATALYST
- (void)menuDisconnect:(id)sender;
- (void)menuCycleConnections:(id)sender;
- (void)menuClearScreen:(id)sender;
- (void)menuShowWorldList:(id)sender;
#endif

@end

@interface UIViewController (SSClientContainerAccess)

/**
 * Walk the parent/presenting chain to find the nearest SSClientContainer.
 */
@property (nonatomic, readonly, nullable) SSClientContainer *clientContainer;

/**
 * Shortcut: self.clientContainer.worldDisplay.
 */
@property (nonatomic, readonly, nullable) SSWorldDisplayController *worldDisplay;

@end

NS_ASSUME_NONNULL_END
