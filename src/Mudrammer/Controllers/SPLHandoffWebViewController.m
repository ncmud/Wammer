//
//  SPLHandoffWebViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/21/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "SPLHandoffWebViewController.h"
@import SPLUserActivity;

#if !TARGET_OS_VISION
@interface SPLHandoffWebViewController () <SFSafariViewControllerDelegate>
@end
#endif

@implementation SPLHandoffWebViewController

- (instancetype)initWithURL:(NSURL *)url {
    self = [super initWithURL:url];
    if (self) {
#if !TARGET_OS_VISION
        self.delegate = self;
#endif
        self.webActivity = [SPLWebActivity activityWithURL:url];
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (self.webActivity) {
        [self.webActivity invalidate];
        self.webActivity = nil;
    }
}

#if !TARGET_OS_VISION
#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialNavigation:(BOOL)didLoadSuccessfully {
    // Handoff activity was set at init time via the URL
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}
#endif

@end
