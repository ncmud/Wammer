//
//  SSClientViewController+Interactions.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 12/20/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SSClientViewController+Interactions.h"
#import "SSMudView.h"
#import "SSMUDSocket.h"
#import "SSClientContainer.h"
#import "SSWorldDisplayController.h"
#import "SSMUDToolbar.h"

@implementation SSClientViewController (Interactions)

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    DLog(@"URL %@ %@", url, url.absoluteString);

    NSString *urlString = [[url absoluteString] lowercaseString];

    BOOL matchesImageExtension = NO;
    for (NSString *extension in @[ @"gif", @"png", @"jpg", @"jpeg", @"tiff" ]) {
        if ([urlString hasSuffix:extension]) {
            matchesImageExtension = YES;
            break;
        }
    }
    if (matchesImageExtension) {

        JTSImageInfo *info = [JTSImageInfo new];
        info.imageURL = url;

        JTSImageViewController *imageViewController = [[JTSImageViewController alloc] initWithImageInfo:info
                                                                                                   mode:JTSImageViewControllerMode_Image
                                                                                        backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred];

        imageViewController.interactionsDelegate = self;
        imageViewController.optionsDelegate = self;

        [imageViewController showFromViewController:self
                                         transition:JTSImageViewControllerTransition_FromOffscreen];

        return;
    }

    if ([@[ @"http", @"https", @"mailto" ] containsObject:[url scheme]]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationURLTapped
                                                            object:url];
    }
}

#pragma mark - JTSImageViewControllerInteractionsDelegate

- (BOOL)imageViewerAllowCopyToPasteboard:(JTSImageViewController *)imageViewer {
    return YES;
}

#pragma mark - JTSImageViewControllerOptionsDelegate

- (CGFloat)backgroundBlurRadiusForImageViewer:(JTSImageViewController *)imageViewer {
    return 5.f;
}

#pragma mark - SSConnectButtonDelegate

- (void)connectButton:(SSConnectButton *)button didChangeState:(BOOL)connected {
    if ([self isConnected]) {
        [self.socket disconnect];
    } else {
        [self connect];
    }
}

#pragma mark - UIKeyCommand

- (void)keyCommandCycleActiveConnections:(UIKeyCommand *)sender {
    [[self worldDisplay] selectNextWorld];
    SSClientViewController *newClient = [[self worldDisplay] currentVisibleClient];
    [newClient.mudView.inputToolbar.textView becomeFirstResponder];
}

- (void)keyCommandSwitchToActiveConnection:(UIKeyCommand *)sender {
    NSInteger desiredIndex = sender.input.integerValue - 1;

    if (desiredIndex >= 0 && desiredIndex < [[self worldDisplay] numberOfClients]) {
        [[self worldDisplay] setSelectedIndex:desiredIndex];

        SSClientViewController *newClient = [[self worldDisplay] currentVisibleClient];
        [newClient.mudView.inputToolbar.textView becomeFirstResponder];
    }
}

@end
