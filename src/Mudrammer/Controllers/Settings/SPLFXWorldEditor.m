//
//  SPLFXWorldEditor.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/20/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLFXWorldEditor.h"
#import "Wammer-Swift.h"
#import "SPLTickerForm.h"
#import "SSSoundPickerViewController.h"
#import "JSQSystemSoundPlayer+SSAdditions.h"
#import "SPLAlerts.h"

@interface SPLFXWorldEditor ()

@property (nonatomic, strong) MUDTicker *ticker;
@property (nonatomic, copy) NSString *worldIdentifier;
@property (nonatomic, strong) UIBarButtonItem *saveButton;

@end

@implementation SPLFXWorldEditor

+ (instancetype)editorForTicker:(NSString *)tickerIdentifier
                worldIdentifier:(NSString *)worldIdentifier {

    MUDWorld *world = [WorldStoreBridge mudWorldForIdentifier:worldIdentifier];
    if (!world) return nil;

    MUDTicker *ticker = nil;
    for (MUDTicker *t in world.tickers) {
        if ([t.identifier isEqualToString:tickerIdentifier]) {
            ticker = t;
            break;
        }
    }
    if (!ticker) return nil;

    SPLFXWorldEditor *editor = [self formViewControllerWithForm:
                                [SPLTickerForm formForTicker:ticker]];

    editor.title = (ticker.isHidden
                    ? NSLocalizedString(@"NEW_TICKER", nil)
                    : NSLocalizedString(@"EDIT_TICKER", nil));

    editor.ticker = ticker;
    editor.worldIdentifier = worldIdentifier;

    return editor;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [SSThemes configureTable:self.tableView];

    if (![[UIDevice currentDevice] isIPad]) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(cancelEditing:)];
    }

    _saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                target:self
                                                                action:@selector(saveEditing:)];

    self.navigationItem.rightBarButtonItem = self.saveButton;
}

#pragma mark - Actions

- (void)showSoundPicker {
    SSSoundPickerViewController *picker = [SSSoundPickerViewController new];
    picker.selectedFileName = ((SPLTickerForm *)self.formController.form).soundFileName;

    @weakify(self);
    picker.selectedBlock = ^(NSString *str) {
        @strongify(self);

        SSSound *newSound = [JSQSystemSoundPlayer soundForFileName:str];

        ((SPLTickerForm *)self.formController.form).soundFileName = (newSound
                                                                     ? newSound.fileName
                                                                     : @"None");

        [self.tableView reloadData];
    };

    [self.navigationController pushViewController:picker
                                         animated:YES];
}

- (void) cancelEditing:(id)sender {
    // If ticker is new (hidden), remove it since user cancelled
    if (_ticker.isHidden) {
        [WorldStoreBridge removeTickerWithIdentifier:_ticker.identifier
                                 fromWorldIdentifier:_worldIdentifier];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) saveEditing:(id)sender {
    [self.tableView endEditing:YES];

    [self bindToObject:self.ticker];

    if (![self.ticker canSave]) {
        return;
    }

    self.ticker.isHidden = NO;

    [WorldStoreBridge updateMUDWorld:[WorldStoreBridge mudWorldForIdentifier:_worldIdentifier]];

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)deleteCurrentRecord {
    [self.tableView endEditing:YES];

    @weakify(self);
    NSString *title = NSLocalizedString(@"DELETE_TICKER", nil);

    [SPLAlerts SPLShowActionViewWithTitle:nil
                              cancelTitle:NSLocalizedString(@"CANCEL", @"Cancel")
                              cancelBlock:nil
                         destructiveTitle:title
                         destructiveBlock:^{
                             @strongify(self);
                             [WorldStoreBridge removeTickerWithIdentifier:self.ticker.identifier
                                                     fromWorldIdentifier:self.worldIdentifier];
                             [self.navigationController popViewControllerAnimated:YES];
                         }
                            barButtonItem:nil
                               sourceView:self.tableView
                               sourceRect:self.tableView.frame
                      presentingController:self];
}

@end
