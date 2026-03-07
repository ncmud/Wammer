//
//  SSWorldEditViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import "SSWorldEditViewController.h"
#import "Wammer-Swift.h"
#import "SSTGAEditor.h"
#import "SSWorldForm.h"
#import "SPLTickerForm.h"
#import "SPLFXWorldEditor.h"

@interface SSWorldEditViewController ()
- (SSWorldEditViewController *) initWithWorldIdentifier:(NSString *)identifier;

- (void) saveWorld:(id)sender;
- (void) cancelEditing:(id)sender;
@end

@implementation SSWorldEditViewController
{
    MUDWorld *currentWorld;

    UIBarButtonItem *saveButton;
}

- (SSWorldEditViewController *) initWithWorldIdentifier:(NSString *)identifier {

    MUDWorld *world = [WorldStoreBridge mudWorldForIdentifier:identifier];
    if (!world) return nil;

    if( ( self = [self initWithRoot:[SSWorldForm formForWorld:world]] ) ) {
        currentWorld = world;

        [SSThemes configureTable:self.quickDialogTableView];

        saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                   target:self
                                                                   action:@selector(saveWorld:)];

        if( ![[UIDevice currentDevice] isIPad] ) {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                  target:self
                                                                                                  action:@selector(cancelEditing:)];
        }

        self.navigationItem.rightBarButtonItem = saveButton;
    }

    return self;
}

+ (instancetype)editorForWorldIdentifier:(NSString *)worldIdentifier {
    return [[SSWorldEditViewController alloc] initWithWorldIdentifier:worldIdentifier];
}

- (CGSize)preferredContentSize {
    return [self.quickDialogTableView sizeThatFits:CGSizeMake(320.0f, CGFLOAT_MAX)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Reload world from store in case sub-editors made changes
    MUDWorld *refreshed = [WorldStoreBridge mudWorldForIdentifier:currentWorld.identifier];
    if (refreshed) {
        currentWorld = refreshed;
    }

    [(SSWorldForm *)self.root refreshWorldFormForController:self];
    [self.quickDialogTableView reloadData];
    self.title = self.root.title;
}

- (void)dealloc {
    _saveCompletionBlock = nil;
}

#pragma mark - saving

- (void)cancelEditing:(id)sender {
    if( self.saveCompletionBlock )
        self.saveCompletionBlock(NO);
    else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveWorld:(id)sender {
    [self.quickDialogTableView endEditing:YES];

    [self.root fetchValueIntoObject:currentWorld];

    // hostname parsing
    currentWorld.hostname = [MUDWorld cleanedHostNameFor:currentWorld.hostname];

    if( ![currentWorld canSave] )
        return;

    currentWorld.isHidden = NO;
    [WorldStoreBridge updateMUDWorld:currentWorld];

    if( self.saveCompletionBlock )
        self.saveCompletionBlock(YES);
    else
        [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Form actions

- (void)newTrigger {
    MUDTrigger *trigger = [[MUDTrigger alloc] init];
    [WorldStoreBridge addTrigger:trigger toWorldIdentifier:currentWorld.identifier];

    [self.navigationController pushViewController:
     [SSTGAEditor editorForTrigger:trigger.identifier
                   worldIdentifier:currentWorld.identifier]
                                         animated:YES];
}

- (void)newAlias {
    MUDAlias *alias = [[MUDAlias alloc] init];
    [WorldStoreBridge addAlias:alias toWorldIdentifier:currentWorld.identifier];

    [self.navigationController pushViewController:
     [SSTGAEditor editorForAlias:alias.identifier
                 worldIdentifier:currentWorld.identifier]
                                         animated:YES];
}

- (void)newGag {
    MUDGag *gag = [[MUDGag alloc] init];
    [WorldStoreBridge addGag:gag toWorldIdentifier:currentWorld.identifier];

    [self.navigationController pushViewController:
     [SSTGAEditor editorForGag:gag.identifier
               worldIdentifier:currentWorld.identifier]
                                         animated:YES];
}

- (void)newTicker {
    MUDTicker *ticker = [[MUDTicker alloc] init];
    [WorldStoreBridge addTickerToWorldIdentifier:currentWorld.identifier
                                        commands:ticker.commands
                                        interval:ticker.interval
                                       isEnabled:ticker.isEnabled];

    // Reload world to get the ticker that was just added
    MUDWorld *refreshed = [WorldStoreBridge mudWorldForIdentifier:currentWorld.identifier];
    if (refreshed) {
        currentWorld = refreshed;
    }

    MUDTicker *addedTicker = currentWorld.tickers.lastObject;
    if (addedTicker) {
        [self.navigationController pushViewController:
         [SPLFXWorldEditor editorForTicker:addedTicker.identifier
                           worldIdentifier:currentWorld.identifier]
                                             animated:YES];
    }
}

- (void)deepClone {
    MUDWorld *clone = [currentWorld deepClone];
    [WorldStoreBridge addMUDWorld:clone];
    if (self.saveCompletionBlock) {
        self.saveCompletionBlock(YES);
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)editTrigger:(NSString *)triggerIdentifier {
    [self.navigationController pushViewController:
     [SSTGAEditor editorForTrigger:triggerIdentifier
                   worldIdentifier:currentWorld.identifier]
                                         animated:YES];
}

- (void)editAlias:(NSString *)aliasIdentifier {
    [self.navigationController pushViewController:
     [SSTGAEditor editorForAlias:aliasIdentifier
                 worldIdentifier:currentWorld.identifier]
                                         animated:YES];
}

- (void)editGag:(NSString *)gagIdentifier {
    [self.navigationController pushViewController:
     [SSTGAEditor editorForGag:gagIdentifier
               worldIdentifier:currentWorld.identifier]
                                         animated:YES];
}

- (void)editTicker:(NSString *)tickerIdentifier {
    [self.navigationController pushViewController:
     [SPLFXWorldEditor editorForTicker:tickerIdentifier
                       worldIdentifier:currentWorld.identifier]
                                         animated:YES];
}

@end
