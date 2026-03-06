//
//  SSClientContainer.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 4/20/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSClientContainer.h"
#import "SSClientViewController.h"
#import "SSWorldListViewController.h"
#import "WorldStoreBridge.h"
#import <QuartzCore/QuartzCore.h>
#import "SSClientViewController.h"
#import "SSWorldDisplayController.h"
#import "SSRadialControl.h"
#import "SPLHandoffWebViewController.h"
#import "SPLAlerts.h"
#import <FBKVOController.h>

@import MessageUI;

#import "SSWelcomeViewController.h"

@interface SSClientContainer () <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) FBKVOController *kvoController;

// notifications
- (void) URLTapped:(NSNotification *)notification;

@end

@implementation SSClientContainer

- (instancetype)init {
    if ((self = [super init])) {
        // Setup pane
        self.pushesSidePanels = NO;
        self.shouldResizeRightPanel = YES;
        self.rightFixedWidth = kWorldDisplayWidth;
        self.minimumMovePercentage = 0.2f;
        self.recognizesPanGesture = YES;
        self.panningLimitedToTopViewController = YES;
        self.allowRightOverpan = NO;
        self.allowLeftOverpan = NO;
        self.maximumAnimationDuration = 0.2f;
        self.style = JASidePanelSingleActive;
        self.recognizesPanGesture = YES;
        self.bounceOnCenterPanelChange = NO;
        self.bounceOnSidePanelClose = NO;
        self.bounceOnSidePanelOpen = NO;

        // URL tapped
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(URLTapped:)
                                                     name:kNotificationURLTapped
                                                   object:nil];

        // world selected notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(selectedWorldDidChange:)
                                                     name:kNotificationWorldChanged
                                                   object:nil];

        _kvoController = [FBKVOController controllerWithObserver:self];

        [self.kvoController observe:self
                            keyPath:@"state"
                            options:NSKeyValueObservingOptionNew
                              block:^(SSClientContainer *container, id state, NSDictionary *dict) {
                                  JASidePanelState newState = (JASidePanelState)[dict[NSKeyValueChangeNewKey] integerValue];
                                  if (newState == JASidePanelRightVisible) {
                                      UINavigationController *nav = (UINavigationController *)container.centerPanel;

                                      SSClientViewController *client = [[nav viewControllers] firstObject];

                                      if ([client isKindOfClass:[SSClientViewController class]]) {
                                          [client setNavVisible:YES];
                                      }
                                  }
                              }];
    }

    return self;
}

+ (instancetype)sharedClientContainer {
    id rootVC = [SSAppDelegate sharedApplication].window.rootViewController;

    if ([rootVC isKindOfClass:[SSClientContainer class]]) {
        return (SSClientContainer *)rootVC;
    }

    return nil;
}

+ (SSWorldDisplayController *)worldDisplayDrawer {
    return (SSWorldDisplayController *)(((SSClientContainer *)[self sharedClientContainer]).rightPanel);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

    // Add drawer and initial client
    SSWorldDisplayController *displayController = [SSWorldDisplayController new];
    self.rightPanel = displayController;
    [displayController addClientWithWorld:nil];

    // Hide splash if necessary
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{

        if (![[NSUserDefaults standardUserDefaults] boolForKey:kPrefInitialSetupComplete]) {
            SSWelcomeViewController *welcome = [SSWelcomeViewController new];
            UINavigationController *nav = [welcome wrappedNavigationController];
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

            [self presentViewController:nav
                               animated:NO
                             completion:nil];
        }
    });
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (BOOL)shouldAutorotate {
    return YES;
}
#pragma clang diagnostic pop

- (void)dealloc {
    _kvoController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - notifications

- (void)URLTapped:(NSNotification *)notification {
    NSURL *url = [notification object];

    if( !url )
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[url scheme] isEqualToString:@"mailto"]) {
            if ([MFMailComposeViewController canSendMail]) {
                MFMailComposeViewController *mvc = [MFMailComposeViewController new];
                [mvc setToRecipients:@[ [[url absoluteString] stringByReplacingOccurrencesOfString:@"mailto:"
                                                                                        withString:@""] ]];
                mvc.mailComposeDelegate = self;

                [self presentViewController:mvc
                                   animated:YES
                                 completion:nil];
            }
        } else {
            SPLHandoffWebViewController *webView = [[SPLHandoffWebViewController alloc] initWithURL:url];

            [[[SSClientContainer worldDisplayDrawer] currentVisibleClient] hideKeyboard];

            [[[SSClientContainer worldDisplayDrawer] currentVisibleClient] presentViewController:webView
                                                                                        animated:YES
                                                                                      completion:nil];
        }
    });
}

- (void)selectedWorldDidChange:(NSNotification *)notification {
    NSString *worldIdentifier = [notification object];

    if( !worldIdentifier )
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        MUDWorldBridge *mudWorld = [WorldStoreBridge worldForIdentifier:worldIdentifier];
        if (!mudWorld)
            return;

        NSInteger currentClient = [[SSClientContainer worldDisplayDrawer] selectedIndex];

        void (^WorldChangeBlock)(void) = ^{
            [[[SSClientContainer worldDisplayDrawer] clientAtIndex:currentClient] updateCurrentWorld:worldIdentifier
                                                                                  connectAfterUpdate:YES];
        };

        SSClientViewController *client = [[SSClientContainer worldDisplayDrawer] currentVisibleClient];

        if ([client isConnected]) {
            NSString *desc = [WorldStoreBridge worldDescriptionForIdentifier:worldIdentifier];
            [SPLAlerts SPLShowAlertViewWithTitle:[NSString stringWithFormat:NSLocalizedString(@"CONNECTING_TO_%@", nil),
                                                  desc ?: worldIdentifier]
                                         message:[NSString stringWithFormat:NSLocalizedString(@"DISCONNECT_FROM_%@", @"Disconnect from"),
                                                  client.hostname]
                                     cancelTitle:NSLocalizedString(@"CANCEL", @"Cancel")
                                     cancelBlock:nil
                                         okTitle:NSLocalizedString(@"CONNECT", @"Connect")
                                         okBlock:WorldChangeBlock];
        } else {
            WorldChangeBlock();
        }
    });
}

#pragma mark - JASidePanel

- (void)stylePanel:(UIView *)panel {}

- (void)closeDrawerAnimated:(BOOL)animated {
    if (self.state != JASidePanelCenterVisible) {
        [self showCenterPanelAnimated:animated];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
