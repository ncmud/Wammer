//
//  SPLHandoffWebViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/21/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "SPLHandoffWebViewController.h"

@interface SPLHandoffWebViewController ()

@end

@implementation SPLHandoffWebViewController

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (self.webActivity) {
        [self.webActivity invalidate];
        self.webActivity = nil;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [super webViewDidFinishLoad:webView];

    NSURL *url = webView.request.URL;
    if (!self.webActivity && url) {
        self.webActivity = [SPLWebActivity activityWithURL:url];
    } else if (self.webActivity && url) {
        self.webActivity.userActivity.webpageURL = url;
        [self.webActivity setNeedsUpdate];
    }
}

@end
