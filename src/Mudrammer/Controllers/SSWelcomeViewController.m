//
//  SSWelcomeViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 1/12/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSWelcomeViewController.h"
@import Masonry;
#import "SSWorldDisplayController.h"
#import "Wammer-Swift.h"

@interface SSWelcomeViewController ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *getStartedButton;

@end

@implementation SSWelcomeViewController

- (instancetype) init {
    if ((self = [super init])) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [[SSThemes sharedThemer] themeAtIndex:0][kThemeBackgroundColor];

    // Shield image — centered in upper half
    _imageView = [[UIImageView alloc] initWithImage:[SPLImagesCatalog shieldImage]];
    self.imageView.alpha = 0.15f;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;

    [self.view addSubview:self.imageView];
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).offset(-80);
        make.width.height.mas_equalTo(200);
    }];

    // Title
    _titleLabel = [UILabel new];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.text = NSLocalizedString(@"WELCOME", nil);
    self.titleLabel.font = [UIFont systemFontOfSize:32 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor whiteColor];

    [self.view addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.imageView.mas_bottom).offset(32);
        make.left.greaterThanOrEqualTo(self.view).offset(32);
        make.right.lessThanOrEqualTo(self.view).offset(-32);
    }];

    // Body text
    _bodyLabel = [UILabel new];
    self.bodyLabel.textAlignment = NSTextAlignmentCenter;
    self.bodyLabel.numberOfLines = 0;
    self.bodyLabel.text = NSLocalizedString(@"WELCOME_TEXT", nil);
    self.bodyLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
    self.bodyLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];

    [self.view addSubview:self.bodyLabel];
    [self.bodyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(16);
        make.left.greaterThanOrEqualTo(self.view).offset(40);
        make.right.lessThanOrEqualTo(self.view).offset(-40);
    }];

    // Get Started button
    UIButtonConfiguration *config = [UIButtonConfiguration filledButtonConfiguration];
    config.title = @"Get Started";
    config.cornerStyle = UIButtonConfigurationCornerStyleLarge;
    config.baseBackgroundColor = [UIColor systemBlueColor];
    config.baseForegroundColor = [UIColor whiteColor];
    config.contentInsets = NSDirectionalEdgeInsetsMake(14, 40, 14, 40);

    _getStartedButton = [UIButton buttonWithConfiguration:config primaryAction:nil];
    self.getStartedButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    [self.getStartedButton addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.getStartedButton];
    [self.getStartedButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-60);
    }];
}

- (void)tappedButton:(id)sender {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setBool:YES forKey:kPrefInitialSetupComplete];

    SSClientContainer *container = [self clientContainer];

    [container dismissViewControllerAnimated:YES
                                  completion:^
    {
        SSClientViewController *firstClient = [[self worldDisplay] clientAtIndex:0];
        [firstClient connect];
    }];
}

@end
