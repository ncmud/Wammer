//
//  SPLHandoffWebViewController.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/21/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

@import SafariServices;

@class SPLWebActivity;

@interface SPLHandoffWebViewController : SFSafariViewController

@property (nonatomic, strong) SPLWebActivity *webActivity;

- (instancetype)initWithURL:(NSURL *)url;

@end
